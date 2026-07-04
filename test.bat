@echo off
start "Test" cmd /c cd /d "%~dp0frontend" ^&^& echo hi from inner ^> "%~dp0frontend\test_output.txt"
