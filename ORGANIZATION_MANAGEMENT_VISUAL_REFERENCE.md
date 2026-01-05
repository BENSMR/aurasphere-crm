# 🎯 Organization Management System - Visual Reference

**Complete system architecture and data flow diagrams**

---

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     AuraSphere CRM                              │
│                  Organization Management                        │
└─────────────────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
        ▼                   ▼                   ▼
   ┌─────────┐         ┌──────────┐        ┌─────────┐
   │Company  │         │Team      │        │Device   │
   │Profile  │         │Management│        │Mgmt     │
   └─────────┘         └──────────┘        └─────────┘
        │                   │                   │
        ├─ Registration    ├─ Members          ├─ Mobile
        ├─ Tax Info        ├─ Roles            ├─ Tablet
        ├─ Address         ├─ Permissions      ├─ Approval
        ├─ Logo            ├─ Approval         ├─ Features
        └─ Colors          └─ Activity         └─ Access Log
                                │
                        ┌───────┴──────┐
                        │              │
                        ▼              ▼
                    ┌────────┐    ┌──────────┐
                    │Member  │    │Feature   │
                    │Code    │    │Custom.   │
                    │(Unique)│    │Per Device│
                    └────────┘    └──────────┘
```

---

## 📊 Data Flow Diagrams

### Adding a Team Member

```
CEO/Owner
    │
    ├─ Enters member email & details
    │
    ▼
Add Member Form
    │
    ├─ Validate input
    ├─ Generate member code (TM-XXXXXXXX)
    ├─ Create auth user
    ├─ Save to org_members table
    │
    ▼
Member Record Created
    │
    ├─ Status: PENDING
    ├─ is_active: FALSE
    ├─ approval_status: pending
    │
    ▼
Invitation Email Sent
    │
    ├─ Unique code shared
    ├─ Login link provided
    ├─ Set temporary password
    │
    ▼
CEO Approval Queue
    │
    ├─ CEO reviews pending approvals
    │
    ├─── Approve ──┐
    │              │
    └─ Reject ─┐   │
               │   │
               ▼   ▼
            ┌────────────┐    ┌──────────┐
            │ Rejected   │    │ Approved │
            │ Status: ❌  │    │Status: ✅ │
            │ is_active: │    │is_active:│
            │ FALSE      │    │TRUE      │
            └────────────┘    └──────────┘
                                   │
                                   ▼
                           Member can now login
                           & access features
```

### Registering a Device

```
Team Member
    │
    ├─ Requests device registration
    │
    ▼
Device Registration Form
    │
    ├─ Enter device details
    │  ├─ Device name (e.g., "John's iPhone")
    │  ├─ Device type (mobile/tablet)
    │  ├─ Device model
    │  └─ OS version
    │
    ▼
Generate Device Code
    │
    ├─ Format: DEV-XXXXXXXXXX
    ├─ Unique identifier
    ├─ Non-reusable
    │
    ▼
Device Record Created
    │
    ├─ Status: PENDING
    ├─ is_active: FALSE
    ├─ approval_status: pending
    │
    ▼
Notification to CEO
    │
    ├─ CEO gets alert
    ├─ Reviews pending approvals
    │
    ├─── Approve ──┐
    │              │
    └─ Revoke ─┐   │
               │   │
               ▼   ▼
            ┌──────────┐    ┌─────────────┐
            │ Revoked  │    │  Approved   │
            │Status: ❌ │    │ Status: ✅  │
            │Can't use │    │ Can use app │
            │ app      │    │ now         │
            └──────────┘    └──────────────┘
                                   │
                                   ▼
                          Set device features
                          (8 for mobile,
                           12 for tablet)
```

---

## 🔄 Approval Workflow

### Member Approval Flow

```
Step 1: PENDING
┌──────────────────────────────────┐
│ CEO receives notification        │
│ Member code: TM-ABC12345         │
│ Email verified: john@company.com │
│ Role: Manager                    │
└──────────────────────────────────┘
        │
        ▼
Step 2: REVIEW
┌──────────────────────────────────┐
│ CEO can:                         │
│ • View member details            │
│ • Review assigned role           │
│ • Check permissions              │
│ • View activity history          │
└──────────────────────────────────┘
        │
        ├─ APPROVE ─────┐
        │                │
        └─ REJECT ──┐   │
                    │   │
                    ▼   ▼
               ┌────────────────┐
               │ Status Updated │
               │ Log recorded   │
               │ Email sent     │
               └────────────────┘
```

### Device Approval Flow

```
Step 1: REGISTRATION
┌────────────────────────────┐
│ Device registered          │
│ Code: DEV-ABCD1234567890   │
│ Type: Mobile (iPhone 14)   │
│ Member: John Smith         │
└────────────────────────────┘
        │
        ▼
Step 2: PENDING
┌────────────────────────────┐
│ Awaiting CEO approval      │
│ Features not yet active    │
│ Access denied until OK'd   │
└────────────────────────────┘
        │
        ▼
