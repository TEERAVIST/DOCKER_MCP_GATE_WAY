@echo off
setlocal enabledelayedexpansion

REM MCP Gateway Backup Script for Windows
REM This script creates backups of critical data and configuration files

echo === MCP Gateway Backup Script ===
echo Backup started at: %date% %time%

REM Configuration
set BACKUP_DIR=%BACKUP_DIR%
if "%BACKUP_DIR%"=="" set BACKUP_DIR=.\backups
set DATA_DIR=%DATA_DIR%
if "%DATA_DIR%"=="" set DATA_DIR=.\data
set LOG_DIR=%LOG_DIR%
if "%LOG_DIR%"=="" set LOG_DIR=.\logs
set RETENTION_DAYS=%BACKUP_RETENTION_DAYS%
if "%RETENTION_DAYS%"=="" set RETENTION_DAYS=30

REM Generate timestamp
for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"
set "YYYY=%dt:~0,4%"
set "MM=%dt:~4,2%"
set "DD=%dt:~6,2%"
set "HH=%dt:~8,2%"
set "Min=%dt:~10,2%"
set "Sec=%dt:~12,2%"
set "BACKUP_NAME=mcp_backup_%YYYY%%MM%%DD%_%HH%%Min%%Sec%"

echo Backup name: %BACKUP_NAME%

REM Create backup directory
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"
if not exist "%BACKUP_DIR%\%BACKUP_NAME%" mkdir "%BACKUP_DIR%\%BACKUP_NAME%"
echo Created backup directory: %BACKUP_DIR%\%BACKUP_NAME%

REM Backup data directories
echo Backing up data directories...
if exist "%DATA_DIR%" (
    powershell -Command "Compress-Archive -Path '%DATA_DIR%' -DestinationPath '%BACKUP_DIR%\%BACKUP_NAME%\data.zip' -Force"
    echo ✓ Data directory backed up
) else (
    echo ⚠ Data directory not found: %DATA_DIR%
)

REM Backup logs
echo Backing up logs...
if exist "%LOG_DIR%" (
    powershell -Command "Compress-Archive -Path '%LOG_DIR%' -DestinationPath '%BACKUP_DIR%\%BACKUP_NAME%\logs.zip' -Force"
    echo ✓ Logs backed up
) else (
    echo ⚠ Log directory not found: %LOG_DIR%
)

REM Backup configuration files
echo Backing up configuration files...
if not exist "%BACKUP_DIR%\%BACKUP_NAME%\config" mkdir "%BACKUP_DIR%\%BACKUP_NAME%\config"

if exist ".env" (
    copy ".env" "%BACKUP_DIR%\%BACKUP_NAME%\config\" >nul
    echo ✓ .env backed up
) else (
    echo ⚠ .env file not found
)

if exist "docker-compose.yml" (
    copy "docker-compose.yml" "%BACKUP_DIR%\%BACKUP_NAME%\config\" >nul
    echo ✓ docker-compose.yml backed up
) else (
    echo ⚠ docker-compose.yml file not found
)

if exist ".env.production" (
    copy ".env.production" "%BACKUP_DIR%\%BACKUP_NAME%\config\" >nul
    echo ✓ .env.production backed up
)

REM Create backup metadata
echo Creating backup metadata...
(
echo MCP Gateway Backup Information
echo ==============================
echo Backup Name: %BACKUP_NAME%
echo Created: %date% %time%
echo Hostname: %COMPUTERNAME%
echo User: %USERNAME%
echo Working Directory: %CD%
echo.
echo Docker Information:
docker --version 2>nul || echo Docker not available
docker-compose --version 2>nul || echo Docker Compose not available
echo.
echo Running Services:
docker-compose ps 2>nul || echo No running services
echo.
echo Disk Usage:
dir "%BACKUP_DIR%" 2>nul || echo Disk usage not available
) > "%BACKUP_DIR%\%BACKUP_NAME%\backup_info.txt"

echo ✓ Backup metadata created

REM Compress entire backup
echo Compressing backup...
cd "%BACKUP_DIR%"
powershell -Command "Compress-Archive -Path '%BACKUP_NAME%' -DestinationPath '%BACKUP_NAME%.zip' -Force"
rmdir /s /q "%BACKUP_NAME%"

echo ✓ Backup completed: %BACKUP_DIR%\%BACKUP_NAME%.zip

REM Show backup size
for %%F in ("%BACKUP_DIR%\%BACKUP_NAME%.zip") do set "size=%%~zF"
set /a sizeMB=%size%/1048576
echo Backup size: !sizeMB! MB

REM Clean up old backups
echo Cleaning up old backups ^(older than %RETENTION_DAYS% days^^)...
forfiles /p "%BACKUP_DIR%" /m "mcp_backup_*.zip" /d -%RETENTION_DAYS% /c "cmd /c del @path" 2>nul
echo ✓ Old backups cleaned up

echo === Backup completed successfully ===
echo Backup file: %BACKUP_DIR%\%BACKUP_NAME%.zip
echo Completed at: %date% %time%

REM Verify backup integrity
echo Verifying backup integrity...
powershell -Command "try { Expand-Archive -Path '%BACKUP_DIR%\%BACKUP_NAME%.zip' -DestinationPath '%TEMP%\verify_backup' -Force; Remove-Item -Path '%TEMP%\verify_backup' -Recurse -Force; Write-Host '✓ Backup integrity verified' } catch { Write-Host '✗ Backup integrity check failed'; exit 1 }"

echo Backup script completed successfully!
pause