# 📚 API Documentation - Complete Reference Guide

**Version**: 1.0 | **Updated**: January 15, 2026  
**API Version**: v2.0 | **Protocol**: REST + WebSocket

---

## 🎯 Overview

AuraSphere CRM provides a comprehensive API for integrating with the platform. The API follows RESTful principles and uses JWT authentication via Supabase.

### Base URLs

| Environment | URL | Status |
|-------------|-----|--------|
| Production | `https://fppmuibvpxrkwmymszhd.supabase.co` | ✅ Active |
| Local Dev | `http://localhost:54321` | Dev only |

### Authentication

All requests require a valid JWT token from Supabase Auth:

```bash
Authorization: Bearer <supabase_jwt_token>
```

---

## 📋 Table of Contents

- [Authentication APIs](#authentication-apis)
- [Invoice APIs (All Plans)](#invoice-apis)
- [Job Management APIs (All Plans)](#job-management-apis)
- [Client Management APIs (All Plans)](#client-management-apis)
- [Team APIs (Team+ Plans)](#team-apis)
- [Device Management APIs (Team+ Plans)](#device-management-apis)
- [Feature Personalization APIs (All Plans)](#feature-personalization-apis)
- [Payment APIs (Plan-Dependent)](#payment-apis)
- [AI Agent APIs (Plan-Dependent)](#ai-agent-apis)
- [Integration APIs (Plan-Dependent)](#integration-apis)
- [Real-Time APIs](#real-time-apis)
- [Error Handling](#error-handling)

---

## Authentication APIs

### Sign Up

```http
POST /rest/v1/auth/v1/signup
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "secure_password_123"
}
```

**Response**: 
```json
{
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "created_at": "2026-01-15T10:00:00Z"
  },
  "session": {
    "access_token": "eyJhbGc...",
    "refresh_token": "eyJhbGc...",
    "expires_in": 3600
  }
}
```

**Status Codes**:
- `200 OK` - User created successfully
- `400 Bad Request` - Invalid email or password
- `409 Conflict` - Email already exists

### Sign In

```http
POST /rest/v1/auth/v1/signin?grant_type=password
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "secure_password_123"
}
```

**Response**: Same as Sign Up response

**Status Codes**:
- `200 OK` - Login successful
- `400 Bad Request` - Invalid credentials
- `401 Unauthorized` - User not found

### Refresh Token

```http
POST /rest/v1/auth/v1/token?grant_type=refresh_token
Content-Type: application/json

{
  "refresh_token": "eyJhbGc..."
}
```

**Response**:
```json
{
  "access_token": "eyJhbGc...",
  "expires_in": 3600
}
```

### Sign Out

```http
POST /rest/v1/auth/v1/logout
Authorization: Bearer <jwt_token>
```

**Response**: `200 OK`

---

## Invoice APIs

### ✅ Available in All Plans (Solo, Team, Workshop)

### Create Invoice

```http
POST /rest/v1/invoices
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "org_id": "org_uuid",
  "client_id": "client_uuid",
  "amount": 500.00,
  "currency": "USD",
  "due_date": "2026-02-15",
  "description": "Plumbing repair services",
  "items": [
    {
      "description": "Labor",
      "quantity": 5,
      "unit_price": 100.00
    }
  ],
  "notes": "Payment due within 30 days",
  "custom_template_id": "template_uuid" // optional
}
```

**Response**:
```json
{
  "id": "invoice_uuid",
  "org_id": "org_uuid",
  "client_id": "client_uuid",
  "amount": 500.00,
  "currency": "USD",
  "status": "draft",
  "due_date": "2026-02-15",
  "created_at": "2026-01-15T10:00:00Z",
  "payment_link": "https://stripe.example.com/pay/...",
  "pdf_url": "https://storage.example.com/invoices/..."
}
```

**Status Codes**:
- `201 Created` - Invoice created successfully
- `400 Bad Request` - Invalid invoice data
- `403 Forbidden` - User not authorized for this organization

### Get Invoices

```http
GET /rest/v1/invoices?org_id=org_uuid&status=pending&limit=50&offset=0
Authorization: Bearer <jwt_token>
```

**Query Parameters**:
| Parameter | Type | Description |
|-----------|------|-------------|
| `org_id` | string (required) | Organization ID |
| `status` | string | Filter by status: draft, sent, paid, overdue, cancelled |
| `client_id` | string | Filter by client |
| `limit` | integer | Page size (default: 50, max: 100) |
| `offset` | integer | Pagination offset (default: 0) |
| `sort` | string | Sort field: created_at, due_date, amount |

**Response**:
```json
{
  "data": [
    {
      "id": "invoice_uuid",
      "amount": 500.00,
      "status": "pending",
      "due_date": "2026-02-15",
      "created_at": "2026-01-15T10:00:00Z"
    }
  ],
  "count": 150,
  "total_pages": 3
}
```

### Get Invoice by ID

```http
GET /rest/v1/invoices/{invoice_id}
Authorization: Bearer <jwt_token>
```

**Response**: Single invoice object (same as Create response)

**Status Codes**:
- `200 OK` - Invoice found
- `404 Not Found` - Invoice not found
- `403 Forbidden` - User not authorized

### Update Invoice

```http
PATCH /rest/v1/invoices/{invoice_id}
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "status": "sent",
  "due_date": "2026-03-01"
}
```

**Allowed Updates**:
- `status` - draft, sent, paid, overdue, cancelled
- `due_date` - ISO 8601 date
- `notes` - Plain text notes
- `items` - Array of line items

**Response**: Updated invoice object

**Status Codes**:
- `200 OK` - Invoice updated
- `400 Bad Request` - Invalid update
- `409 Conflict` - Cannot update (e.g., already paid)

### Send Invoice

```http
POST /rest/v1/invoices/{invoice_id}/send
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "email_subject": "Your Invoice #{invoice_number}",
  "email_message": "Please find your invoice attached. Payment due by {due_date}.",
  "send_sms": true // optional
}
```

**Response**:
```json
{
  "id": "invoice_uuid",
  "status": "sent",
  "sent_at": "2026-01-15T10:05:00Z",
  "delivery_status": {
    "email": "delivered",
    "sms": "pending"
  }
}
```

### Generate PDF

```http
POST /rest/v1/invoices/{invoice_id}/pdf
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "template_id": "template_uuid", // optional, uses default if omitted
  "include_signature": false,
  "include_qr_code": true
}
```

**Response**:
```json
{
  "pdf_url": "https://storage.example.com/invoices/inv_123.pdf",
  "size_bytes": 45234,
  "generated_at": "2026-01-15T10:05:00Z"
}
```

### Generate Payment Link (Stripe)

```http
POST /rest/v1/invoices/{invoice_id}/payment-link
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "currency": "USD",
  "success_url": "https://yourapp.com/success",
  "cancel_url": "https://yourapp.com/cancelled"
}
```

**Response**:
```json
{
  "payment_link": "https://checkout.stripe.com/pay/...",
  "stripe_invoice_id": "in_1234567890",
  "status": "active"
}
```

---

## Job Management APIs

### ✅ Available in All Plans

### Create Job

```http
POST /rest/v1/jobs
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "org_id": "org_uuid",
  "client_id": "client_uuid",
  "title": "Kitchen plumbing repair",
  "description": "Fix leaking faucet and install new sink",
  "status": "scheduled",
  "start_date": "2026-01-20",
  "start_time": "09:00",
  "end_date": "2026-01-20",
  "end_time": "17:00",
  "address": "123 Main St, City, State 12345",
  "assigned_to": "team_member_uuid", // optional
  "materials_needed": [
    {
      "item_id": "item_uuid",
      "quantity": 2,
      "unit": "pcs"
    }
  ],
  "estimated_cost": 500.00,
  "priority": "high" // low, medium, high, urgent
}
```

**Response**:
```json
{
  "id": "job_uuid",
  "org_id": "org_uuid",
  "title": "Kitchen plumbing repair",
  "status": "scheduled",
  "start_date": "2026-01-20",
  "assigned_to": "team_member_uuid",
  "created_at": "2026-01-15T10:00:00Z",
  "updated_at": "2026-01-15T10:00:00Z"
}
```

### Get Jobs

```http
GET /rest/v1/jobs?org_id=org_uuid&status=active&limit=50
Authorization: Bearer <jwt_token>
```

**Query Parameters**:
| Parameter | Type | Description |
|-----------|------|-------------|
| `org_id` | string (required) | Organization ID |
| `status` | string | scheduled, in_progress, completed, cancelled |
| `assigned_to` | string | Filter by team member |
| `start_date` | string | Filter jobs starting after this date |
| `priority` | string | low, medium, high, urgent |
| `limit` | integer | Page size (default: 50) |
| `offset` | integer | Pagination offset |

### Update Job Status

```http
PATCH /rest/v1/jobs/{job_id}
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "status": "in_progress",
  "notes": "Started work on kitchen sink",
  "assigned_to": "team_member_uuid"
}
```

### Complete Job

```http
POST /rest/v1/jobs/{job_id}/complete
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "completion_notes": "Repair completed successfully",
  "actual_cost": 450.00,
  "create_invoice": true,
  "invoice_amount": 500.00
}
```

**Response**:
```json
{
  "id": "job_uuid",
  "status": "completed",
  "completed_at": "2026-01-20T15:30:00Z",
  "invoice_id": "invoice_uuid" // if create_invoice=true
}
```

---

## Client Management APIs

### ✅ Available in All Plans

### Create Client

```http
POST /rest/v1/clients
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "org_id": "org_uuid",
  "name": "John Smith",
  "email": "john@example.com",
  "phone": "+1 (555) 123-4567",
  "address": "123 Main St, City, State 12345",
  "city": "City",
  "state": "State",
  "postal_code": "12345",
  "country": "USA",
  "business_name": "Smith Properties Inc.", // optional
  "tax_id": "12-3456789", // optional
  "notes": "Preferred client, VIP status"
}
```

**Response**:
```json
{
  "id": "client_uuid",
  "org_id": "org_uuid",
  "name": "John Smith",
  "email": "john@example.com",
  "phone": "+1 (555) 123-4567",
  "created_at": "2026-01-15T10:00:00Z",
  "invoice_count": 0,
  "total_spent": 0.00,
  "last_contacted": null
}
```

### Get Clients

```http
GET /rest/v1/clients?org_id=org_uuid&search=Smith&limit=50
Authorization: Bearer <jwt_token>
```

**Query Parameters**:
| Parameter | Type | Description |
|-----------|------|-------------|
| `org_id` | string (required) | Organization ID |
| `search` | string | Search by name, email, or phone |
| `sort` | string | created_at, name, total_spent |
| `limit` | integer | Page size (default: 50) |

### Update Client

```http
PATCH /rest/v1/clients/{client_id}
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "email": "newemail@example.com",
  "phone": "+1 (555) 987-6543",
  "notes": "Updated contact information"
}
```

---

## Team APIs

### 🟡 Available in Team & Workshop Plans Only

### Get Team Members

```http
GET /rest/v1/org_members?org_id=org_uuid
Authorization: Bearer <jwt_token>
```

**Response**:
```json
{
  "data": [
    {
      "id": "member_uuid",
      "user_id": "user_uuid",
      "email": "member@example.com",
      "role": "member", // owner, member, technician, admin
      "joined_at": "2026-01-15T10:00:00Z",
      "status": "active" // active, invited, inactive
    }
  ]
}
```

### Invite Team Member

```http
POST /rest/v1/org_members/invite
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "org_id": "org_uuid",
  "email": "newmember@example.com",
  "role": "member", // member, technician, admin
  "send_email": true
}
```

**Response**:
```json
{
  "id": "invitation_uuid",
  "email": "newmember@example.com",
  "role": "member",
  "status": "pending",
  "invitation_url": "https://yourapp.com/invite/abc123xyz",
  "expires_at": "2026-01-29T10:00:00Z"
}
```

### Update Team Member Role

```http
PATCH /rest/v1/org_members/{member_id}
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "role": "admin"
}
```

**Allowed Roles**: member, technician, admin (Owner cannot be changed)

### Remove Team Member

```http
DELETE /rest/v1/org_members/{member_id}
Authorization: Bearer <jwt_token>
```

**Response**: `204 No Content`

---

## Device Management APIs

### 🟡 Available in Team & Workshop Plans Only

### Register Device

```http
POST /rest/v1/devices
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "org_id": "org_uuid",
  "device_type": "mobile", // mobile or tablet
  "device_name": "John's iPhone",
  "reference_code": "AUTO" // AUTO generates random code
}
```

**Response**:
```json
{
  "id": "device_uuid",
  "org_id": "org_uuid",
  "device_type": "mobile",
  "device_name": "John's iPhone",
  "reference_code": "ABC123XYZ",
  "registered_at": "2026-01-15T10:00:00Z",
  "registered_by": "owner_uuid"
}
```

**Status Codes**:
- `201 Created` - Device registered
- `400 Bad Request` - Invalid device type
- `409 Conflict` - Device limit reached for plan

### Get Device Limit Summary

```http
GET /rest/v1/device-limits?org_id=org_uuid
Authorization: Bearer <jwt_token>
```

**Response**:
```json
{
  "mobile": {
    "limit": 3,
    "used": 2,
    "available": 1,
    "can_add": true
  },
  "tablet": {
    "limit": 2,
    "used": 1,
    "available": 1,
    "can_add": true
  }
}
```

### Get Devices

```http
GET /rest/v1/devices?org_id=org_uuid&device_type=mobile
Authorization: Bearer <jwt_token>
```

---

## Feature Personalization APIs

### ✅ Available in All Plans

### Get Personalized Features

```http
GET /rest/v1/feature-personalization?device_type=mobile
Authorization: Bearer <jwt_token>
```

**Query Parameters**:
| Parameter | Type | Description |
|-----------|------|-------------|
| `device_type` | string | mobile or tablet (required) |

**Response**:
```json
{
  "device_type": "mobile",
  "selected_features": [
    {
      "id": "dashboard",
      "name": "Dashboard",
      "icon": "dashboard",
      "enabled": true
    },
    {
      "id": "jobs",
      "name": "Jobs",
      "icon": "work",
      "enabled": true
    }
  ],
  "total_features": 6,
  "max_allowed": 6
}
```

### Update Personalized Features

```http
POST /rest/v1/feature-personalization
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "device_type": "mobile",
  "selected_feature_ids": [
    "dashboard",
    "jobs",
    "invoices",
    "clients",
    "calendar",
    "expenses"
  ]
}
```

**Response**:
```json
{
  "success": true,
  "device_type": "mobile",
  "total_features": 6,
  "max_allowed": 6
}
```

### Add Feature

```http
POST /rest/v1/feature-personalization/add
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "device_type": "mobile",
  "feature_id": "inventory"
}
```

### Remove Feature

```http
POST /rest/v1/feature-personalization/remove
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "device_type": "mobile",
  "feature_id": "inventory"
}
```

### Reset to Defaults

```http
POST /rest/v1/feature-personalization/reset
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "device_type": "mobile"
}
```

---

## 🔐 Owner-Only Feature Control APIs

### Force Enable All Features

```http
POST /rest/v1/feature-personalization/force-enable
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "target_device_id": "device_uuid",
  "target_user_id": "user_uuid"
}
```

**Response**:
```json
{
  "success": true,
  "message": "All features enabled on device",
  "features_enabled": 6,
  "enforced": true
}
```

**Status Codes**:
- `200 OK` - Features enforced
- `403 Forbidden` - User is not organization owner

### Disable Features

```http
POST /rest/v1/feature-personalization/disable
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "target_device_id": "device_uuid",
  "target_user_id": "user_uuid",
  "features_to_disable": ["inventory", "reports"]
}
```

### Lock Features Org-Wide

```http
POST /rest/v1/feature-personalization/lock-org-wide
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "locked_feature_ids": ["ai_agents", "integrations"],
  "reason": "Compliance requirement"
}
```

### Get Feature Audit Log

```http
GET /rest/v1/feature-personalization/audit-log?org_id=org_uuid&limit=100
Authorization: Bearer <jwt_token>
```

**Response**:
```json
{
  "data": [
    {
      "action": "force_enable_allFeatures",
      "performed_by": "owner_uuid",
      "target_user_id": "user_uuid",
      "details": "All 6 features enabled on mobile device",
      "created_at": "2026-01-15T10:05:00Z"
    }
  ]
}
```

---

## Payment APIs

### 🎯 Subscription Plan-Based Access

#### SOLO Plan
- ❌ No payment APIs (uses Stripe/Paddle checkouts)

#### TEAM & WORKSHOP Plans
- ✅ All payment endpoints

### Create Stripe Checkout Session

```http
POST /rest/v1/stripe/checkout
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "plan": "team", // solo, team, workshop
  "billing_period": "monthly",
  "success_url": "https://yourapp.com/dashboard",
  "cancel_url": "https://yourapp.com/pricing"
}
```

**Response**:
```json
{
  "session_id": "cs_1234567890",
  "url": "https://checkout.stripe.com/pay/cs_1234567890",
  "status": "active"
}
```

### Create Paddle Checkout Session

```http
POST /rest/v1/paddle/checkout
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "plan": "team",
  "billing_period": "monthly",
  "customer_email": "user@example.com"
}
```

### Get Subscription Status

```http
GET /rest/v1/subscription
Authorization: Bearer <jwt_token>
```

**Response**:
```json
{
  "org_id": "org_uuid",
  "plan": "team",
  "status": "active",
  "provider": "stripe", // stripe or paddle
  "provider_id": "sub_1234567890",
  "renewal_date": "2026-02-15",
  "cancel_at_period_end": false
}
```

### Redeem Prepayment Code

```http
POST /rest/v1/prepayment-codes/redeem
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "code": "ABC123XYZ"
}
```

**Response**:
```json
{
  "success": true,
  "amount": 100.00,
  "currency": "USD",
  "plan": "team",
  "validity_period": "3 months",
  "expires_at": "2026-04-15"
}
```

---

## AI Agent APIs

### 🎯 Plan-Based Access

#### SOLO Plan
- ✅ `POST /rest/v1/ai/job-automation` (Full)
- ❌ All other agents disabled

#### TEAM Plan
- ✅ `POST /rest/v1/ai/job-automation` (Full)
- 🟡 Limited agent endpoints (all agents available with basic features)

#### WORKSHOP Plan
- ✅ All AI agent endpoints (full features)

### Job Automation

```http
POST /rest/v1/ai/job-automation
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "org_id": "org_uuid"
}
```

**Response**:
```json
{
  "status": "executed",
  "jobs_assigned": 3,
  "team_members_notified": 2,
  "executed_at": "2026-01-15T10:05:00Z"
}
```

### CFO Agent

```http
POST /rest/v1/ai/cfo-agent
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "org_id": "org_uuid"
}
```

**Response**:
```json
{
  "status": "executed",
  "overdue_reminders_sent": 2,
  "total_overdue_amount": 1500.00,
  "executed_at": "2026-01-15T10:05:00Z"
}
```

### CEO Agent

```http
POST /rest/v1/ai/ceo-agent
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "org_id": "org_uuid"
}
```

**Response**:
```json
{
  "status": "executed",
  "revenue_summary": {
    "period": "monthly",
    "total_revenue": 5000.00,
    "paid_invoices": 3,
    "pending_invoices": 2
  },
  "recommendations": [
    "Follow up on 2 overdue invoices",
    "Consider raising prices - high demand"
  ]
}
```

### Marketing Agent

```http
POST /rest/v1/ai/marketing-agent
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "org_id": "org_uuid"
}
```

**Response**:
```json
{
  "status": "executed",
  "inactive_clients_identified": 5,
  "emails_sent": 5,
  "executed_at": "2026-01-15T10:05:00Z"
}
```

### Sales Agent

```http
POST /rest/v1/ai/sales-agent
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "org_id": "org_uuid"
}
```

**Response**:
```json
{
  "status": "executed",
  "clients_scored": 25,
  "high_value_clients": 8,
  "low_value_clients": 4,
  "recommended_actions": [...]
}
```

---

## Integration APIs

### 🎯 Plan-Based Access

#### SOLO Plan
- ❌ Most integrations disabled

#### TEAM Plan
- 🟡 Limited integration features

#### WORKSHOP Plan
- ✅ All integrations fully enabled

### Send WhatsApp Message

```http
POST /rest/v1/integrations/whatsapp/send
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "org_id": "org_uuid",
  "phone_number": "+1 (555) 123-4567",
  "message": "Your invoice #INV-001 is ready. Pay here: {payment_link}",
  "media_url": "https://storage.example.com/file.pdf" // optional
}
```

**Response**:
```json
{
  "message_id": "msg_uuid",
  "status": "sent",
  "sent_at": "2026-01-15T10:05:00Z",
  "delivery_status": "delivered"
}
```

### Send Email

```http
POST /rest/v1/integrations/email/send
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "org_id": "org_uuid",
  "to": "client@example.com",
  "subject": "Your Invoice INV-001",
  "html_body": "<h1>Invoice</h1><p>Amount: $500</p>",
  "attachments": ["invoice.pdf"]
}
```

### Sync to HubSpot

```http
POST /rest/v1/integrations/hubspot/sync
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "org_id": "org_uuid",
  "sync_type": "deals", // deals, contacts, companies
  "direction": "to_hubspot" // to_hubspot or from_hubspot
}
```

### Sync to QuickBooks

```http
POST /rest/v1/integrations/quickbooks/sync
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "org_id": "org_uuid",
  "sync_type": "invoices", // invoices, expenses, customers
  "direction": "to_quickbooks"
}
```

---

## Real-Time APIs

### WebSocket Connection

```javascript
const channel = supabase
  .channel('jobs:org_uuid')
  .on('postgres_changes',
    { event: '*', schema: 'public', table: 'jobs' },
    (payload) => {
      console.log('Job updated:', payload);
    }
  )
  .subscribe();
```

### Listen to Invoice Updates

```javascript
const channel = supabase
  .channel('invoices:org_uuid')
  .on('postgres_changes',
    { event: 'UPDATE', schema: 'public', table: 'invoices' },
    (payload) => {
      console.log('Invoice status changed:', payload.new);
    }
  )
  .subscribe();
```

### Broadcast Presence

```javascript
const channel = supabase.channel('team:org_uuid');

await channel.track({
  user_id: user.id,
  page: 'dashboard',
  status: 'online'
});

channel.on('presence', { event: 'sync' }, () => {
  const state = channel.presenceState();
  console.log('Online users:', state);
});
```

---

## Error Handling

### Standard Error Response

```json
{
  "code": "INVALID_REQUEST",
  "message": "Missing required field: org_id",
  "details": {
    "field": "org_id",
    "reason": "required"
  },
  "status_code": 400
}
```

### Common Status Codes

| Code | Meaning |
|------|---------|
| `200 OK` | Request successful |
| `201 Created` | Resource created successfully |
| `204 No Content` | Request successful, no content to return |
| `400 Bad Request` | Invalid request parameters |
| `401 Unauthorized` | Missing or invalid authentication |
| `403 Forbidden` | User lacks permission for this action |
| `404 Not Found` | Resource not found |
| `409 Conflict` | Request conflicts with current state (e.g., device limit) |
| `422 Unprocessable Entity` | Request validation failed |
| `429 Too Many Requests` | Rate limit exceeded |
| `500 Internal Server Error` | Server error |

### Authentication Errors

```json
{
  "code": "INVALID_TOKEN",
  "message": "Invalid or expired JWT token",
  "status_code": 401
}
```

### Authorization Errors

```json
{
  "code": "PERMISSION_DENIED",
  "message": "You do not have permission to access this resource",
  "status_code": 403
}
```

### Rate Limiting

```json
{
  "code": "RATE_LIMIT_EXCEEDED",
  "message": "Too many requests. Please try again later.",
  "retry_after_seconds": 60,
  "status_code": 429
}
```

---

## Pagination

All list endpoints support pagination with `limit` and `offset`:

```http
GET /rest/v1/invoices?org_id=org_uuid&limit=50&offset=100
```

**Response includes**:
```json
{
  "data": [...],
  "count": 250,
  "limit": 50,
  "offset": 100,
  "total_pages": 5
}
```

---

## Rate Limiting

- **Solo Plan**: 100 requests/minute
- **Team Plan**: 500 requests/minute
- **Workshop Plan**: 2000 requests/minute

Headers returned:
```
X-RateLimit-Limit: 500
X-RateLimit-Remaining: 487
X-RateLimit-Reset: 1642276800
```

---

Generated: January 15, 2026
