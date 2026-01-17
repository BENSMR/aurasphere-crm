#!/bin/bash
# 🎯 VISUAL DEPLOYMENT CHECKLIST
# AuraSphere CRM - Production Launch
# Date: January 16, 2026

# This is a quick-reference checklist you can print or keep in your terminal
# Run this to track progress: bash DEPLOYMENT_CHECKLIST.sh

clear

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                                                                ║"
echo "║        🚀 AURASPHERE CRM DEPLOYMENT CHECKLIST 🚀             ║"
echo "║                                                                ║"
echo "║              Production Launch - January 16, 2026             ║"
echo "║                                                                ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# PHASE 1
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PHASE 1: GET API KEYS (15 minutes)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Documentation: API_KEYS_SETUP_GUIDE.md"
echo "Quick Reference: QUICK_API_KEYS_CHECKLIST.md"
echo ""

# Array of services
services=("Groq (AI)" "Resend (Email)" "Stripe (Payment)" "Paddle (Alt Payment)" "Twilio (WhatsApp)" "OCR Space (Optional)")
urls=("https://console.groq.com" "https://resend.com" "https://dashboard.stripe.com" "https://www.paddle.com" "https://www.twilio.com" "https://ocr.space")
key_names=("GROQ_API_KEY" "RESEND_API_KEY" "STRIPE_SECRET_KEY / STRIPE_PUBLIC_KEY" "PADDLE_API_KEY" "TWILIO_ACCOUNT_SID / TWILIO_AUTH_TOKEN" "OCR_API_KEY")
prefixes=("gsk_" "re_" "sk_test_ / pk_test_" "pdl_" "AC... / token" "varies")

for i in "${!services[@]}"; do
    echo "☐ ${services[$i]}"
    echo "  URL: ${urls[$i]}"
    echo "  Key: ${key_names[$i]}"
    echo "  Prefix: ${prefixes[$i]}"
    echo ""
done

echo "✅ ACTION: Complete QUICK_API_KEYS_CHECKLIST.md Phase 1 section"
echo ""
echo "Press Enter to continue..."
read

# PHASE 2
clear
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PHASE 2: SUPABASE SECRETS (5 minutes)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Documentation: COMPLETE_DEPLOYMENT_GUIDE.md Phase 2"
echo ""
echo "Steps:"
echo "1. Go to: https://app.supabase.com/"
echo "2. Select project: lxufgembtogmsvwhdvq"
echo "3. Settings → Secrets"
echo "4. Add each secret:"
echo ""

secrets=("GROQ_API_KEY" "RESEND_API_KEY" "STRIPE_SECRET_KEY" "STRIPE_PUBLIC_KEY" "PADDLE_API_KEY" "TWILIO_ACCOUNT_SID" "TWILIO_AUTH_TOKEN" "OCR_API_KEY")

for secret in "${secrets[@]}"; do
    echo "   ☐ $secret"
done

echo ""
echo "5. Click 'Deploy'"
echo ""
echo "✅ ACTION: Add all secrets to Supabase and click Deploy"
echo ""
echo "Press Enter to continue..."
read

# PHASE 3
clear
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PHASE 3: DEPLOY EDGE FUNCTIONS (3 minutes)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Documentation: COMPLETE_DEPLOYMENT_GUIDE.md Phase 3"
echo ""
echo "Terminal commands:"
echo ""
echo "  $ cd c:\\Users\\PC\\AuraSphere\\crm\\aura_crm"
echo "  $ supabase functions deploy"
echo "  $ supabase functions invoke verify-secrets"
echo ""
echo "Expected output:"
echo "  ✅ GROQ_API_KEY: CONFIGURED"
echo "  ✅ RESEND_API_KEY: CONFIGURED"
echo "  ✅ STRIPE_SECRET_KEY: CONFIGURED"
echo "  ✅ STRIPE_PUBLIC_KEY: CONFIGURED"
echo "  ✅ PADDLE_API_KEY: CONFIGURED"
echo "  ✅ TWILIO_ACCOUNT_SID: CONFIGURED"
echo "  ✅ TWILIO_AUTH_TOKEN: CONFIGURED"
echo "  ✅ ALL SECRETS CONFIGURED"
echo ""
echo "☐ Edge Functions deployed"
echo "☐ verify-secrets shows all ✅"
echo ""
echo "Press Enter to continue..."
read

# PHASE 4
clear
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PHASE 4: DATABASE SETUP (5 minutes)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Documentation: SUPABASE_DEPLOYMENT_SCRIPT.sql"
echo ""
echo "Steps:"
echo "1. Go to: https://app.supabase.com/"
echo "2. SQL Editor"
echo "3. Run these migrations in order:"
echo ""

migrations=("database_schema_setup.sql" "20260105_create_african_prepayment_codes.sql" "20260110_add_digital_signatures.sql" "20260111_add_owner_feature_control.sql" "20260114_add_cloudguard_finops.sql")

for i in "${!migrations[@]}"; do
    echo "   $(($i+1)). ☐ ${migrations[$i]}"
done

echo ""
echo "4. Wait for each to complete with ✅ 'Success'"
echo ""
echo "✅ ACTION: Run all 5 SQL migrations in order"
echo ""
echo "Press Enter to continue..."
read

# PHASE 5
clear
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PHASE 5: AUTHENTICATION (5 minutes)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Documentation: COMPLETE_DEPLOYMENT_GUIDE.md Phase 5"
echo ""
echo "Steps:"
echo "1. Supabase Dashboard"
echo "2. Authentication → Providers"
echo ""
echo "   ☐ Enable 'Email' provider"
echo "   ☐ Uncheck 'Auto Confirm'"
echo ""
echo "3. Email Templates"
echo ""
echo "   ☐ Update 'Confirm signup' template"
echo "   ☐ Update 'Password recovery' template"
echo ""
echo "✅ ACTION: Configure email authentication in Supabase"
echo ""
echo "Press Enter to continue..."
read

