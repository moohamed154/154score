@echo off
REM ========================================================
REM 154Score - Production Secure Release Build Script
REM Builds release APK & App Bundle with full code obfuscation
REM and symbol stripping to prevent decompilation & scraping
REM ========================================================

echo ========================================================
echo Building Obfuscated Production Release APK...
echo ========================================================

flutter build apk --release --obfuscate --split-debug-info=./build/debug_symbols --dart-define=ENVIRONMENT=production

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================================
    echo Build SUCCESSFUL!
    echo Output: build\app\outputs\flutter-apk\app-release.apk
    echo Debug symbols saved to: build\debug_symbols
    echo ========================================================
) else (
    echo.
    echo Build FAILED! Please review the compiler output above.
)
