<#
    .SYNOPSIS
    Start the stable diffusion webui application

    .DESCRIPTION
    Start the stable diffusion webui application. This script will create the
    virtual environment for the installation and then start the webui.

    You can customize the parameters in the file webui-user.ps1 or webui-user.COMPUTERNAME.ps1
    If the file webui-user.COMPUTERNAME.ps1 is present in this directory, it will be used instead
    of the default one.

    Use the -Verbose option for detailed output

    .PARAMETER DryRun
    Will not perform any operation (create venv and start application)
    Usefull to check the folders and options while tuning the webui-user.ps1 (or webui-user.COMPUTERNAME.ps1) file

    .PARAMETER AutoRestart
    Will restart stable diffusion if the process stop. This restart will occured only if : 
    1. This script did not restart any other stable diffusion
    2. The stable diffusion had not been restarted

    .PARAMETER KillOnly
    Do not start stable diffusion, but kill it if it is running. 
    This parameter will disregard AutoRestart if provided.

    .INPUTS
    None. You can't pipe objects to Add-Extension.

#>

param(
     [Parameter()]
     [switch]$DryRun,
     [Parameter()]
     [switch]$AutoRestart,
     [Parameter()]
     [switch]$Killonly

 )
 


####
#### Functions
####

## Required to check if already running
$TypeData = @{
    TypeName   = [System.Diagnostics.Process].ToString()
    MemberType = [System.Management.Automation.PSMemberTypes]::ScriptProperty
    MemberName = 'CommandLine'
    Value = {
        if (('Win32NT' -eq [System.Environment]::OSVersion.Platform)) { # it's windows
            (Get-CimInstance Win32_Process -Filter "ProcessId = $($this.Id)").CommandLine
        } elseif (('Unix' -eq [System.Environment]::OSVersion.Platform)) { # it's linux/unix
            Get-Content -LiteralPath "/proc/$($this.Id)/cmdline"
        } 
    }
}
Update-TypeData @TypeData -ErrorAction Ignore
function Get-StableDiffusionProcesses {
    param
    (
      [Parameter(ValueFromPipeline)]
      [System.ComponentModel.Component[]]
      $Processes
    )
    if ($null -eq $Processes) {
        $Processes= ([array](Get-Process -Name 'accelerate' -ErrorAction SilentlyContinue) + [array](Get-Process -Name 'python' -ErrorAction SilentlyContinue))
    }
    $searchRegex= ".?$virtual_env_directory.*launch.*"  
    $selectedProcesses= @()  
    foreach($process in $Processes){
        if ($process.CommandLine -match $searchRegex) {
            $selectedProcesses+= $process
        } 
    }
    return $selectedProcesses
}

function Stop-StableDiffusion() {
    $processes= Get-StableDiffusionProcesses
    if (($processes | Measure-Object).Count -gt 0) {
        Write-Warning "Found at least one process already running"
        $processes | Format-Table -Property Id, StartTime, ProcessName
        Write-Warning "Stop those processes"
        if (-not $DryRun) {
            $processes | Stop-Process -ErrorAction Continue
        }
    }    
}
## Resolve-Path does not work with non existing path. This one does
function Get-UnresolvedPath {
    param (
        [string]
        $Path
    )    
    return $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
}

####
#### Main script
####
if ($DryRun) {
    Write-Host "Running in dry run mode."
}
if (!$DryRun) {
    Write-Host "Running in real mode."
}

if ($Killonly) {
    Write-Host "Only stopping stable diffusions processes"
    Stop-StableDiffusion
    exit 0    
}

#Define the directory of the stable-diffusion-webui (the location of this script), either current ps script root or current directory
if ([string]::IsNullOrEmpty($PSScriptRoot)) {
    $stable_diffusion_webui_dir=Resolve-Path .
} else {
    $stable_diffusion_webui_dir=Resolve-Path $PSScriptRoot
}

$temp_dir= Join-Path -Path $stable_diffusion_webui_dir -ChildPath "tmp"

Write-Verbose "Stable diffusion webui directory : $stable_diffusion_webui_dir"
Write-Verbose "Stable diffusion tmp directory   : $temp_dir"

