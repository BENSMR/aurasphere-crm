// supabase-test/server.js
// Express server for testing Supabase auth endpoints
// Includes health check, admin user creation, and signup proxy
// Usage: node server.js (requires Node.js 18+)
// Requires .env with SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY

import express from "express";
import fetch from "node-fetch";
import dotenv from "dotenv";
import path from "path";
import { fileURLToPath } from "url";
import fs from "fs";

dotenv.config();

const app = express();
const __dirname = path.dirname(fileURLToPath(import.meta.url));

app.use(express.json());

// ============================================================================
// Middleware
// ============================================================================

// Logging middleware
app.use((req, res, next) => {
  const start = Date.now();
  res.on("finish", () => {
    const duration = Date.now() - start;
    console.log(`[${new Date().toISOString()}] ${req.method} ${req.path} -> ${res.statusCode} (${duration}ms)`);
  });
  next();
});

// ============================================================================
// Health & Status
// ============================================================================

app.get("/health", (_, res) => {
  res.json({
    ok: true,
    timestamp: new Date().toISOString(),
  });
});

app.get("/config", (_, res) => {
  const supabaseUrl = process.env.SUPABASE_URL || "NOT_SET";
  const anonKey = process.env.SUPABASE_ANON_KEY || "NOT_SET";
  const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY || "NOT_SET";

  res.json({
    supabase_url: supabaseUrl,
    anon_key: anonKey.slice(0, 20) + "...",
    service_key: serviceKey.slice(0, 20) + "...",
    env_check: {
      SUPABASE_URL: !!process.env.SUPABASE_URL,
      SUPABASE_ANON_KEY: !!process.env.SUPABASE_ANON_KEY,
      SUPABASE_SERVICE_ROLE_KEY: !!process.env.SUPABASE_SERVICE_ROLE_KEY,
    },
  });
});

// ============================================================================
// Client-side signup proxy (optional; normally handled by supabase-js)
// ============================================================================

app.post("/api/signup", async (req, res) => {
  try {
    const { email, password } = req.body || {};

    if (!email || !password) {
      return res.status(400).json({
        error: "email and password are required",
        received: { email: !!email, password: !!password },
      });
    }

    if (!process.env.SUPABASE_URL || !process.env.SUPABASE_ANON_KEY) {
      return res.status(500).json({
        error: "SUPABASE_URL or SUPABASE_ANON_KEY not configured in .env",
      });
    }

    console.log(`📤 Proxying signup request for: ${email}`);

    const response = await fetch(`${process.env.SUPABASE_URL}/auth/v1/signup`, {
      method: "POST",
      headers: {
        apikey: process.env.SUPABASE_ANON_KEY,
        Authorization: `Bearer ${process.env.SUPABASE_ANON_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ email, password }),
    });

    const body = await response.json().catch(() => ({}));

    console.log(`📨 Signup response status: ${response.status}`);
    if (response.status >= 400) {
      console.log(`📨 Error body:`, body);
    }

    res.status(response.status).json({
      status: response.status,
      body,
    });
  } catch (e) {
    console.error("❌ Exception in /api/signup:", e);
    res.status(500).json({
      error: String(e),
      message: e.message,
    });
  }
});

// ============================================================================
// Admin endpoint: Create user with service role (server-only, KEEP KEY SECRET)
// ============================================================================

app.post("/admin/create-user", async (req, res) => {
  try {
    const { email, password } = req.body || {};

    if (!email || !password) {
      return res.status(400).json({
        error: "email and password required",
      });
    }

    if (!process.env.SUPABASE_URL || !process.env.SUPABASE_SERVICE_ROLE_KEY) {
      return res.status(500).json({
        error: "SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY not configured",
      });
    }

    console.log(`🔐 Admin creating user: ${email}`);

    const response = await fetch(`${process.env.SUPABASE_URL}/auth/v1/admin/users`, {
      method: "POST",
      headers: {
        apikey: process.env.SUPABASE_ANON_KEY,
        Authorization: `Bearer ${process.env.SUPABASE_SERVICE_ROLE_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ email, password, user_metadata: {} }),
    });

    const body = await response.json().catch(() => ({}));

    console.log(`🔐 Admin create response status: ${response.status}`);
    if (response.status >= 400) {
      console.log(`🔐 Error body:`, body);
    }

    res.status(response.status).json({
      status: response.status,
      body,
    });
  } catch (e) {
    console.error("❌ Exception in /admin/create-user:", e);
    res.status(500).json({
      error: String(e),
    });
  }
});

// ============================================================================
// Serve static HTML test page
// ============================================================================

app.get("/", (_, res) => {
  const htmlPath = path.join(__dirname, "../signup-test.html");
  if (fs.existsSync(htmlPath)) {
    res.sendFile(htmlPath);
  } else {
    res.json({
      message: "Server running. Create signup-test.html or visit /health",
      endpoints: {
        "/health": "GET - Health check",
        "/config": "GET - Show configuration status",
        "/api/signup": "POST - Client signup proxy (email, password)",
        "/admin/create-user": "POST - Admin user creation (service role required)",
      },
    });
  }
});

// ============================================================================
// Start Server
// ============================================================================

const PORT = process.env.PORT || 5174;
app.listen(PORT, () => {
  console.log(`\n🚀 Server listening on http://localhost:${PORT}`);
  console.log(`📝 Test signup at: http://localhost:${PORT}/`);
  console.log(`\n📋 Endpoints:`);
  console.log(`   GET  /health           - Health check`);
  console.log(`   GET  /config           - Configuration status`);
  console.log(`   POST /api/signup       - Client signup proxy`);
  console.log(`   POST /admin/create-user - Admin user creation\n`);
});
