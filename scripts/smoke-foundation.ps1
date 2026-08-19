[CmdletBinding()]
param(
    [ValidateRange(1, 65535)]
    [int]$BackendPort = 8000,

    [ValidateRange(1, 65535)]
    [int]$FrontendPort = 5173,

    [ValidateRange(1, 120)]
    [int]$TimeoutSeconds = 20
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Net.Http

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$backendDirectory = Join-Path $repositoryRoot "backend"
$frontendDirectory = Join-Path $repositoryRoot "frontend"
$pythonPath = Join-Path $backendDirectory ".venv\Scripts\python.exe"
$npmPath = (Get-Command npm.cmd -ErrorAction Stop).Source
$runId = [Guid]::NewGuid().ToString("N")
$temporaryDirectory = [System.IO.Path]::GetTempPath()
$backendOutputLog = Join-Path $temporaryDirectory "mtg-smoke-$runId-backend.out.log"
$backendErrorLog = Join-Path $temporaryDirectory "mtg-smoke-$runId-backend.err.log"
$frontendOutputLog = Join-Path $temporaryDirectory "mtg-smoke-$runId-frontend.out.log"
$frontendErrorLog = Join-Path $temporaryDirectory "mtg-smoke-$runId-frontend.err.log"

$backendProcess = $null
$frontendProcess = $null
$httpClient = [System.Net.Http.HttpClient]::new()
$httpClient.Timeout = [TimeSpan]::FromSeconds(2)
$failure = $null

function Assert-PortAvailable {
    param(
        [Parameter(Mandatory)]
        [int]$Port,

        [Parameter(Mandatory)]
        [string]$ApplicationName
    )

    $listener = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
    if ($null -ne $listener) {
        throw "$ApplicationName cannot start because port $Port is already in use."
    }
}

function Wait-ForEndpoint {
    param(
        [Parameter(Mandatory)]
        [string]$ApplicationName,

        [Parameter(Mandatory)]
        [string]$Uri,

        [Parameter(Mandatory)]
        [System.Diagnostics.Process]$Process,

        [Parameter(Mandatory)]
        [int]$Timeout
    )

    $deadline = [DateTime]::UtcNow.AddSeconds($Timeout)
    $lastObservation = "No response received."

    while ([DateTime]::UtcNow -lt $deadline) {
        $Process.Refresh()
        if ($Process.HasExited) {
            throw "$ApplicationName exited before becoming ready with exit code $($Process.ExitCode)."
        }

        try {
            $response = $httpClient.GetAsync($Uri).GetAwaiter().GetResult()
            $content = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
            $statusCode = [int]$response.StatusCode
            $isSuccess = $response.IsSuccessStatusCode
            $response.Dispose()

            if ($isSuccess) {
                return $content
            }

            $lastObservation = "HTTP $statusCode"
        }
        catch {
            $lastObservation = $_.Exception.Message
        }

        Start-Sleep -Milliseconds 250
    }

    throw "$ApplicationName did not become ready at $Uri within $Timeout seconds. Last observation: $lastObservation"
}

function Assert-HealthyResponse {
    param(
        [Parameter(Mandatory)]
        [string]$ResponseBody,

        [Parameter(Mandatory)]
        [string]$BoundaryName
    )

    try {
        $body = $ResponseBody | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        throw "$BoundaryName returned invalid JSON: $ResponseBody"
    }

    $statusProperty = $body.PSObject.Properties["status"]
    if ($null -eq $statusProperty -or $statusProperty.Value -ne "ok") {
        throw "$BoundaryName returned an unexpected health body: $ResponseBody"
    }
}

function Stop-ProcessTree {
    param(
        [Parameter(Mandatory)]
        [int]$RootProcessId
    )

    $children = @(Get-CimInstance Win32_Process -Filter "ParentProcessId = $RootProcessId" -ErrorAction SilentlyContinue)
    foreach ($child in $children) {
        Stop-ProcessTree -RootProcessId $child.ProcessId
    }

    Stop-Process -Id $RootProcessId -Force -ErrorAction SilentlyContinue
}

function Write-ProcessLog {
    param(
        [Parameter(Mandatory)]
        [string]$ApplicationName,

        [Parameter(Mandatory)]
        [string]$OutputPath,

        [Parameter(Mandatory)]
        [string]$ErrorPath
    )

    Write-Host "--- $ApplicationName standard output ---"
    if (Test-Path -LiteralPath $OutputPath) {
        Get-Content -LiteralPath $OutputPath
    }

    Write-Host "--- $ApplicationName error output ---"
    if (Test-Path -LiteralPath $ErrorPath) {
        Get-Content -LiteralPath $ErrorPath
    }
}

try {
    if (-not (Test-Path -LiteralPath $pythonPath)) {
        throw "Backend Python environment was not found at $pythonPath. Complete backend setup first."
    }

    Assert-PortAvailable -Port $BackendPort -ApplicationName "FastAPI"
    Assert-PortAvailable -Port $FrontendPort -ApplicationName "Vite"

    Write-Host "Starting FastAPI on port $BackendPort..."
    $backendProcess = Start-Process `
        -FilePath $pythonPath `
        -ArgumentList @("-m", "uvicorn", "app.main:app", "--host", "127.0.0.1", "--port", $BackendPort) `
        -WorkingDirectory $backendDirectory `
        -WindowStyle Hidden `
        -RedirectStandardOutput $backendOutputLog `
        -RedirectStandardError $backendErrorLog `
        -PassThru

    $backendHealthUri = "http://127.0.0.1:$BackendPort/health"
    $backendHealthBody = Wait-ForEndpoint `
        -ApplicationName "FastAPI" `
        -Uri $backendHealthUri `
        -Process $backendProcess `
        -Timeout $TimeoutSeconds
    Assert-HealthyResponse -ResponseBody $backendHealthBody -BoundaryName "FastAPI"
    Write-Host "FastAPI is ready at $backendHealthUri."

    Write-Host "Starting Vite on port $FrontendPort..."
    $frontendProcess = Start-Process `
        -FilePath $npmPath `
        -ArgumentList @("run", "dev", "--", "--host", "127.0.0.1", "--port", $FrontendPort, "--strictPort") `
        -WorkingDirectory $frontendDirectory `
        -WindowStyle Hidden `
        -RedirectStandardOutput $frontendOutputLog `
        -RedirectStandardError $frontendErrorLog `
        -PassThru

    $frontendUri = "http://127.0.0.1:$FrontendPort/"
    [void](Wait-ForEndpoint `
        -ApplicationName "Vite" `
        -Uri $frontendUri `
        -Process $frontendProcess `
        -Timeout $TimeoutSeconds)
    Write-Host "Vite is ready at $frontendUri."

    $proxiedHealthUri = "http://127.0.0.1:$FrontendPort/health"
    $proxiedHealthBody = Wait-ForEndpoint `
        -ApplicationName "Vite proxy health boundary" `
        -Uri $proxiedHealthUri `
        -Process $frontendProcess `
        -Timeout $TimeoutSeconds
    Assert-HealthyResponse -ResponseBody $proxiedHealthBody -BoundaryName "Vite proxy health boundary"
    Write-Host "Vite reached FastAPI through $proxiedHealthUri."
    Write-Host "Foundation smoke check passed."
}
catch {
    $failure = $_
}
finally {
    if ($null -ne $frontendProcess) {
        Stop-ProcessTree -RootProcessId $frontendProcess.Id
    }

    if ($null -ne $backendProcess) {
        Stop-ProcessTree -RootProcessId $backendProcess.Id
    }

    $httpClient.Dispose()
}

if ($null -ne $failure) {
    Write-Error "Foundation smoke check failed: $($failure.Exception.Message)" -ErrorAction Continue
    Write-ProcessLog -ApplicationName "FastAPI" -OutputPath $backendOutputLog -ErrorPath $backendErrorLog
    Write-ProcessLog -ApplicationName "Vite" -OutputPath $frontendOutputLog -ErrorPath $frontendErrorLog
}

Remove-Item -LiteralPath @(
    $backendOutputLog,
    $backendErrorLog,
    $frontendOutputLog,
    $frontendErrorLog
) -Force -ErrorAction SilentlyContinue

if ($null -ne $failure) {
    exit 1
}
