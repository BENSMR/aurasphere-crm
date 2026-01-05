# 🧪 FULL APP TEST GUIDE - AuraSphere CRM

**Status**: App is launching in Chrome (debug mode)  
**Date**: January 2, 2026  
**Version**: Latest with updated pricing plans

---

## 📋 FULL APP TEST CHECKLIST

### STEP 1: Landing Page (First Screen)
When app opens, you should see:

**Expected Content**:
- [ ] AuraSphere logo/header
- [ ] "🎉 7 Days Free Trial - No Credit Card Required" banner
  - ❌ OLD (incorrect): "3 Days Free Trial"
  - ✅ NEW (correct): "7 Days Free Trial"
- [ ] Navigation buttons: "Get Started", "Learn More", etc.
- [ ] Marketing copy highlighting features
- [ ] Responsive design (test on different sizes)

**Actions to test**:
- Click "Get Started" or similar CTA button
- Scroll down to see features list

---

### STEP 2: Pricing Page
Click on pricing/plan selection button

**Expected to see - 3 Plan Cards**:

#### Solo Plan Card
- **Title**: Solo
- **Price**: ✅ $9.99/month (was $20)
- **Users**: 1
- **Jobs/Month**: ✅ 25 (was 30)
- **Description**: Includes all core features
- **Color**: Blue

#### Team Plan Card
- **Title**: Team
- **Price**: ✅ $15/month (was $20)
- **Users**: 3
- **Jobs/Month**: ✅ 60 (was 120)
- **Description**: For growing teams
- **Color**: Indigo

#### Workshop Plan Card
- **Title**: Workshop
- **Price**: $49/month ✓
- **Users**: 7
- **Jobs/Month**: Unlimited ✓
- **Description**: For larger operations
- **Color**: Purple

**Trial & Discount Banner**:
```
✅ "🎉 Start with 7 days FREE • No credit card required!"
(was: "3 days FREE")

✅ "After trial ends, get 50% off for your first 2 months of any plan"
```

**Feature Comparison Table**:
| Feature | Solo | Team | Workshop |
|---------|------|------|----------|
| Jobs/Month | **25** ✅ | **60** ✅ | Unlimited ✓ |
| Team Members | 1 ✓ | 3 ✓ | 7 ✓ |
| All other features | ✓ | ✓ | ✓ |

---

### STEP 3: Sign In / Authentication
- [ ] Click "Get Started" or "Sign In"
- [ ] Should redirect to login page
- [ ] Enter test credentials (or create account)
- [ ] Check that auth guard works

---

### STEP 4: Dashboard (Post-Login)
Once logged in, you should see:

- [ ] Main dashboard/home page
- [ ] Navigation menu/sidebar
- [ ] Your organization name
- [ ] Trial status (if in trial: "7 days remaining")
- [ ] Plan information showing selected plan
- [ ] Bottom navigation tabs (Jobs, Clients, Invoices, etc.)

---

### STEP 5: Feature Pages (Click Each Tab)
Test each section of the app:

#### Jobs Tab
- [ ] Can see job list
- [ ] Create new job button works
- [ ] Job details display correctly

#### Clients Tab
- [ ] Client list displays
- [ ] Can add/edit clients
- [ ] Contact information shows

#### Invoices Tab
- [ ] Invoice list visible
- [ ] Can create invoice
- [ ] Invoice preview works

#### Inventory Tab
- [ ] Inventory items listed
- [ ] Can add/edit inventory
- [ ] Stock levels display

#### Team Tab
- [ ] Team members visible
- [ ] Shows max users for plan:
  - Solo: 1 user limit
  - Team: 3 users limit
  - Workshop: 7 users limit
- [ ] Can add team members (within limit)
- [ ] Remove members works

#### Dispatch/Scheduling Tab (if available)
- [ ] Calendar/scheduling loads
- [ ] Can assign jobs to team

#### Analytics/Performance Tab
- [ ] Reports display
- [ ] Charts load correctly
- [ ] Data shows

