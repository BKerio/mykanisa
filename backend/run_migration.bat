@echo off
cd /d C:\xampp\htdocs\project\backend
echo Running fresh migration...
C:\xampp\php\php.exe artisan migrate:fresh --force
echo Migration completed. Exit code: %ERRORLEVEL%
pause