Step 3: CEO REVIEW
┌────────────────────────────┐
│ CEO can:                   │
│ • View device details      │
│ • See member assignment    │
│ • Check device history     │
│ • Set feature access       │
└────────────────────────────┘
        │
        ├─ APPROVE ─────┐
        │                │
        └─ REVOKE ──┐   │
                    │   │
                    ▼   ▼
               ┌────────────────┐
               │ Status Updated │
               │ Features set   │
               │ Access enabled │
               └────────────────┘
```

---

## 👥 Organizational Hierarchy

### Team Structure

```
┌─────────────────────────────────────────────────┐
│              ORGANIZATION                       │
│        (Company Registry Entry)                 │
└──────────────────────┬──────────────────────────┘
                       │
        ┌──────────────┼──────────────┐
        │              │              │
        ▼              ▼              ▼
    ┌─────────┐   ┌─────────┐   ┌─────────┐
    │ OWNER   │   │ MANAGER │   │ MEMBER  │
    │ Full    │   │ Team    │   │ Individ │
    │ Control │   │ Super   │   │ Contrib │
    └─────────┘   └─────────┘   └─────────┘
        │              │              │
        ├──AllAccess   ├──Limited     ├──JobMgmt
        ├──ApproveAll  ├──Supervise   ├──Invoices
        ├──Billing     ├──Reports     ├──Expenses
        └──Settings    └──NoApproval  └──ReadOnly


CODES:
┌─────────────────┬──────────┐
│ Owner           │ No code  │
│ Manager         │TM-XXXXX1 │
│ Member          │TM-XXXXX2 │
│ Technician      │TM-XXXXX3 │
└─────────────────┴──────────┘
```

---

## 📱 Device Feature Mapping

### Mobile Devices (Max 8 Features)

```
Mobile Device
├─ Dashboard ✓
├─ Jobs ✓
├─ Invoices ✓
├─ Clients ✓
├─ Calendar ✓
├─ OCR Scanning ✓
├─ Reports ✓
├─ AI Chat ✓
├─ Inventory ✗ (tablet only)
├─ Team ✗ (tablet only)
├─ Dispatch ✗ (tablet only)
└─ Settings ✗ (tablet only)
```

### Tablet Devices (Max 12 Features)

```
Tablet Device
├─ Dashboard ✓
├─ Jobs ✓
├─ Invoices ✓
├─ Clients ✓
├─ Calendar ✓
├─ OCR Scanning ✓
├─ Reports ✓
├─ AI Chat ✓
├─ Inventory ✓ (mobile only has 8)
├─ Team ✓
├─ Dispatch ✓
└─ Settings ✓
```

---

## 🔐 Permission Matrix

### Role vs. Permissions

```
                    │ Owner │Manager│Member │Tech
────────────────────┼───────┼───────┼───────┼────
Dashboard           │   ✓   │   ✓   │   ✓   │ ✓
Jobs                │   ✓   │   ✓   │   ✓   │ ✓
Invoices            │   ✓   │   ✓   │   ✓   │ ✗
Clients             │   ✓   │   ✓   │   ✓   │ ✗
Calendar            │   ✓   │   ✓   │   ✓   │ ✗
Team Management     │   ✓   │   ✗   │   ✗   │ ✗
Device Management   │   ✓   │   ✗   │   ✗   │ ✗
Inventory           │   ✓   │   ✓   │   ✗   │ ✗
Expenses            │   ✓   │   ✓   │   ✓   │ ✗
Reports             │   ✓   │   ✓   │   ✓   │ ✗
AI Agents           │   ✓   │   ✓   │   ✓   │ ✗
Settings            │   ✓   │   ✗   │   ✗   │ ✗
Billing             │   ✓   │   ✗   │   ✗   │ ✗
Approvals (Members) │   ✓   │   ✗   │   ✗   │ ✗
Approvals (Devices) │   ✓   │   ✗   │   ✗   │ ✗
────────────────────┴───────┴───────┴───────┴────
```

---

## 🎨 Company Profile Schema

### Basic Information Section

```
┌─────────────────────────────────────────┐
│ COMPANY PROFILE                         │
├─────────────────────────────────────────┤
│ Company Name                 [TextInput] │
│ Business Type               [Dropdown]   │
│   └─ Freelancer                        │
│   └─ Small Team                        │
│   └─ Workshop                          │
│   └─ Enterprise                        │
│ Industry                    [Dropdown]   │
│   └─ Construction                      │
│   └─ Plumbing                          │
│   └─ Electrical                        │
│   └─ ... (40+ options)                 │
└─────────────────────────────────────────┘
```

### Contact Information Section

```
┌─────────────────────────────────────────┐
│ CONTACT INFORMATION                     │
├─────────────────────────────────────────┤
│ Phone Number              [TextInput]    │
│ Email Address             [TextInput]    │
│ Website URL               [TextInput]    │
│ Logo Upload               [ImagePicker]  │
└─────────────────────────────────────────┘
```

### Address Section

```
┌─────────────────────────────────────────┐
│ ADDRESS                                 │
├─────────────────────────────────────────┤
│ Street Address            [TextInput]    │
│ ┌─────────────────────────────────────┐ │
│ │ City      [Input] │ State [Input]  │ │
│ └─────────────────────────────────────┘ │
│ ┌─────────────────────────────────────┐ │
│ │ Zip Code  [Input] │ Country[Input] │ │
│ └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

