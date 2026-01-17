#!/bin/bash
# 🚀 AuraSphere CRM - Complete Production Setup Script
# This script helps deploy all secrets and Edge Functions to Supabase
# Date: January 16, 2026

set -e  # Exit on error

echo "🚀 AuraSphere CRM - Production Deployment Script"
echo "=================================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ID="lxufgembtogmsvwhdvq"
PROJECT_URL="https://lxufgembtogmsvwhdvq.supabase.co"

echo -e "${BLUE}Project URL: ${PROJECT_URL}${NC}"
echo ""

# Function to print section headers
print_section() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Function to print success
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Function to print error
print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to print info
print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

# Step 1: Check prerequisites
print_section "STEP 1: Checking Prerequisites"

command -v supabase &> /dev/null && print_success "Supabase CLI installed" || { print_error "Supabase CLI not installed. Run: npm install -g supabase"; exit 1; }
command -v flutter &> /dev/null && print_success "Flutter installed" || print_info "Flutter not installed (needed for build step)"
command -v git &> /dev/null && print_success "Git installed" || print_info "Git not installed"

# Step 2: Login to Supabase
print_section "STEP 2: Login to Supabase"

echo "📝 Make sure you're logged into Supabase:"
echo "   supabase login"
echo ""
read -p "Have you logged in? (yes/no): " logged_in

if [ "$logged_in" != "yes" ]; then
    print_error "Please login first: supabase login"
    exit 1
fi

print_success "Supabase login verified"

# Step 3: Collect API Keys
print_section "STEP 3: API Keys Configuration"

echo "Enter your API keys (you can leave blank and add them manually in Supabase Dashboard)"
echo ""

read -p "🔑 Groq API Key (gsk_...): " GROQ_API_KEY
read -p "📧 Resend API Key (re_...): " RESEND_API_KEY
read -p "💳 Stripe Secret Key (sk_test_ or sk_live_): " STRIPE_SECRET_KEY
read -p "💳 Stripe Public Key (pk_test_ or pk_live_): " STRIPE_PUBLIC_KEY
read -p "🛒 Paddle API Key (pdl_...): " PADDLE_API_KEY
read -p "📱 Twilio Account SID (AC...): " TWILIO_ACCOUNT_SID
read -p "📱 Twilio Auth Token: " TWILIO_AUTH_TOKEN
read -p "📸 OCR.space API Key (optional, leave blank): " OCR_API_KEY

echo ""

# Step 4: Set Secrets in Supabase
print_section "STEP 4: Setting Secrets in Supabase"

if [ ! -z "$GROQ_API_KEY" ]; then
    echo "Setting GROQ_API_KEY..."
    supabase secrets set GROQ_API_KEY="$GROQ_API_KEY" --project-id=$PROJECT_ID
    print_success "GROQ_API_KEY set"
fi

if [ ! -z "$RESEND_API_KEY" ]; then
    echo "Setting RESEND_API_KEY..."
    supabase secrets set RESEND_API_KEY="$RESEND_API_KEY" --project-id=$PROJECT_ID
    print_success "RESEND_API_KEY set"
fi

if [ ! -z "$STRIPE_SECRET_KEY" ]; then
    echo "Setting STRIPE_SECRET_KEY..."
    supabase secrets set STRIPE_SECRET_KEY="$STRIPE_SECRET_KEY" --project-id=$PROJECT_ID
    print_success "STRIPE_SECRET_KEY set"
fi

if [ ! -z "$STRIPE_PUBLIC_KEY" ]; then
    echo "Setting STRIPE_PUBLIC_KEY..."
    supabase secrets set STRIPE_PUBLIC_KEY="$STRIPE_PUBLIC_KEY" --project-id=$PROJECT_ID
    print_success "STRIPE_PUBLIC_KEY set"
fi

if [ ! -z "$PADDLE_API_KEY" ]; then
    echo "Setting PADDLE_API_KEY..."
    supabase secrets set PADDLE_API_KEY="$PADDLE_API_KEY" --project-id=$PROJECT_ID
    print_success "PADDLE_API_KEY set"
fi

