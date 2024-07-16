import os
import sys
import logging
import time
import uvicorn

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi import APIRouter
from fastapi import Request
from fastapi.responses import PlainTextResponse
from fastapi.responses import JSONResponse
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
from fastapi.staticfiles import StaticFiles

from backend.api import chat
from backend.api import feedback
from backend.config import startup
from backend.config.models import ChatRequest
from backend.config.models import FeedbackRequest
from backend.config.models import ChatResponse
from backend.config.models import FeedbackResponse


# Configure logging
logging.basicConfig(level=logging.ERROR, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')


# Initialize FastAPI app
app = FastAPI(title="AI Assistant",
              description="Azure AI Assistant",
              version="0.0.1",
              debug=False)


# Initialize API router
router = APIRouter()


# Define the lifespan context manager
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup code
    logging.info("Application startup: Initializing resources")
    startup.init_search_index()
    yield
    # Shutdown code

# Set the lifespan context manager
app.router.lifespan_context = lifespan


# Get the current directory
app_directory = os.path.dirname(os.path.abspath(__file__))


# Load Jinja2 templates
templates_directory = os.path.join(app_directory, "frontend/templates")
templates = Jinja2Templates(directory=templates_directory)


# Mount static files directory
static_directory = os.path.join(app_directory, "frontend/static")
app.mount("/static", StaticFiles(directory=static_directory), name="static")


# Set up assistant index page
@app.get("/", tags=["index"], response_class=HTMLResponse)
def index(request: Request):
    return templates.TemplateResponse("index.html", {"request": request})


# Set up health check endpoint
@app.get("/ping", tags=["health_check"], response_class=PlainTextResponse)
async def ping():
    version = sys.version_info
    return f"Azure AI Assistant API Backend Services running on Python v{version.major}.{version.minor}"


# Set up API route for chat endpoint
@router.post("/chat", tags=["chat_api_endpoint"], response_model=ChatResponse)
async def chat_endpoint(request: ChatRequest):
    return chat.run(request)


# Set up API route for feedback endpoint
@router.post("/feedback", tags=["feedback_api_endpoint"], response_model=FeedbackResponse)
async def feedback_endpoint(request: FeedbackRequest):
    return feedback.run(request)


# Set middleware to intercept requests and include process time in response header 
@app.middleware("http")
async def add_process_time_header(request, call_next):
    start_time = time.time()
    response = await call_next(request)
    process_time = time.time() - start_time
    response.headers["X-Process-Time"] = str(f'{process_time:0.4f} sec')
    return response


# Set exception handler for all unhandled exceptions
@app.exception_handler(Exception)
async def validation_exception_handler(request, err):
    logging.error(f"Unhandled exception: {err}", exc_info=True)
    return JSONResponse(
        status_code = 500,
        content = {
            "reason": f"{err}",
            "source": {
                "url": f"{request.url}",
                "method": f"{request.method}"
            }
        }
    )


# Add API routes and prefix
app.include_router(router, prefix="/api", tags=["api_routes_v1"])


if __name__ == "__main__":
    # Run the FastAPI app using Uvicorn server
    uvicorn.run("main:app", host="0.0.0.0", port=8000)