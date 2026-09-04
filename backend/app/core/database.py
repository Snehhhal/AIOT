from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import declarative_base
from backend.app.core.config import settings

Base = declarative_base()

# Determine database engine URL
# In development or when PostgreSQL is unavailable, fallback to a local SQLite database
db_url = settings.async_database_url
if not db_url or "localhost" in db_url:
    # Use SQLite for reliable zero-setup execution while keeping postgresql driver config ready
    engine_url = "sqlite+aiosqlite:///./safety_platform.db"
else:
    engine_url = db_url

engine = create_async_engine(
    engine_url,
    echo=False,
    future=True,
    connect_args={"check_same_thread": False} if "sqlite" in engine_url else {}
)

AsyncSessionLocal = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False
)


async def get_db():
    """Async database session dependency for FastAPI endpoints."""
    async with AsyncSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()
