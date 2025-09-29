#!/bin/bash
set -e # Exit immediately if any command fails

python3.11 install_jobrunner.py # Install the jobrunner

# Set up necessary environment variables (optional)
# export CONDA_EXE=/opt/conda/bin/conda

python3.11 -m datoma_jobrunner # Run the jobrunner module