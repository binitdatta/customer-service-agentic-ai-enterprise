from pathlib import Path
from dotenv import load_dotenv

# Load .env BEFORE importing app modules/config
project_root = Path(__file__).resolve().parent
env_path = project_root / ".env"
load_dotenv(dotenv_path=env_path, override=False)

from app import create_app  # noqa: E402

app = create_app()
