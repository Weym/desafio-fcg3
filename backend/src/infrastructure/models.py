"""Central model registry for Alembic discovery."""

from importlib import import_module

from infrastructure.database import Base


MODEL_MODULES = (
    "features.auth.models",
    "features.courses.models",
    "features.enrollment.models",
    "features.students.models",
    "features.documents.models",
    "features.scheduling.models",
    "features.chat.models",
    "features.knowledge_base.models",
)


for module_path in MODEL_MODULES:
    try:
        import_module(module_path)
    except ModuleNotFoundError:
        continue


__all__ = ["Base"]
