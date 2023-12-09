#!/bin/bash
#########################################################
# Uncomment and change the variables below to your need:#
#########################################################

# Install directory without trailing slash
#install_dir="/home/$(whoami)"

# Name of the subdirectory
#clone_dir="stable-diffusion-webui"

# Commandline arguments for webui.py, for example: export COMMANDLINE_ARGS="--medvram --opt-split-attention"
#export COMMANDLINE_ARGS=""
if ! hash nvidia-smi &> /dev/null ; then
  export COMMANDLINE_ARGS="--opt-sdp-attention --listen --enable-insecure-extension-access --allow-code --use-cpu all --no-half --no-half-vae --skip-torch-cuda-test --lowvram --loglevel info ${EXTRA_COMMANDLINE_ARGS}"
else
  export COMMANDLINE_ARGS="--listen --enable-insecure-extension-access --allow-code --loglevel info ${EXTRA_COMMANDLINE_ARGS}"
fi
# python3 executable
#python_cmd="python3"

# git executable
#export GIT="git"

# python3 venv without trailing slash (defaults to ${install_dir}/${clone_dir}/venv)
#venv_dir="venv"

# script to launch to start the app
#export LAUNCH_SCRIPT="launch.py"

# install command for torch
if ! hash nvidia-smi &> /dev/null ; then
  export TORCH_COMMAND="pip install torch==1.12.1+cpu --extra-index-url https://download.pytorch.org/whl/cpu"
  export NO_TCMALLOC="True"
fi

#export TORCH_COMMAND="pip install torch==1.12.1+cu113 --extra-index-url https://download.pytorch.org/whl/cu113"

# Requirements file to use for stable-diffusion-webui
#export REQS_FILE="requirements_versions.txt"

# Fixed git repos
#export K_DIFFUSION_PACKAGE=""
#export GFPGAN_PACKAGE=""

# Fixed git commits
#export STABLE_DIFFUSION_COMMIT_HASH=""
#export CODEFORMER_COMMIT_HASH=""
#export BLIP_COMMIT_HASH=""

# Uncomment to enable accelerated launch
export ACCELERATE="True"

# Uncomment to disable TCMalloc
#export NO_TCMALLOC="True"

###########################################
