#!/usr/bin/env pwsh
# GitHub Push Script for AuraSphere CRM
# This script commits all changes and pushes to GitHub

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "🚀 AuraSphere CRM - GitHub Push Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if git is initialized
if (-not (Test-Path .git)) {
    Write-Host "❌ Git not initialized. Running: git init" -ForegroundColor Red
    git init
}

# Show current status
Write-Host "📋 Current Git Status:" -ForegroundColor Yellow
git status --short
Write-Host ""

# Check if .env is in .gitignore
Write-Host "🔐 Checking .gitignore..." -ForegroundColor Yellow
if (Select-String -Path .gitignore -Pattern "\.env" -Quiet) {
    Write-Host "✅ .env is properly ignored" -ForegroundColor Green
} else {
    Write-Host "⚠️  WARNING: .env not in .gitignore!" -ForegroundColor Red
}
Write-Host ""

# Add all files
Write-Host "📦 Adding all files..." -ForegroundColor Yellow
git add .
Write-Host "✅ Files added" -ForegroundColor Green
Write-Host ""

# Commit
$commitMessage = "Fix: Update to correct Supabase project ID (lxufgzembtogmsvwhdvq with 'z')"
Write-Host "📝 Committing with message:" -ForegroundColor Yellow
Write-Host "   '$commitMessage'" -ForegroundColor Cyan
git commit -m $commitMessage
Write-Host "✅ Committed" -ForegroundColor Green
Write-Host ""

# Push
Write-Host "🚀 Pushing to GitHub..." -ForegroundColor Yellow
git push origin main

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ Push Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📍 GitHub Repository:" -ForegroundColor Yellow
Write-Host "   https://github.com/bensmr/aura-sphere" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Go to Netlify: https://app.netlify.com/teams/bensmr/projects" -ForegroundColor Cyan
Write-Host "2. Delete old deployment (if exists)" -ForegroundColor Cyan
Write-Host "3. Create new site from GitHub repo" -ForegroundColor Cyan
Write-Host "4. Set environment variables:" -ForegroundColor Cyan
Write-Host "   SUPABASE_URL = https://lxufgzembtogmsvwhdvq.supabase.co" -ForegroundColor Green
Write-Host "   SUPABASE_ANON_KEY = eyJhbGciOiJIUzI1NiIsInR5cCI6..." -ForegroundColor Green
Write-Host ""
Write-Host "🎉 Deployment Ready!" -ForegroundColor Green
