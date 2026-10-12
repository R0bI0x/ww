from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import httpx
import os

OLLAMA_URL = os.getenv("OLLAMA_URL", "http://127.0.0.1:11434")
MODEL = os.getenv("MODEL", "llama3.2:1b")

app = FastAPI(title="LLM API on GitHub Actions")


class ChatRequest(BaseModel):
    prompt: str
    system: str | None = None


class ChatResponse(BaseModel):
    response: str
    model: str


@app.get("/")
def root():
    return {"status": "ok", "model": MODEL}


@app.get("/health")
async def health():
    async with httpx.AsyncClient(timeout=10) as c:
        r = await c.get(f"{OLLAMA_URL}/api/tags")
        return {"ollama": r.status_code == 200, "model": MODEL}


@app.post("/chat", response_model=ChatResponse)
async def chat(req: ChatRequest):
    payload = {
        "model": MODEL,
        "prompt": req.prompt,
        "stream": False,
    }
    if req.system:
        payload["system"] = req.system

    async with httpx.AsyncClient(timeout=300) as c:
        try:
            r = await c.post(f"{OLLAMA_URL}/api/generate", json=payload)
            r.raise_for_status()
        except httpx.HTTPError as e:
            raise HTTPException(status_code=502, detail=str(e))

    data = r.json()
    return ChatResponse(response=data.get("response", ""), model=MODEL)
