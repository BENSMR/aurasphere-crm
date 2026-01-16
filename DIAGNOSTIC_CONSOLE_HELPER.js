// Paste this into browser DevTools Console to capture detailed 401 error info

// 1. Check what Supabase is initialized with
console.log("=== Supabase Config Check ===");
try {
  // Note: Flutter's Supabase instance won't be directly accessible in console
  // But we can check if there are any network errors
  console.log("Check Network tab for requests to:");
  console.log("  https://fppmuibvpxrkwmymszhd.supabase.co/auth/v1/*");
  console.log("  https://fppmuibvpxrkwmymszhd.supabase.co/rest/v1/*");
} catch(e) {
  console.log("Error:", e);
}

// 2. Filter console for errors
console.log("=== Look for any ERROR messages below ===");

// 3. Check what headers are being sent
console.log("=== Network Tab Instructions ===");
console.log("1. Open DevTools → Network tab");
console.log("2. Reload page (F5)");
console.log("3. Look for requests to fppmuibvpxrkwmymszhd.supabase.co");
console.log("4. For any 401 error, click it and check:");
console.log("   - Request → Headers → Authorization and apikey");
console.log("   - Response → See what error message Supabase returns");
console.log("5. Copy the exact error response text");
