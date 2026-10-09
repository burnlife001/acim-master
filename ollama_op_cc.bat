@echo off
setlocal EnableExtensions




set "start_ornith=ollama launch claude --model rafw007/ornith-claude-coder"
set "start_qwen35=ollama launch claude --model rafw007/qwen35-claude-coder:4b"
set "rm_ornith=ollama rm rafw007/ornith-claude-coder"
set "rm_qwen35=ollama rm rafw007/qwen35-claude-coder:4b"

:menu
echo 1. start:%start_ornith%
echo 2. start:%start_qwen35%
echo;
echo 3. rm:%rm_ornith%
echo 4. rm:%rm_qwen35%
echo;
echo 0. exit
echo "-------------------------------------------------------------"
set /p choice="Enter your choice:
if %choice%==1 (
    echo %start_ornith%
    %start_ornith%
    pause
    goto  menu
) else if %choice%==2 (
    echo %start_qwen35%
    %start_qwen35%
    pause
    goto  menu
) else if %choice%==3 (
    echo %rm_ornith%
    %rm_ornith%
    pause
    goto  menu
) else if %choice%==4 (
    echo %rm_qwen35%
    %rm_qwen35%
    pause
    goto  menu
) else if %choice%==0 (
    exit
)