if (-not $DryRun) {
    New-Item -ItemType Directory -Force -Path "$temp_dir" -ErrorAction SilentlyContinue
}

$default_option_file= Join-Path -Path $stable_diffusion_webui_dir -ChildPath "webui-user.ps1"
$computer_option_file= Join-Path -Path $stable_diffusion_webui_dir -ChildPath "webui-user.$env:COMPUTERNAME.ps1"

if (Test-Path -Path $computer_option_file) {
    Write-Verbose "Using computer specific option file $computer_option_file"
    $option_file= $computer_option_file
} elseif (Test-Path -Path $default_option_file) {
    Write-Verbose "Using default option file $default_option_file"
    $option_file= $default_option_file
} else {
    Write-Error "Unable to locate option file, one of the following file must be present :"
    Write-Error "$default_option_file"
    Write-Error "$computer_option_file"
    exit
}

Write-Output "Sourcing option file $(Split-Path $option_file -leaf)"
. $option_file

if ($command_line_arguments -eq $null) {
    Write-Warning "Command line arguments was null"
    $command_line_arguments= @()
}

if (-not [string]::IsNullOrEmpty($env:DATA_DIR)) {
    if (-not (Test-Path $env:DATA_DIR)) {
        Write-Warning "Data directory provided does not exists : $env:DATA_DIR"
    }
    $command_line_arguments+= ("--data-dir", "`"$env:DATA_DIR`"")
}

if([string]::IsNullOrEmpty($env:python_cmd)) {
    Write-Verbose "Setting default python_cmd"
    $python_cmd= "python.exe"
} else {
    $python_cmd= $env:python_cmd
}

if([string]::IsNullOrEmpty($python_venv_interpreter)) {
    Write-Verbose "Setting venv interpreter to default python interpreter"
    $python_venv_interpreter= $python_cmd
}
if([string]::IsNullOrEmpty($venv_dir)) {
    $venv_dir= "$stable_diffusion_webui_dir\venv"
}


$python_cmd_path= (Get-Command -ErrorAction Ignore "$python_cmd" | Resolve-Path -ErrorAction Ignore).Path
$python_venv_interpreter_path= (Get-Command -ErrorAction Ignore "$python_venv_interpreter" | Resolve-Path -ErrorAction Ignore).Path
$venv_path= Get-UnresolvedPath "$venv_dir"
$venv_python= Join-Path -Path $venv_path -ChildPath "Scripts\python.exe"
$venv_activate = Join-Path -Path $venv_path -ChildPath "Scripts\activate.ps1"
$venv_accelerate = Join-Path -Path $venv_path -ChildPath "Scripts\accelerate.exe"

Write-Host    "Python command          : $python_cmd"
Write-Verbose "Python command path     : $python_cmd_path"
Write-Verbose "Python venv command path: $python_venv_interpreter_path"
Write-Host    "Python venv interpreter : $python_venv_interpreter"
Write-Host    "Pyhon venv directory    : $venv_path"

if([string]::IsNullOrEmpty($python_cmd_path)) {
    Write-Error "Python command not found. Command path : $python_cmd"
    if (-not $DryRun) {
        exit 1
    }
}

$need_create_venv= (-not (Get-Command -ErrorAction Ignore $venv_python) -or -not (Test-Path $venv_path))

if (-not (Get-Command -ErrorAction Ignore $venv_python) -and [string]::IsNullOrEmpty($python_venv_interpreter_path)) {
    Write-Error "Virtual environment python executable command is invalid and the python interpreter $python_venv_interpreter_path is invalid. Could not create virtual environment"
    if (-not $DryRun) {
        exit 1
    }

}

if ($need_create_venv) {
    Write-Warning "Creating virtual environment on path $venv_path. Requested interpreter : $python_venv_interpreter_path"
    $args= @("-m", 
             "virtualenv",
             "-p",
             "`"$python_venv_interpreter_path`"",
             "`"$venv_dir`"")
    if (-not $DryRun) {
        Write-Host -ForegroundColor Blue "** Create venv"
        Write-Host -ForegroundColor Blue $("-" * $Host.UI.RawUI.WindowSize.Width)
        $cmd= "& `"$python_cmd_path`" -m virtualenv -p `"$python_venv_interpreter_path`" `"$venv_dir`""
        Write-Host $cmd
        Invoke-Expression $cmd
        if ($LASTEXITCODE -ne 0) {
            Write-Host -ForegroundColor Red $("-" * $Host.UI.RawUI.WindowSize.Width)
            Write-Error "Unable to create venv in directory $VENV_DIR"
            exit 2
        }        
        Write-Host -ForegroundColor Blue $("-" * $Host.UI.RawUI.WindowSize.Width)
        Write-Host -ForegroundColor Blue "** Create venv SUCCESS"

    }
}

if (-not (Get-Command -ErrorAction Ignore $venv_python)) {
    Write-Error "Virtual environment python command is invalid : $ven_python"
    if (-not $DryRun) {
        exit 3
    }
}

if (-not (Test-Path -ErrorAction Ignore $venv_activate)) {
    Write-Error "Virtual environment activation script not found : $venv_activate"
    if (-not $DryRun) {
        exit 3
    }
}

$venv_python_cmd= (Get-Command -ErrorAction Ignore "$venv_python" | Resolve-Path -ErrorAction Ignore).Path
$venv_activate_cmd = (Get-Command -ErrorAction Ignore "$venv_activate" | Resolve-Path -ErrorAction Ignore).Path
$venv_accelerate_cmd = (Get-Command -ErrorAction Ignore "$venv_accelerate" | Resolve-Path -ErrorAction Ignore).Path

if ([string]::IsNullOrEmpty($venv_activate_cmd)) {
    Write-Error "Venv activate script not found $venv_activate"
    if (-not $DryRun) {
        exit 4
    }
}
if ([string]::IsNullOrEmpty($venv_python_cmd)) {
    Write-Error "VENV Python executable not found : $venv_python"
    if (-not $DryRun) {
        exit 4
    }
}

Write-Host "Arguments : $command_line_arguments"
Write-Host -ForegroundColor Blue "** Activate venv"
if (-not $DryRun) {
    Invoke-Expression ". `"$venv_activate`""
}

$CMD_PROG="$venv_python_cmd"
$CMD_ARGS=@()
if ($env:ACCELERATE -eq 'True') {
    Write-Verbose "Accelerate requested"
    if ([string]::IsNullOrEmpty($venv_accelerate_cmd)) {
        Write-Warning "The environment variable ACCELERATE (env:ACCELERATE) is True but $venv_accelerate_cmd not found. Fallback to normal launch"
    } else {
        Write-Host "Launching with Accelerate"
        $CMD_PROG="`"$venv_accelerate_cmd`""
        $CMD_ARGS=@("launch", "--num_cpu_threads_per_process=6")
    }
}
$CMD_ARGS+= "launch.py"
$CMD_ARGS+= $command_line_arguments

Write-Verbose "Check if already running"
Stop-StableDiffusion

function Start-StableDiffusion() {
    $process= Start-Process "$CMD_PROG" -ArgumentList $CMD_ARGS -NoNewWindow -PassThru
    Write-Warning "Process launched with ID $($process.Id)"
    Write-Host -ForegroundColor Blue $("=" * $Host.UI.RawUI.WindowSize.Width)
    Write-Host -ForegroundColor Blue $("=" * $Host.UI.RawUI.WindowSize.Width)
    return $process
}

$PIDFILE="$temp_dir\webui.ps1.pid"
Write-Host "Launching $CMD_PROG with arguments $CMD_ARGS"
if (-not $DryRun) {
    $PID | Out-File -FilePath "$PIDFILE"
    (Start-StableDiffusion).WaitForExit()
    if ($AutoRestart) {
        while ($true) {
            #Check if we are still the last running process
            $lastPid= Get-Content -Path "$PIDFILE"
            if ($PID -ne $lastPid) {
                Write-Error "Auto restart canceled, my pid $PID last Pid $lastPid"
                exit 0
            }
            #Check if had been restarted
            if ((Get-StableDiffusionProcesses | Measure-Object).Count -gt 0) {
                Write-Error "Auto restart canceled, for some reason stable diffusion is running"
                exit 0
            }
            (Start-StableDiffusion).WaitForExit()            
        }
    }
}