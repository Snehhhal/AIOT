from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from backend.app.core.config import settings
from backend.app.core.seed import seed_initial_data
from backend.app.api.v1.auth import router as auth_router
from backend.app.api.v1.telemetry import router as telemetry_router
from backend.app.api.v1.poles import router as poles_router
from backend.app.api.v1.alerts import router as alerts_router
from backend.app.api.v1.vision import router as vision_router
from backend.app.api.v1.assistant import router as assistant_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: Run schema migrations & seed default data
    print("=" * 70)
    print(f"  {settings.APP_NAME}")
    print(f"  Environment: {settings.APP_ENV} | Debug: {settings.DEBUG}")
    print(f"  Single User-Facing Frontend: FLUTTER MOBILE APPLICATION")
    print(f"  Database Engine: {settings.async_database_url or 'SQLite Fallback'}")
    print("=" * 70)
    try:
        await seed_initial_data()
    except Exception as e:
        print(f"[!] Warning during database initialization: {e}")
    yield
    print("Shutting down Electric Pole Safety Platform...")


app = FastAPI(
    title=settings.APP_NAME,
    version="1.0.0",
    description="AI and IoT Based Leakage Detection in Electric Pole and Life Safety Backend API",
    lifespan=lifespan
)

# CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins or ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include API v1 Routers
app.include_router(auth_router, prefix=settings.API_V1_STR)
app.include_router(telemetry_router, prefix=settings.API_V1_STR)
app.include_router(poles_router, prefix=settings.API_V1_STR)
app.include_router(alerts_router, prefix=settings.API_V1_STR)
app.include_router(vision_router, prefix=settings.API_V1_STR)
app.include_router(assistant_router, prefix=settings.API_V1_STR)


@app.get("/health", tags=["Health"])
@app.get(f"{settings.API_V1_STR}/health", tags=["Health"])
async def health_check():
    return {
        "status": "online",
        "app_name": settings.APP_NAME,
        "environment": settings.APP_ENV,
        "simulation_mode": settings.SIMULATION_MODE,
        "supported_roles": ["CITIZEN", "TECHNICIAN", "ENGINEER", "AUTHORITY", "ADMIN"],
        "version": "1.0.0"
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "backend.main:app",
        host=settings.BACKEND_HOST,
        port=settings.BACKEND_PORT,
        reload=settings.DEBUG
    )