# PHASE 6
clear
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PHASE 6: UPDATE PRICE IDS (5 minutes)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Documentation: COMPLETE_DEPLOYMENT_GUIDE.md Phase 6"
echo ""
echo "Steps:"
echo "1. Create products in Stripe/Paddle:"
echo ""
echo "   ☐ Solo Plan (monthly + annual)"
echo "   ☐ Team Plan (monthly + annual)"
echo "   ☐ Workshop Plan (monthly + annual)"
echo ""
echo "2. Copy price IDs and update code:"
echo ""
echo "   ☐ lib/services/stripe_payment_service.dart (priceIds map)"
echo "   ☐ lib/services/paddle_payment_service.dart (priceIds map)"
echo ""
echo "3. Verify code compiles: flutter analyze"
echo ""
echo "✅ ACTION: Create products and update price IDs in code"
echo ""
echo "Press Enter to continue..."
read

# PHASE 7
clear
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PHASE 7: BUILD FLUTTER WEB (5 minutes)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Terminal commands:"
echo ""
echo "  $ flutter clean"
echo "  $ flutter build web --release"
echo ""
echo "Expected output:"
echo "  ✅ build/web/ directory created"
echo "  ✅ index.html"
echo "  ✅ main.dart.js (5-10 MB minified)"
echo "  ✅ assets/"
echo ""
echo "☐ Flutter build completed"
echo "☐ No errors (✅ 0 errors)"
echo ""
echo "Press Enter to continue..."
read

# PHASE 8
clear
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PHASE 8: DEPLOY TO HOSTING (5 minutes)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Documentation: COMPLETE_DEPLOYMENT_GUIDE.md Phase 8"
echo ""
echo "Choose one:"
echo ""
echo "Option A: Netlify (Recommended)"
echo "  $ npm install -g netlify-cli"
echo "  $ netlify login"
echo "  $ netlify deploy --prod --dir build/web"
echo "  ☐ Done"
echo ""
echo "Option B: Vercel"
echo "  $ npm install -g vercel"
echo "  $ vercel --prod"
echo "  ☐ Done"
echo ""
echo "Option C: Firebase"
echo "  $ firebase deploy"
echo "  ☐ Done"
echo ""
echo "Option D: Custom Server"
echo "  $ rsync -avz build/web/ user@server:/var/www/"
echo "  ☐ Done"
echo ""
echo "✅ ACTION: Deploy build/web/ to your hosting provider"
echo ""
echo "Press Enter to continue..."
read

# PHASE 9
clear
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PHASE 9: TEST EVERYTHING (5 minutes)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Documentation: COMPLETE_DEPLOYMENT_GUIDE.md Phase 9"
echo ""
echo "Test Signup:"
echo "  ☐ Open app URL"
echo "  ☐ Click 'Sign Up'"
echo "  ☐ Enter email and password (6+ chars)"
echo "  ☐ Receive confirmation email"
echo "  ☐ Click email link"
echo "  ☐ Account confirmed"
echo "  ☐ Can login"
echo ""
echo "Test Payments:"
echo "  ☐ Go to billing"
echo "  ☐ Click 'Subscribe to Team Plan'"
echo "  ☐ See payment form (Stripe/Paddle)"
echo "  ☐ Use test card: 4242 4242 4242 4242"
echo "  ☐ Complete payment"
echo "  ☐ See 'Subscription created' message"
echo ""
echo "Test AI Agent:"
echo "  ☐ Go to dashboard"
echo "  ☐ Type command in AI box"
echo "  ☐ See Groq LLM response"
echo ""
echo "Test Email:"
echo "  ☐ Create invoice"
echo "  ☐ Mark as 'Sent'"
echo "  ☐ Receive email reminder"
echo ""
echo "Check Logs:"
echo "  ☐ Supabase Dashboard → Logs"
echo "  ☐ No errors in past hour"
echo ""
echo "✅ ACTION: Run all tests above"
echo ""
echo "Press Enter to continue..."
read

# FINAL STATUS
clear
echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                                                                ║"
echo "║              ✨ DEPLOYMENT COMPLETE! ✨                       ║"
echo "║                                                                ║"
echo "║           🚀 AuraSphere CRM is LIVE! 🚀                       ║"
echo "║                                                                ║"
echo "║  All phases completed (45-60 minutes total)                   ║"
echo "║  App is accessible at your domain                             ║"
echo "║  All integrations verified and working                        ║"
echo "║                                                                ║"
echo "║  Next Steps:                                                  ║"
echo "║  1. Monitor Supabase logs for errors                         ║"
echo "║  2. Announce launch to users                                 ║"
echo "║  3. Track early user feedback                                ║"
echo "║  4. Set up analytics monitoring                              ║"
echo "║                                                                ║"
echo "║  Status: ✅ PRODUCTION LIVE                                   ║"
echo "║  Date: January 16, 2026                                      ║"
echo "║                                                                ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "Congratulations! 🎉"
echo ""
echo "Questions? Check:"
echo "  - COMPLETE_DEPLOYMENT_GUIDE.md (Troubleshooting section)"
echo "  - MASTER_DEPLOYMENT_SUMMARY.md (Quick reference)"
echo "  - API_KEYS_SETUP_GUIDE.md (Service-specific help)"
echo ""
echo "Thank you for using this deployment package!"
echo ""