---

### STEP 6: Plan Information Page
Look for settings or account page:

- [ ] Current plan displayed (should show Solo, Team, or Workshop)
- [ ] Billing section shows:
  - [ ] Trial status (if applicable)
  - [ ] Next billing date
  - [ ] Amount due
- [ ] Upgrade/downgrade buttons work
- [ ] 50% discount message displays (if in discount period)

---

### STEP 7: Responsive Design Test
Test on different screen sizes:

**Desktop (1920px)**:
- [ ] All content visible
- [ ] Navigation horizontal/sidebar
- [ ] Forms laid out properly
- [ ] Tables readable

**Tablet (768px)**:
- [ ] Content reflows
- [ ] Buttons still clickable
- [ ] No horizontal scroll needed
- [ ] Plans displayed well

**Mobile (375px)**:
- [ ] Everything stacks vertically
- [ ] Navigation becomes hamburger menu
- [ ] Touch targets large enough
- [ ] Pricing cards stack

---

### STEP 8: Performance Test
- [ ] App loads in < 5 seconds
- [ ] Page transitions are smooth
- [ ] No console errors (F12 → Console)
- [ ] No broken images
- [ ] Animations smooth (not janky)

---

### STEP 9: Trial System Test (Advanced)
If you can access admin/settings:

- [ ] Trial end date set to 7 days from creation
- [ ] Countdown displays correctly
- [ ] Discount triggers after trial ends
- [ ] 50% discount applies to billing

---

### STEP 10: Payment System (Advanced)
- [ ] Paddle integration ready (API keys not yet configured)
- [ ] Payment buttons visible
- [ ] Checkout URLs ready for Paddle (post-launch configuration)

---

## ✅ CRITICAL SUCCESS CRITERIA

**Must pass for launch**:
- ✅ Trial shows "7 Days" (not "3 Days")
- ✅ Solo shows 25 jobs (not 30)
- ✅ Team shows $15 (not $20)
- ✅ Team shows 60 jobs (not 120)
- ✅ Workshop unchanged: $49, 7 users, unlimited
- ✅ No console errors
- ✅ App responsive on mobile/tablet
- ✅ Auth system works
- ✅ All tabs/pages load

---

## 🐛 IF YOU SEE ISSUES

### Still Showing Old Prices?
**Solution**: 
1. Press `Ctrl + Shift + Delete` (clear browser cache)
2. Select "All time" → Clear data
3. Refresh page `Ctrl + F5`
4. If still old: Close Chrome completely, then `flutter run -d chrome` again

### App Won't Load?
**Solution**:
1. Check browser console: Press `F12` → Console tab
2. Look for red error messages
3. Copy error and share with developer

### Pricing Page Blank?
**Solution**:
1. Go back to home page
2. Click pricing button again
3. Check console (F12) for JS errors
4. Hard refresh with `Ctrl + F5`

### Trial Shows Wrong Duration?
**Check**:
- Source code has `Duration(days: 7)` ✅ (already verified)
- Browser cache cleared ✅
- Hard refresh done ✅
- If still wrong: Contact dev

---

## 📸 TESTING NOTES

**Record these results**:
1. Screenshot of landing page with "7 Days Free Trial" ✓
2. Screenshot of pricing page showing:
   - Solo: $9.99, 25 jobs
   - Team: $15, 60 jobs
   - Workshop: $49, unlimited
3. Screenshot of feature table with correct numbers
4. Console output (should have no errors) - F12 → Console
5. Test on tablet and mobile (screenshot at least one)

---

## 🎯 FINAL SIGN-OFF

Once you've tested all items above:

- [ ] All critical criteria met
- [ ] No console errors
- [ ] Responsive design works
- [ ] All features functional
- [ ] Ready for production deployment

---

**App Status**: 🟢 **READY FOR TESTING**

**Current Time**: The app is running in Chrome debug mode  
**Next**: Test using this checklist  
**Duration**: ~15-20 minutes for complete test

---

*Report back with results and any issues found!*
