function Get-UnresolvedPath($p) {
    return $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($p)
}

if ($null -eq $PSScriptRoot -or $PSScriptRoot -eq "") {
    $BASE_DIR=Resolve-Path .
} else {
    $BASE_DIR=Resolve-Path $PSScriptRoot
}

function Start-Venv {
    if ($VENV_DIR -eq '-') {
        Skip-Venv
    }

    if (Test-Path -Path "$VENV_DIR\Scripts\$python") {
        Enter-Venv
    } else {
        $PYTHON_FULLNAME = & $PYTHON -c "import sys; print(sys.executable)"
        Write-Output "Creating venv in directory $VENV_DIR using python $PYTHON_FULLNAME"
        Invoke-Expression "$PYTHON_FULLNAME -m virtualenv $VENV_DIR"
        if ($LASTEXITCODE -eq 0) {
            Enter-Venv
        } else {
            Write-Output "Unable to create venv in directory $VENV_DIR"
        }
    }
}

function Enter-Venv {
    #$PYTHON = "$VENV_DIR\Scripts\Python.exe"
    $ACTIVATE = "$VENV_DIR\Scripts\activate.bat"
    Invoke-Expression "cmd.exe /c $ACTIVATE"
    Write-Output "Venv set to $VENV_DIR."
    if ($ACCELERATE -eq 'True') {
        Test-Accelerate
    } else {
        Start-App
    }
}

function Skip-Venv {
    Write-Output "Venv set to $VENV_DIR."
    if ($ACCELERATE -eq 'True') {
        Test-Accelerate
    } else {
        Start-App
    }
}

function Test-Accelerate {
    Write-Output 'Checking for accelerate'
    $ACCELERATE = "$VENV_DIR\Scripts\accelerate.exe"
    if (Test-Path -Path $ACCELERATE) {
        Start-Accelerate
    } else {
        Start-App
    }
}

function Start-App {
    Write-Output "Launching with python"
    Invoke-Expression "$PYTHON $LAUNCH_SCRIPT $LAUNCH_OPTIONS_FINAL"
    #pause
    exit
}

function Start-Accelerate {
    Write-Output 'Accelerating'
    Invoke-Expression "$ACCELERATE launch --num_cpu_threads_per_process=6 $LAUNCH_SCRIPT $LAUNCH_OPTIONS_FINAL"
    #pause
    exit
}


## OPTIONS START HERE
#
## Options for specific computer
$LAUNCH_OPTIONS_COMMON="--listen --enable-insecure-extension-access --theme dark --allow-code --api --loglevel info"
if ($env:COMPUTERNAME -eq "GATAS-ONE") {
    if ($env:VENV_DIR -eq "" -or $null -eq $env:VENV_DIR) {
        $VENV_DIR = Get-UnresolvedPath "$BASE_DIR\..\venv"
    } else {
        $VENV_DIR = $env:VENV_DIR
    }
    $DATA_DIR = Get-UnresolvedPath "$BASE_DIR\..\data_dir"
    $LAUNCH_OPTIONS_SPECIFIC="--use-cpu all --no-half --no-half-vae --skip-torch-cuda-test"
    $env:TORCH_COMMAND="pip install torch==2.0.1+cpu --extra-index-url https://download.pytorch.org/whl/cpu"    
} elseif ($env:COMPUTERNAME -eq "MONSTER") {
    if ($env:VENV_DIR -eq "" -or $null -eq $env:VENV_DIR) {
        $VENV_DIR = "$BASE_DIR\venv"
    } else {
        $VENV_DIR = $env:VENV_DIR
    }    
    $DATA_DIR = "$BASE_DIR"
    $LAUNCH_OPTIONS_SPECIFIC="--xformers"
} else {
    if ($env:VENV_DIR -eq "" -or $null -eq $env:VENV_DIR) {
        $VENV_DIR = Get-UnresolvedPath "$BASE_DIR\venv"
    } else {
        $VENV_DIR = $env:VENV_DIR
    }
    $DATA_DIR = "$BASE_DIR"
    $LAUNCH_OPTIONS_SPECIFIC="--xformers --listen --enable-insecure-extension-access --theme dark --allow-code --api --loglevel info"
}

$LAUNCH_OPTIONS_FINAL="$LAUNCH_OPTIONS_COMMON $LAUNCH_OPTIONS_SPECIFIC --data-dir $DATA_DIR"

if ($env:PYTHON -eq "" -or $null -eq $env:PYTHON) {
    $PYTHON = "Python.exe"
} else {
    $PYTHON = $env:PYTHON
}

if ($env:LAUNCH_SCRIPT -eq "" -or $null -eq $env:LAUNCH_SCRIPT) {
    $LAUNCH_SCRIPT = "$BASE_DIR\launch.py"
} else {
    $LAUNCH_SCRIPT = $env:LAUNCH_SCRIPT
}

#$ERROR_REPORTING = $false
$tmp_dir = Get-UnresolvedPath "$DATA_DIR\tmp"
mkdir "$tmp_dir" 2>$null



try {
    if(Get-Command $PYTHON){
        Start-Venv
    }
} Catch {
    Write-Output "Couldn't launch python."
}