### Branding Section

```
┌─────────────────────────────────────────┐
│ BRANDING COLORS                         │
├─────────────────────────────────────────┤
│ Primary Color   [#007BFF] [COLOR PICKER]│
│ Secondary Color [#6C757D] [COLOR PICKER]│
│ Accent Color    [#28A745] [COLOR PICKER]│
└─────────────────────────────────────────┘
```

---

## 📊 Code Generation Examples

### Member Code Pattern

```
TM-ABCDE12345
││  └─────────┘
││       │
││       └─ 8 random characters
││         (A-Z, 0-9)
││
│└─ Team
│  (Type indicator)
│
└─ Member
   (Entity type)
```

### Device Code Pattern

```
DEV-ABCDEFGHIJ
││   └────────┘
││       │
││       └─ 10 random characters
││         (A-Z, 0-9)
││
│└─ Device
│  (Type indicator)
│
└─ DEV
   (Entity type)
```

---

## 🔄 Status Transitions

### Member Status Lifecycle

```
┌─────────┐
│Invitation
│Sent     │
└────┬────┘
     │
     ▼
┌─────────────┐
│ PENDING     │
│ (Awaiting   │
│  CEO        │
│  Approval)  │
└──┬────────┬─┘
   │        │
   │ REJECT │ APPROVE
   │        │
   ▼        ▼
┌──────┐  ┌──────────┐
│      │  │ APPROVED │
│❌    │  │ ✓ Active │
│ DONE │  │(Can Login)
└──────┘  └──────────┘
```

### Device Status Lifecycle

```
┌──────────────┐
│Registration  │
│Form Complete │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ PENDING      │
│ (Awaiting    │
│  CEO App.)   │
└──┬─────────┬─┘
   │         │
   │ REVOKE  │ APPROVE
   │         │
   ▼         ▼
┌──────┐  ┌─────────────┐
│      │  │  APPROVED   │
│❌    │  │✓ Active     │
│DONE  │  │(Can use app)│
└──────┘  └─────────────┘
```

---

## 📈 Completion Progress

### Profile Completion Percentage

```
Progress Indicator
┌──────────────────────────────────┐
│ Completion  ████████░░░░░░░  75% │
└──────────────────────────────────┘

Fields Tracked (16 total):
✓ Company name
✓ Registration number
✓ Tax number
✓ Business type
✓ Industry
✓ Address
✓ City
✓ State
✓ Zip code
✓ Country
✓ Phone
✓ Email
✓ Logo
✓ Primary color
✗ Website (not filled)
✗ Secondary color (not filled)
```

---

## 🔍 Code Lookup Flows

### Member Lookup by Code

```
Input: TM-ABC12345
   │
   ▼
Query org_members table
WHERE member_code = 'TM-ABC12345'
   │
   ▼
Return:
┌────────────────────────┐
│ ID: 123e4567           │
│ Name: John Smith       │
│ Email: john@...com     │
│ Role: Manager          │
│ Status: Approved ✓     │
│ Active: True           │
│ Created: 2024-01-15    │
└────────────────────────┘
```

### Device Lookup by Code

```
Input: DEV-ABC123456789
   │
   ▼
Query device_management table
WHERE device_code = 'DEV-ABC123456789'
   │
   ▼
Return:
┌────────────────────────┐
│ ID: 456f7890           │
│ Name: John's iPhone    │
│ Type: Mobile           │
│ Model: iPhone 14       │
│ OS: iOS 17.0           │
│ Member: TM-ABC12345    │
│ Status: Approved ✓     │
│ Features: 6/8 selected │
│ Created: 2024-01-20    │
└────────────────────────┘
```

---

## 📋 Activity Log Timeline

### Member Activity Example

```
Timeline of John Smith (TM-ABC12345)

2024-01-25 14:32  ✅ Dashboard accessed
2024-01-25 14:15  ✅ Invoice #INV-1234 created
2024-01-25 13:45  ✅ Job JOB-567 marked complete
2024-01-25 13:20  ✅ Expense logged ($125)
2024-01-25 12:50  ✅ Time logged (2 hours)
2024-01-24 16:30  ✅ Member approved by CEO
2024-01-24 10:15  ✅ Invitation sent
```

### Device Access Log Example

```
Timeline of John's iPhone (DEV-ABC123456789)

2024-01-25 14:32  📱 App opened
2024-01-25 14:15  📊 Dashboard accessed
2024-01-25 13:45  📝 Job list viewed
2024-01-25 13:20  📤 Expense photo uploaded
2024-01-24 18:00  📱 App closed
2024-01-24 17:30  📱 Device approved
2024-01-24 16:45  📱 Device registered
```

---

## 🎯 Summary

**Complete visual reference** for:
- System architecture
- Data flows
- Approval processes
- Permission matrix
- Device features
- Code patterns
- Status transitions
- Activity timelines

**All diagrams are:** Accurate, Clear, Production-Ready

---

*Visual guide for AuraSphere CRM Organization Management*
