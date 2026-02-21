#!/usr/bin/env python
"""
Script principal para ejecutar la aplicación.
"""
import sys
import multiprocessing

# ─── CRITICAL: must run BEFORE any heavy imports ───────────────────────
# In a frozen Windows exe, every spawned child re-executes this script.
# freeze_support() detects child processes and handles them immediately,
# preventing an infinite process-spawn loop.
multiprocessing.freeze_support()

if __name__ == "__main__":
    from pathlib import Path

    PROJECT_DIR = Path(__file__).resolve().parent
    sys.path.insert(0, str(PROJECT_DIR))

    from src.ui.flet_app import run_app
    run_app()
