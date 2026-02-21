#!/usr/bin/env python
"""
Script principal para ejecutar la aplicación.
"""
import sys
from pathlib import Path

# Agregar el directorio del proyecto al path
PROJECT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(PROJECT_DIR))

from src.ui.flet_app import run_app

if __name__ == "__main__":
    run_app()
