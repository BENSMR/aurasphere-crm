#!/bin/bash

# Get Supabase credentials from environment
SUPABASE_URL="https://igkvgrvrdpbmunxwhkax.supabase.co"
SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imlna3ZncnZyZHBibXVueHdoa2F4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDQyNDUyMDAsImV4cCI6MjAyMDI0NTIwMH0.LMQFPSP8JVqVdP_sKHbQWqfyV8tHzM1KI5tLQ7vPczs"

echo "Checking Supabase Storage Buckets..."
echo ""

# Check all buckets
curl -s \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  "$SUPABASE_URL/storage/v1/buckets" | jq '.'

echo ""
echo "Checking aura_backups bucket specifically..."
echo ""

# Check aura_backups bucket
curl -s \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  "$SUPABASE_URL/storage/v1/buckets/aura_backups" | jq '.'
