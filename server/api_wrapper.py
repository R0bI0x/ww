from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import httpx
import os

OLLAMA_URL = os.getenv("OLLAMA_URL", "http://127.0.0.1:11434")
MODEL_NAME = os.getenv("MODEL_NAME", "qwen2.5:7b")

app = FastAPI(title="Hermes Agent API (No Auth)")


class ChatRequest(BaseModel):
    prompt: str | None = None
    messages: list[dict] | None = None
    system: str | None = None


@app.get("/")
def root():
    return {"status": "ok", "backend": "ollama", "model": MODEL_NAME}


@app.get("/health")
async def health():
    async with httpx.AsyncClient(timeout=10) as c:
        try:
            r = await c.get(f"{OLLAMA_URL}/api/tags")
            return {"ollama": r.status_code == 200, "model": MODEL_NAME}
        except Exception as e:
            return {"ollama": False, "error": str(e)}


# Endpoint gaya OpenAI (kompatibel Open WebUI, LobeChat, dll)
@app.post("/v1/chat/completions")
async def openai_chat(body: dict):
    messages = body.get("messages", [])
    prompt_parts = []
    system = None
    for m in messages:
        if m.get("role") == "system":
            system = m.get("content")
        elif m.get("role") == "user":
            prompt_parts.append(m.get("content", ""))
    prompt = "\n".join(prompt_parts)

    payload = {"model": MODEL_NAME, "prompt": prompt, "stream": False}
    if system:
        payload["system"] = system

    async with httpx.AsyncClient(timeout=600) as c:
        r = await c.post(f"{OLLAMA_URL}/api/generate", json=payload)
        if r.status_code >= 400:
            raise HTTPException(status_code=502, detail=r.text)
        data = r.json()

    return {
        "id": "chatcmpl-gha",
        "object": "chat.completion",
        "model": MODEL_NAME,
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


# Endpoint simple
@app.post("/chat")
async def chat(req: ChatRequest):
    if req.messages:
        messages = req.messages
    else:
        messages = []
        if req.system:
            messages.append({"role": "system", "content": req.system})
        messages.append({"role": "user", "content": req.prompt or ""})

    system = next((m["content"] for m in messages if m.get("role") == "system"), None)
    prompt = "\n".join(m["content"] for m in messages if m.get("role") == "user")

    payload = {"model": MODEL_NAME, "prompt": prompt, "stream": False}
    if system:
        payload["system"] = system

    async with httpx.AsyncClient(timeout=600) as c:
        r = await c.post(f"{OLLAMA_URL}/api/generate", json=payload)
        if r.status_code >= 400:
            raise HTTPException(status_code=502, detail=r.text)
        data = r.json()

    return {"response": data.get("response", ""), "model": MODEL_NAME}
