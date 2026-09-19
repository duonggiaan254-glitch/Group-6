@echo off
setlocal
where xelatex >nul 2>&1
if errorlevel 1 (
  echo [ERROR] XeLaTeX was not found in PATH.
  echo Please install MiKTeX or TeX Live, then reopen the terminal/editor.
  pause
  exit /b 1
)

echo [1/2] Compiling with XeLaTeX...
xelatex -interaction=nonstopmode -halt-on-error -file-line-error main.tex
if errorlevel 1 (
  echo [ERROR] First XeLaTeX pass failed.
  pause
  exit /b 1
)

echo [2/2] Compiling again for table of contents and references...
xelatex -interaction=nonstopmode -halt-on-error -file-line-error main.tex
if errorlevel 1 (
  echo [ERROR] Second XeLaTeX pass failed.
  pause
  exit /b 1
)

echo.
echo [OK] Build completed successfully: main.pdf
pause
