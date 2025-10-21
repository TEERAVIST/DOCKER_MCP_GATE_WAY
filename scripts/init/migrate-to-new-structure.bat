@echo off
setlocal enabledelayedexpansion

REM MCP Gateway Migration Script
REM This script helps migrate from the old monolithic structure to the new modular structure

echo === MCP Gateway Migration Script ===
echo This script will migrate your setup to the new modular structure
echo.
echo IMPORTANT: This will:
echo   1. Backup your current setup
echo   2. Create the new directory structure
echo   3. Migrate configuration files
echo   4. Preserve existing data
echo.
echo Press Ctrl+C to cancel or any key to continue...
pause >nul

echo Migration started at: %date% %time%
echo.

REM Configuration
set BACKUP_DIR=migration_backup_%date:~-4%%date:~4,2%%date:~7,2%_%time:~0,2%%time:~3,2%%time:~6,2%
set BACKUP_DIR=%BACKUP_DIR: =0%

REM Step 1: Create backup
echo [1/5] Creating backup of current setup...
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

REM Backup current files
if exist "docker-compose.yml" copy "docker-compose.yml" "%BACKUP_DIR%\" >nul
if exist ".env" copy ".env" "%BACKUP_DIR%\" >nul
if exist ".env.example" copy ".env.example" "%BACKUP_DIR%\" >nul

REM Backup data directories
if exist "data" xcopy "data" "%BACKUP_DIR%\data\" /E /I /H /Q >nul
if exist "kaggle-data" xcopy "kaggle-data" "%BACKUP_DIR%\kaggle-data\" /E /I /H /Q >nul
if exist "playwright-data" xcopy "playwright-data" "%BACKUP_DIR%\playwright-data\" /E /I /H /Q >nul

echo ✓ Backup created in: %BACKUP_DIR%

REM Step 2: Stop existing services
echo.
echo [2/5] Stopping existing services...
docker-compose down 2>nul
echo ✓ Existing services stopped

REM Step 3: Create new directory structure
echo.
echo [3/5] Creating new directory structure...
if not exist "compose" mkdir "compose"
if not exist "config" mkdir "config"
if not exist "scripts" mkdir "scripts"
if not exist "scripts\init" mkdir "scripts\init"
if not exist "scripts\backup" mkdir "scripts\backup"
if not exist "scripts\maintenance" mkdir "scripts\maintenance"
if not exist "logs" mkdir "logs"
if not exist "monitoring" mkdir "monitoring"
if not exist "monitoring\health-checks" mkdir "monitoring\health-checks"
if not exist "monitoring\metrics" mkdir "monitoring\metrics"
echo ✓ Directory structure created

REM Step 4: Migrate configuration
echo.
echo [4/5] Migrating configuration files...

REM Create new .env from existing one if it exists
if exist ".env" (
    echo ✓ Existing .env file found
    echo   Your existing .env will be preserved
    echo   Consider updating it with the new variables from .env.production
    
    REM Show what new variables are available
    echo.
    echo New environment variables available in .env.production:
    findstr "=" ".env.production" | findstr /V "^#" | findstr /V "^$"
) else (
    echo ✓ No existing .env file found
    echo   Creating .env from .env.production template
    copy ".env.production" ".env" >nul
    echo   IMPORTANT: Edit .env with your specific configuration
)

REM Step 5: Update docker-compose.yml
echo.
echo [5/5] Setting up new Docker Compose configuration...

REM Check if new compose file exists
if exist "docker-compose.new.yml" (
    echo ✓ New modular compose file found
    echo   Renaming docker-compose.new.yml to docker-compose.yml
    if exist "docker-compose.yml" move "docker-compose.yml" "docker-compose.old.yml" >nul
    move "docker-compose.new.yml" "docker-compose.yml" >nul
    echo   Old compose file saved as docker-compose.old.yml
) else (
    echo ⚠ New compose file not found
    echo   Please ensure docker-compose.new.yml exists
)

REM Create data directories if they don't exist
if not exist "data" mkdir "data"
if not exist "data\mcp" mkdir "data\mcp"
if not exist "data\kaggle" mkdir "data\kaggle"
if not exist "data\playwright" mkdir "data\playwright"

echo.
echo === Migration Summary ===
echo ✓ Current setup backed up to: %BACKUP_DIR%
echo ✓ New directory structure created
echo ✓ Configuration files migrated
echo ✓ New Docker Compose configuration ready

echo.
echo === Next Steps ===
echo 1. Review and update your .env file with the new variables
echo 2. Test the new structure with:
echo    docker-compose --profile core up -d
echo 3. Start additional profiles as needed:
echo    docker-compose --profile data up -d
echo    docker-compose --profile ai up -d
echo    docker-compose --profile browser up -d
echo 4. Verify all services are working correctly
echo 5. Run health check: monitoring\health-checks\health-check.bat

echo.
echo === Profile Usage Examples ===
echo Start all services:          docker-compose --profile all up -d
echo Start core only:             docker-compose --profile core up -d
echo Start data services:         docker-compose --profile data up -d
echo Start AI services:           docker-compose --profile ai up -d
echo Start browser services:      docker-compose --profile browser up -d
echo Start minimal setup:         docker-compose --profile minimal up -d

echo.
echo === Rollback Instructions ===
echo If you need to rollback to the old structure:
echo 1. Stop all services: docker-compose down
echo 2. Restore from backup: copy %BACKUP_DIR%\*.* .
echo 3. Start old services: docker-compose up -d

echo.
echo Migration completed successfully!
echo Your MCP Gateway is now ready with the new modular structure.
echo.
pause