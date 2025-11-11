@echo off
cd /d C:\xampp\htdocs\project\backend
echo Starting fresh migration...
echo.
C:\xampp\php\php.exe artisan migrate:fresh --force > migration_output.txt 2>&1
echo Migration command executed. Exit code: %ERRORLEVEL%
echo.
echo Checking output file...
type migration_output.txt
echo.
echo Done.

