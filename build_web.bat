@echo off
REM Windows build script for Flutter web with Netlify SPA routing

echo 🔨 Building Flutter web release...
flutter build web --release

if %ERRORLEVEL% NEQ 0 (
    echo ❌ Build failed
    exit /b 1
)

echo ✅ Build complete. Copying _redirects to build/web...
copy "_redirects" "build\web\_redirects" /Y

if %ERRORLEVEL% NEQ 0 (
    echo ❌ Copy failed
    exit /b 1
)

echo ✅ _redirects file copied successfully
echo 📦 Ready for deployment!
