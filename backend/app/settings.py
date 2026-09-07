from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    database_url: str = "postgresql://postgres:postgres@localhost:5432/techselect"
    cors_origins: list[str] = ["http://localhost:5173"]
    openai_api_key: str | None = None
    openai_model: str = "gpt-5"
    site_url: str = "https://techselectai.com"
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

settings = Settings()
