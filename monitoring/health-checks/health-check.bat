@echo off
setlocal enabledelayedexpansion

REM MCP Gateway Health Check Script
REM This script checks the health of all MCP Gateway services

echo === MCP Gateway Health Check ===
echo Health check started at: %date% %time%
echo.

REM Configuration
set GATEWAY_URL=http://localhost:4444
set TIMEOUT=10
set FAILED_CHECKS=0

REM Colors for output
set RED=[91m
set GREEN=[92m
set YELLOW=[93m
set RESET=[0m

echo Checking MCP Gateway services...
echo.

REM Check if Docker is running
echo [1/6] Checking Docker daemon...
docker info >nul 2>&1
if %errorlevel% equ 0 (
    echo %GREEN%✓ Docker daemon is running%RESET%
) else (
    echo %RED%✗ Docker daemon is not running%RESET%
    set /a FAILED_CHECKS+=1
    goto :end
)

REM Check if containers are running
echo.
echo [2/6] Checking container status...
docker-compose ps >nul 2>&1
if %errorlevel% equ 0 (
    echo %GREEN%✓ Docker Compose is available%RESET%
    
    REM Check each service
    for /f "skip=1 tokens=1,2,3" %%a in ('docker-compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"') do (
        set service_name=%%a
        set service_status=%%b
        set service_ports=%%c
        
        if "!service_status!"=="Up" (
            echo %GREEN%✓ !service_name! is running%RESET%
        ) else (
            echo %RED%✗ !service_name! is not running (Status: !service_status!)%RESET%
            set /a FAILED_CHECKS+=1
        )
    )
) else (
    echo %RED%✗ Docker Compose is not available%RESET%
    set /a FAILED_CHECKS+=1
)

REM Check MCP Gateway health endpoint
echo.
echo [3/6] Checking MCP Gateway health endpoint...
powershell -Command "try { $response = Invoke-WebRequest -Uri '%GATEWAY_URL%/health' -TimeoutSec %TIMEOUT% -UseBasicParsing; if ($response.StatusCode -eq 200) { Write-Host '%GREEN%✓ MCP Gateway health endpoint is responding%RESET%' } else { Write-Host '%RED%✗ MCP Gateway health endpoint returned status:' $response.StatusCode%RESET%'; exit 1 } } catch { Write-Host '%RED%✗ MCP Gateway health endpoint is not responding%RESET%'; exit 1 }"
if %errorlevel% neq 0 set /a FAILED_CHECKS+=1

REM Check network connectivity
echo.
echo [4/6] Checking network connectivity...
ping -n 1 127.0.0.1 >nul 2>&1
if %errorlevel% equ 0 (
    echo %GREEN%✓ Local network connectivity is working%RESET%
) else (
    echo %RED%✗ Local network connectivity is failing%RESET%
    set /a FAILED_CHECKS+=1
)

REM Check disk space
echo.
echo [5/6] Checking disk space...
for /f "tokens=3" %%a in ('dir C:\ ^| find "bytes free"') do set free_space=%%a
set free_space=%free_space:,=%
set /a free_space_gb=%free_space%/1073741824
if %free_space_gb% gtr 1 (
    echo %GREEN%✓ Sufficient disk space available (%free_space_gb% GB free)%RESET%
) else (
    echo %YELLOW%⚠ Low disk space warning (%free_space_gb% GB free)%RESET%
)

REM Check memory usage
echo.
echo [6/6] Checking system resources...
for /f "skip=1" %%a in ('wmic OS get TotalVisibleMemorySize,FreePhysicalMemory /format:list ^| find "="') do (
    echo %%a >> temp_mem.txt
)
for /f "tokens=2 delims==" %%a in ('findstr "TotalVisibleMemorySize" temp_mem.txt') do set total_mem=%%a
for /f "tokens=2 delims==" %%a in ('findstr "FreePhysicalMemory" temp_mem.txt') do set free_mem=%%a
del temp_mem.txt 2>nul

set /a total_mem_gb=%total_mem%/1048576
set /a used_mem_gb=(%total_mem%-%free_mem%)/1048576
set /a mem_usage=100-(%free_mem%*100/%total_mem%)

echo Memory: %used_mem_gb% GB used / %total_mem_gb% GB total (%mem_usage%%%)
if %mem_usage% lss 80 (
    echo %GREEN%✓ Memory usage is acceptable%RESET%
) else (
    echo %YELLOW%⚠ High memory usage warning%RESET%
)

:end
echo.
echo === Health Check Summary ===
if %FAILED_CHECKS% equ 0 (
    echo %GREEN%✓ All health checks passed%RESET%
    echo System is healthy and ready for use.
    exit /b 0
) else (
    echo %RED%✗ %FAILED_CHECKS% health check(s) failed%RESET%
    echo Please review the issues above and take corrective action.
    exit /b 1
)