if [ ! -z "$TWILIO_ACCOUNT_SID" ]; then
    echo "Setting TWILIO_ACCOUNT_SID..."
    supabase secrets set TWILIO_ACCOUNT_SID="$TWILIO_ACCOUNT_SID" --project-id=$PROJECT_ID
    print_success "TWILIO_ACCOUNT_SID set"
fi

if [ ! -z "$TWILIO_AUTH_TOKEN" ]; then
    echo "Setting TWILIO_AUTH_TOKEN..."
    supabase secrets set TWILIO_AUTH_TOKEN="$TWILIO_AUTH_TOKEN" --project-id=$PROJECT_ID
    print_success "TWILIO_AUTH_TOKEN set"
fi

if [ ! -z "$OCR_API_KEY" ]; then
    echo "Setting OCR_API_KEY..."
    supabase secrets set OCR_API_KEY="$OCR_API_KEY" --project-id=$PROJECT_ID
    print_success "OCR_API_KEY set"
fi

# Step 5: Deploy Edge Functions
print_section "STEP 5: Deploying Edge Functions"

echo "Deploying all Edge Functions to Supabase..."
echo ""

supabase functions deploy --project-id=$PROJECT_ID

print_success "All Edge Functions deployed"

# Step 6: Verify Secrets
print_section "STEP 6: Verifying Secrets Configuration"

echo "Running verification function..."
echo ""

supabase functions invoke verify-secrets --project-id=$PROJECT_ID

# Step 7: Build Flutter Web
print_section "STEP 7: Building Flutter Web"

read -p "Build Flutter web app now? (yes/no): " build_flutter

if [ "$build_flutter" == "yes" ]; then
    echo "Cleaning previous builds..."
    flutter clean
    
    echo "Building Flutter web (release mode)..."
    flutter build web --release
    
    print_success "Flutter web built successfully"
    print_info "Build output: build/web/"
else
    print_info "Skipping Flutter build"
fi

# Step 8: Run SQL Migrations
print_section "STEP 8: Database Migrations"

echo "SQL migrations are documented in: SUPABASE_DEPLOYMENT_SCRIPT.sql"
echo ""
echo "Steps:"
echo "1. Go to Supabase Dashboard"
echo "2. Navigate to SQL Editor"
echo "3. Run migrations in order:"
echo "   - database_schema_setup.sql"
echo "   - 20260105_create_african_prepayment_codes.sql"
echo "   - 20260110_add_digital_signatures.sql"
echo "   - 20260111_add_owner_feature_control.sql"
echo "   - 20260114_add_cloudguard_finops.sql"
echo ""
read -p "Have you run all migrations? (yes/no): " migrations_done

if [ "$migrations_done" != "yes" ]; then
    print_error "Please run SQL migrations first"
    exit 1
fi

print_success "All migrations completed"

# Step 9: Configure Authentication
print_section "STEP 9: Configure Authentication"

echo "Manual steps in Supabase Dashboard:"
echo "1. Go to Authentication → Providers"
echo "2. Enable 'Email' provider"
echo "3. Uncheck 'Auto confirm' (require email verification)"
echo "4. Go to Email Templates"
echo "5. Update 'Confirm signup' template"
echo ""
read -p "Have you configured authentication? (yes/no): " auth_configured

if [ "$auth_configured" != "yes" ]; then
    print_error "Please configure authentication in Supabase Dashboard"
fi

# Step 10: Summary
print_section "DEPLOYMENT COMPLETE! 🎉"

echo "What was done:"
echo "  ✅ API secrets configured in Supabase"
echo "  ✅ Edge Functions deployed"
echo "  ✅ Verification function run"
if [ "$build_flutter" == "yes" ]; then
    echo "  ✅ Flutter web built"
fi
if [ "$migrations_done" == "yes" ]; then
    echo "  ✅ Database migrations completed"
fi
if [ "$auth_configured" == "yes" ]; then
    echo "  ✅ Authentication configured"
fi
echo ""

echo "Next steps:"
echo "1. Deploy static assets (build/web/) to your hosting"
echo "2. Test signup flow"
echo "3. Test payment integration"
echo "4. Monitor Supabase logs"
echo ""

echo -e "${GREEN}🚀 Ready for production launch!${NC}"
echo ""
