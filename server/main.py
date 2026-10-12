from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from typing import Any, Literal
import httpx
import json
import os
import time
import uuid

OLLAMA_URL = os.getenv("OLLAMA_URL", "http://127.0.0.1:11434")
DEFAULT_MODEL = os.getenv("DEFAULT_MODEL", "qwen2.5:7b")

app = FastAPI(title="OpenAI-Compatible API (GitHub Actions)")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ---------- Schemas (mirip OpenAI) ----------
class ChatMessage(BaseModel):
    role: Literal["system", "user", "assistant", "tool"]
    content: str


class ChatCompletionRequest(BaseModel):
    model: str | None = None
    messages: list[ChatMessage]
    temperature: float | None = 0.7
    top_p: float | None = 0.9
    max_tokens: int | None = None
    stream: bool = False
    stop: list[str] | str | None = None


# ---------- Utilities ----------
def _messages_to_prompt(messages: list[ChatMessage]) -> tuple[str | None, str]:
    """Konversi format OpenAI messages → prompt + system untuk Ollama."""
    system = None
    parts = []
    for m in messages:
        if m.role == "system":
            system = (system + "\n" + m.content) if system else m.content
        elif m.role == "user":
            parts.append(f"User: {m.content}")
        elif m.role == "assistant":
            parts.append(f"Assistant: {m.content}")
        elif m.role == "tool":
            parts.append(f"Tool: {m.content}")
    return system, "\n".join(parts) + "\nAssistant:"


def _chunk(obj: dict) -> str:
    return f"data: {json.dumps(obj, ensure_ascii=False)}\n\n"


# ---------- OpenAI-compatible: /v1/models ----------
@app.get("/v1/models")
async def list_models():
    async with httpx.AsyncClient(timeout=10) as c:
        try:
            r = await c.get(f"{OLLAMA_URL}/api/tags")
            r.raise_for_status()
            tags = r.json().get("models", [])
        except Exception:
            tags = [{"name": DEFAULT_MODEL}]

    now = int(time.time())
    return {
        "object": "list",
        "data": [
            {
                "id": m["name"],
                "object": "model",
                "created": now,
                "owned_by": "github-actions",
            }
            for m in tags
        ],
    }


# ---------- OpenAI-compatible: /v1/chat/completions ----------
@app.post("/v1/chat/completions")
async def chat_completions(req: ChatCompletionRequest):
    model = req.model or DEFAULT_MODEL
    system, prompt = _messages_to_prompt(req.messages)

    payload: dict[str, Any] = {
        "model": model,
        "prompt": prompt,
        "stream": req.stream,
        "options": {
            "temperature": req.temperature if req.temperature is not None else 0.7,
            "top_p": req.top_p if req.top_p is not None else 0.9,
        },
    }
    if req.max_tokens:
        payload["options"]["num_predict"] = req.max_tokens
    if req.stop:
        payload["options"]["stop"] = req.stop if isinstance(req.stop, list) else [req.stop]
    if system:
        payload["system"] = system

    completion_id = f"chatcmpl-{uuid.uuid4().hex[:24]}"
    created = int(time.time())

    # ---------- Non-streaming ----------
    if not req.stream:
        async with httpx.AsyncClient(timeout=600) as c:
            try:
                r = await c.post(f"{OLLAMA_URL}/api/generate", json=payload)
                r.raise_for_status()
            except httpx.HTTPError as e:
                raise HTTPException(status_code=502, detail=str(e))
            data = r.json()

        return {
            "id": completion_id,
            "object": "chat.completion",
            "created": created,
            "model": model,
            "choices": [{
                "index": 0,
                "message": {"role": "assistant", "content": data.get("response", "")},
                "finish_reason": "stop",
            }],
            "usage": {
                "prompt_tokens": data.get("prompt_eval_count", 0),
                "completion_tokens": data.get("eval_count", 0),
                "total_tokens": data.get("prompt_eval_count", 0) + data.get("eval_count", 0),
            },
        }

    # ---------- Streaming (SSE) ----------
    async def event_stream():
        # chunk pertama: role
        yield _chunk({
            "id": completion_id,
            "object": "chat.completion.chunk",
            "created": created,
            "model": model,
            "choices": [{"index": 0, "delta": {"role": "assistant"}, "finish_reason": None}],
        })

        async with httpx.AsyncClient(timeout=None) as c:
            async with c.stream("POST", f"{OLLAMA_URL}/api/generate", json=payload) as r:
                async for line in r.aiter_lines():
                    if not line.strip():
                        continue
                    try:
                        obj = json.loads(line)
                    except json.JSONDecodeError:
                        continue
                    token = obj.get("response", "")
                    if token:
                        yield _chunk({
                            "id": completion_id,
                            "object": "chat.completion.chunk",
                            "created": created,
                            "model": model,
                            "choices": [{"index": 0, "delta": {"content": token}, "finish_reason": None}],
                        })
                    if obj.get("done"):
                        break

        yield _chunk({
            "id": completion_id,
            "object": "chat.completion.chunk",
            "created": created,
            "model": model,
            "choices": [{"index": 0, "delta": {}, "finish_reason": "stop"}],
        })
        yield "data: [DONE]\n\n"

    return StreamingResponse(
        event_stream(),
        media_type="text/event-stream",
        headers={"Cache-Control": "no-cache", "X-Accel-Buffering": "no"},
    )


# ---------- OpenAI-compatible: /v1/completions (legacy) ----------
@app.post("/v1/completions")
async def completions(body: dict):
    prompt = body.get("prompt", "")
    model = body.get("model") or DEFAULT_MODEL
    stream = body.get("stream", False)

    payload = {"model": model, "prompt": prompt, "stream": stream}

    async with httpx.AsyncClient(timeout=600) as c:
        r = await c.post(f"{OLLAMA_URL}/api/generate", json=payload)
        if r.status_code >= 400:
            raise HTTPException(status_code=502, detail=r.text)
        data = r.json()

    return {
        "id": f"cmpl-{uuid.uuid4().hex[:24]}",
        "object": "text_completion",
        "created": int(time.time()),
        "model": model,
        "choices": [{
            "text": data.get("response", ""),
            "index": 0,
            "finish_reason": "stop",
        }],
        "usage": {
            "prompt_tokens": data.get("prompt_eval_count", 0),
            "completion_tokens": data.get("eval_count", 0),
            "total_tokens": data.get("prompt_eval_count", 0) + data.get("eval_count", 0),
        },
    }


# ---------- Meta endpoints ----------
@app.get("/")
def root():
    return {
        "status": "ok",
        "backend": "ollama",
        "openai_base_url": "/v1",
        "default_model": DEFAULT_MODEL,
    }


@app.get("/health")
async def health():
    async with httpx.AsyncClient(timeout=10) as c:
        try:
            r = await c.get(f"{OLLAMA_URL}/api/tags")
            return {"ollama": r.status_code == 200, "default_model": DEFAULT_MODEL}
        except Exception as e:
            return {"ollama": False, "error": str(e)}
