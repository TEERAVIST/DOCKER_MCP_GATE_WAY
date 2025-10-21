@echo off
setlocal enabledelayedexpansion

REM MCP Gateway Kubernetes Deployment Script for Windows
REM This script deploys the MCP Gateway to Kubernetes with proper liveness and readiness probes

title MCP Gateway Kubernetes Deployment

REM Configuration
set NAMESPACE=mcp-gateway
set KUBECTL=kubectl

REM Colors for output (Windows doesn't support ANSI colors by default)
set INFO=[INFO]
set SUCCESS=[SUCCESS]
set WARNING=[WARNING]
set ERROR=[ERROR]

REM Function to check if kubectl is available
:kubectl_check
echo %INFO% Checking if kubectl is available...
kubectl version --client >nul 2>&1
if %errorlevel% neq 0 (
    echo %ERROR% kubectl is not installed or not in PATH
    pause
    exit /b 1
)

kubectl cluster-info >nul 2>&1
if %errorlevel% neq 0 (
    echo %ERROR% Cannot connect to Kubernetes cluster
    pause
    exit /b 1
)

echo %SUCCESS% kubectl is available and connected to cluster
goto :eof

REM Function to create namespace
:create_namespace
echo %INFO% Creating namespace: %NAMESPACE%
kubectl get namespace %NAMESPACE% >nul 2>&1
if %errorlevel% equ 0 (
    echo %WARNING% Namespace %NAMESPACE% already exists
) else (
    kubectl apply -f ../namespaces/mcp-gateway.yaml
    echo %SUCCESS% Namespace %NAMESPACE% created
)
goto :eof

REM Function to create secrets
:create_secrets
echo %INFO% Creating secrets...
kubectl apply -f ../secrets/mcp-gateway-secrets.yaml
echo %SUCCESS% Secrets created
goto :eof

REM Function to create configmaps
:create_configmaps
echo %INFO% Creating configmaps...
kubectl apply -f ../configmaps/mcp-gateway-config.yaml
echo %SUCCESS% Configmaps created
goto :eof

REM Function to create persistent volumes
:create_persistent_volumes
echo %INFO% Creating persistent volumes...
kubectl apply -f ../persistent-volumes/postgres-pv.yaml
echo %SUCCESS% Persistent volumes created
goto :eof

REM Function to deploy services
:deploy_services
echo %INFO% Deploying services...
kubectl apply -f ../services/mcp-gateway-services.yaml
echo %SUCCESS% Services deployed
goto :eof

REM Function to deploy database
:deploy_database
echo %INFO% Deploying PostgreSQL database...
kubectl apply -f ../deployments/postgres.yaml

echo %INFO% Waiting for PostgreSQL to be ready...
kubectl wait --for=condition=ready pod -l app=postgres -n %NAMESPACE% --timeout=300s
echo %SUCCESS% PostgreSQL is ready
goto :eof

REM Function to deploy core services
:deploy_core_services
echo %INFO% Deploying MCP Gateway...
kubectl apply -f ../deployments/mcp-gateway.yaml

echo %INFO% Waiting for MCP Gateway to be ready...
kubectl wait --for=condition=ready pod -l app=mcp-gateway -n %NAMESPACE% --timeout=300s
echo %SUCCESS% MCP Gateway is ready
goto :eof

REM Function to deploy bridge services
:deploy_bridge_services
echo %INFO% Deploying AI bridge services...
kubectl apply -f ../deployments/ai-bridges.yaml

echo %INFO% Deploying data bridge services...
kubectl apply -f ../deployments/data-bridges.yaml

echo %INFO% Deploying Playwright bridge service...
kubectl apply -f ../deployments/playwright.yaml

echo %INFO% Waiting for bridge services to be ready...
start /b kubectl wait --for=condition=ready pod -l app=context7-bridge -n %NAMESPACE% --timeout=300s
start /b kubectl wait --for=condition=ready pod -l app=gistpad-bridge -n %NAMESPACE% --timeout=300s
start /b kubectl wait --for=condition=ready pod -l app=kaggle-bridge -n %NAMESPACE% --timeout=300s
start /b kubectl wait --for=condition=ready pod -l app=mssql-bridge -n %NAMESPACE% --timeout=300s
start /b kubectl wait --for=condition=ready pod -l app=playwright-bridge -n %NAMESPACE% --timeout=600s

REM Wait for all background processes to complete
timeout /t 1 /nobreak >nul
:wait_for_pods
tasklist | findstr "kubectl.exe" >nul
if %errorlevel% equ 0 (
    timeout /t 5 /nobreak >nul
    goto wait_for_pods
)

echo %SUCCESS% All bridge services are ready
goto :eof

REM Function to show deployment status
:show_deployment_status
echo %INFO% Deployment status:
echo.
kubectl get pods -n %NAMESPACE%
echo.
kubectl get services -n %NAMESPACE%
echo.

REM Get MCP Gateway URL
for /f "tokens=*" %%i in ('kubectl get service mcp-gateway -n %NAMESPACE% -o jsonpath^="{.status.loadBalancer.ingress[0].ip}" 2^>nul') do set GATEWAY_URL=%%i
if "!GATEWAY_URL!"=="" set GATEWAY_URL=localhost

for /f "tokens=*" %%i in ('kubectl get service mcp-gateway -n %NAMESPACE% -o jsonpath^="{.spec.ports[0].port}"') do set GATEWAY_PORT=%%i

echo %SUCCESS% MCP Gateway is available at: http://!GATEWAY_URL!:!GATEWAY_PORT!
echo %INFO% Username: admin
echo %INFO% Password: changeme
goto :eof

REM Function to show logs
:show_logs
echo %INFO% Showing logs for all services (press Ctrl+C to exit):
kubectl logs -f -n %NAMESPACE% --all-containers=true
goto :eof

REM Main deployment function
:deploy_all
echo %INFO% Starting MCP Gateway Kubernetes deployment...
echo.

call :kubectl_check
call :create_namespace
call :create_secrets
call :create_configmaps
call :create_persistent_volumes
call :deploy_services
call :deploy_database
call :deploy_core_services
call :deploy_bridge_services

echo.
echo %SUCCESS% MCP Gateway deployment completed successfully!
echo.

call :show_deployment_status
goto :eof

REM Function to cleanup deployment
:cleanup
echo %WARNING% Cleaning up MCP Gateway deployment...
kubectl delete namespace %NAMESPACE% --ignore-not-found=true
echo %SUCCESS% Cleanup completed
goto :eof

REM Function to scale services
:scale_service
if "%~2"=="" (
    echo %ERROR% Usage: %0 scale ^<service^> ^<replicas^>
    pause
    exit /b 1
)
if "%~3"=="" (
    echo %ERROR% Usage: %0 scale ^<service^> ^<replicas^>
    pause
    exit /b 1
)

set SERVICE=%~2
set REPLICAS=%~3

echo %INFO% Scaling %SERVICE% to %REPLICAS% replicas
kubectl scale deployment %SERVICE% --replicas=%REPLICAS% -n %NAMESPACE%
kubectl wait --for=condition=available deployment/%SERVICE% -n %NAMESPACE% --timeout=300s
echo %SUCCESS% %SERVICE% scaled to %REPLICAS% replicas
goto :eof

REM Main script logic
if "%~1"=="" set COMMAND=deploy
if "%~1"=="deploy" set COMMAND=deploy
if "%~1"=="cleanup" set COMMAND=cleanup
if "%~1"=="status" set COMMAND=status
if "%~1"=="logs" set COMMAND=logs
if "%~1"=="scale" set COMMAND=scale
if "%~1"=="help" set COMMAND=help
if "%~1"=="-h" set COMMAND=help
if "%~1"=="--help" set COMMAND=help

if "%COMMAND%"=="deploy" (
    call :deploy_all
) else if "%COMMAND%"=="cleanup" (
    call :cleanup
) else if "%COMMAND%"=="status" (
    call :show_deployment_status
) else if "%COMMAND%"=="logs" (
    call :show_logs
) else if "%COMMAND%"=="scale" (
    call :scale_service %*
) else if "%COMMAND%"=="help" (
    echo MCP Gateway Kubernetes Deployment Script
    echo.
    echo Usage: %0 [COMMAND] [OPTIONS]
    echo.
    echo Commands:
    echo   deploy              Deploy MCP Gateway to Kubernetes ^(default^)
    echo   cleanup             Remove MCP Gateway from Kubernetes
    echo   status              Show deployment status
    echo   logs                Show logs for all services
    echo   scale ^<svc^> ^<rep^>   Scale a service to specified replicas
    echo   help                Show this help message
    echo.
    echo Examples:
    echo   %0 deploy           # Deploy all services
    echo   %0 scale mcp-gateway 3  # Scale MCP Gateway to 3 replicas
    echo   %0 status            # Show deployment status
    echo   %0 logs              # Show logs
    echo   %0 cleanup           # Remove all services
) else (
    echo %ERROR% Unknown command: %~1
    echo Use '%0 help' for usage information
    pause
    exit /b 1
)

pause