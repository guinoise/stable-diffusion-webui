### Copy this file to webui-user.COMPUTERNAME.ps1 to customize for specific computer
### Use this file for default (computer without specific files) on all your environments
### Copy-Item webui-user.ps1 webui-user.$env:COMPUTERNAME.ps1

#########################################################
# Uncomment and change the variables below to your need:#
#########################################################

#Define the directory of the stable-diffusion-webui (the location of this script), either current ps script root or current directory
if ([string]::IsNullOrEmpty($PSScriptRoot)) {
    $stable_diffusion_webui_dir=Resolve-Path .
} else {
    $stable_diffusion_webui_dir=Resolve-Path $PSScriptRoot
}


# Commandline arguments for webui.py, as an array. 
# For example arguments "--medvram --opt-split-attention" will become
#$command_line_arguments= @("--medvram", "--opt-split-attention")
$command_line_arguments= @("--listen", 
                            "--enable-insecure-extension-access",
                            "--theme dark",
                            "--allow-code",
                            "--api",
                            "--loglevel info",
                            "--xformers",
                            "--use-cpu", "all", 
                            "--no-half", 
                            "--no-half-vae", 
                            "--skip-torch-cuda-test",
							"--skip-load-model-at-start"
                            )

#                            "--ui-debug-mode",
# python3 executable
#$env:python_cmd="python.exe"

# python executable to create venv if required. 
# by default $env:python_cmd or python.exe will be used
# use this variable for a specific version of python currently sd webui require python3.10
$python_venv_interpreter="$env:UserProfile\AppData\Local\Programs\Python\Python310\python.exe"

# python3 venv directory (defaults to $stable_diffusion_webui_dir/venv
# could be relative path to $stable_diffusion_webui_dir
$venv_dir="../venv"
# $venv_dir="venv"

# Stable diffusion data-dir
# If provided the option --data-dir will be populated automatically
# Could be relative to $stable_diffusion_webui_dir
$env:DATA_DIR="../data_dir"

# script to launch to start the app
#$LAUNCH_SCRIPT="launch.py"

# install command for torch
# examples with CUDA or CPU (no CUDA available)
#$env:TORCH_COMMAND="pip install torch==1.12.1+cu113 --extra-index-url https://download.pytorch.org/whl/cu113"
$env:TORCH_COMMAND="pip install torch==2.0.1+cpu --extra-index-url https://download.pytorch.org/whl/cpu"

# Requirements file to use for stable-diffusion-webui
#$env:REQS_FILE="requirements_versions.txt"

# Uncomment to enable accelerated launch
#$env:ACCELERATE="True"

###########################################
