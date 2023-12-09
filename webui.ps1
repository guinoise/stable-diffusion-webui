#Define base directory, either current ps script root or current directory
if ([string]::IsNullOrEmpty($PSScriptRoot)) {
    $BASE_DIR=Resolve-Path .
} else {
    $BASE_DIR=Resolve-Path $PSScriptRoot
}
function Get-UnresolvedPath {
    param (
        [string]
        $Path
    )    
    return $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
}
function Start-Venv {
    if ($VENV_DIR -eq '-') {
        Skip-Venv
    }
    $VENV_PYTHON= Resolve-Path -ErrorAction Ignore "$VENV_DIR\Scripts\python.exe"
#    Write-Host "VENVPYTHON .$VENV_PYTHON."
#    Write-Host "    PYTHON .$PYTHON."
#    Write-Host "$(($VENV_PYTHON | Out-String) -eq ($PYTHON | Out-String))"    
    if ([string]::IsNullOrEmpty($VENV_PYTHON) -or ($VENV_PYTHON | Out-String) -ne ($PYTHON | Out-String)) {
        New-VENV
    }
    Enter-Venv
}

function New-VENV {
    if ([string]::IsNullOrEmpty($VENV_CREATE_PYTHON_VERSION)) {
        $VENV_CREATE_PYTHON_VERSION=$PYTHON
    }
    Write-Output "Creating venv in directory $VENV_DIR using python $VENV_CREATE_PYTHON_VERSION and module virtualenv"
    Invoke-Expression "$VENV_CREATE_PYTHON_VERSION -m virtualenv $VENV_DIR"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Unable to create venv in directory $VENV_DIR"
        exit 2
    }    
}

function Enter-Venv {
    if ($PYTHON -ne "$VENV_DIR\Scripts\Python.exe") {
        $PYTHON = "$VENV_DIR\Scripts\Python.exe"
        $ACTIVATE = "$VENV_DIR\Scripts\activate.bat"
        Invoke-Expression "cmd.exe /c $ACTIVATE"
        Write-Output "Venv set to $VENV_DIR."
    } else {
        Write-Output "Already in VENV."
    }
    Start-App
}

function Skip-Venv {
    Write-Output "Venv set to $VENV_DIR."
    Start-App
}

function Start-App {
    #test-accelerate
    Write-Output 'Checking for accelerate'
    $ACCELERATE_PROG = "$VENV_DIR\Scripts\accelerate.exe"
#    Write-Output "ACCELERATE : $ACCELERATE ACCELERATE_PROG : $ACCELERATE_PROG Test-Path: $(Test-Path -Path $ACCELERATE_PROG)"
    if ($ACCELERATE -eq 'True' -and (Test-Path -Path $ACCELERATE_PROG)) {
        Write-Output 'Accelerating'
        $PROG="$ACCELERATE_PROG launch --num_cpu_threads_per_process=6"
    } else {
        Write-Output "Launching with python"
        $PROG="$PYTHON"
    }
    $FINAL_COMMAND="$PROG $LAUNCH_SCRIPT $LAUNCH_OPTIONS_FINAL"
    Write-Output "Command: $FINAL_COMMAND"
    Invoke-Expression "$FINAL_COMMAND"
    #pause
    exit
}


## OPTIONS START HERE
#
## Options for specific computer
$LAUNCH_OPTIONS_COMMON="--listen --enable-insecure-extension-access --theme dark --allow-code --api --loglevel info"
if ($env:COMPUTERNAME -eq "GATAS-ONE") {
    if ([string]::IsNullOrEmpty($env:VENV_DIR)) {
        $VENV_DIR = Get-UnresolvedPath "$BASE_DIR\..\venv"
    } else {
        $VENV_DIR = $env:VENV_DIR
    }
    $DATA_DIR = Get-UnresolvedPath "$BASE_DIR\..\data_dir"
    $LAUNCH_OPTIONS_SPECIFIC="--use-cpu all --no-half --no-half-vae --skip-torch-cuda-test"
    $env:TORCH_COMMAND="pip install torch==2.0.1+cpu --extra-index-url https://download.pytorch.org/whl/cpu"    
    $VENV_CREATE_PYTHON_VERSION= Resolve-Path -ErrorAction Ignore "$env:UserProfile\AppData\Local\Programs\Python\Python310\python.exe"

} elseif ($env:COMPUTERNAME -eq "MONSTER") {
    if ([string]::IsNullOrEmpty($env:VENV_DIR)) {
        $VENV_DIR = "$BASE_DIR\venv"
    } else {
        $VENV_DIR = $env:VENV_DIR
    }    
    $DATA_DIR = "$BASE_DIR"
    $LAUNCH_OPTIONS_SPECIFIC="--xformers"
    $VENV_CREATE_PYTHON_VERSION= Resolve-Path -ErrorAction Ignore "$env:UserProfile\AppData\Local\Programs\Python\Python310\python.exe"
} else {
    if ([string]::IsNullOrEmpty($env:VENV_DIR)) {
        $VENV_DIR = Get-UnresolvedPath "$BASE_DIR\venv"
    } else {
        $VENV_DIR = $env:VENV_DIR
    }
    $DATA_DIR = "$BASE_DIR"
    $LAUNCH_OPTIONS_SPECIFIC="--xformers --listen --enable-insecure-extension-access --theme dark --allow-code --api --loglevel info"
}

$LAUNCH_OPTIONS_FINAL="$LAUNCH_OPTIONS_COMMON $LAUNCH_OPTIONS_SPECIFIC --data-dir $DATA_DIR"

if ([string]::IsNullOrEmpty($env:PYTHON) -and [string]::IsNullOrEmpty($PYTHON)) {
    $PYTHON = Get-Command "Python.exe" | Resolve-Path
} elseif ([string]::IsNullOrEmpty($PYTHON))  {
    $PYTHON = $env:PYTHON
}

if ([string]::IsNullOrEmpty($env:LAUNCH_SCRIPT)) {
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
    Write-Output "Couldn't launch python. $PYTHON"
}