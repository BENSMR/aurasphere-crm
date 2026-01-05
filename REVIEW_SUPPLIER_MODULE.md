# GitHub Copilot Review Prompt - Supplier Management Module

You are a **senior engineering architect** reviewing the **Supplier Management Module** for AuraSphere CRM. Analyze this feature pack and provide **concrete, production-focused feedback**:

## 📦 **Feature Summary**
- **8 Supabase tables** with RLS + 15+ constraints
- **Autonomous AI Agent** (Edge Function) for:
  • Supplier health scoring (0-100)
  • Price comparison with quantity breaks
  • Delivery delay prediction
  • Reorder suggestions
- **Full UI**: 5 tabs (Dashboard, Suppliers, Pricing, POs, AI Insights)
- **Zero breaking changes** to existing app
- **Documentation**: 2,240 lines (quick start → deployment)

## 🔍 **Review Focus Areas**

### 1. **Security**
- Are RLS policies sufficient for multi-tenancy?
- Any risk of API key exposure in Edge Function?

### 2. **Reliability**
- How to prevent Edge Function abuse (e.g., infinite AI triggers)?
- Missing validation constraints in POs/suppliers?

### 3. **Performance**
- Critical missing indexes for AI queries?
- Cold start mitigation for Deno functions?

### 4. **UX**
- Loading states for initial AI analysis?
- Error handling for supplier data gaps?

### 5. **Business Value**
- Are the claimed 15-30% cost savings realistic?
- Missing high-impact features (e.g., risk alerts)?

## 🚫 **Strict Rules**
- **NO generic praise** — only actionable fixes
- **Cite specific files/lines** (e.g., "In `index.ts` line 45...")
- **Prioritize by severity**: Critical → High → Medium
- **Include exact code snippets** for fixes

## 📋 **Expected Output Format**

```markdown
### 🔴 Critical Issues (Blockers)
- [ ] **Issue**: ...
  **File**: ...
  **Fix**: ...

### 🟠 High-Impact Improvements
- [ ] **Issue**: ...
  **File**: ...
  **Fix**: ...

### 🟢 Post-Launch Opportunities
- [ ] **Feature**: ...
  **Business Impact**: ...
```

---

## 💡 **How to Use This File**

1. **In VS Code**: Right-click on this file → **"Ask Copilot"**
2. **Paste**: Copy the entire content above (Feature Summary through Expected Output Format)
3. **Command**: Say *"Review this supplier module following the spec"*
4. Copilot will output a **prioritized, file-specific action plan** — no fluff, just engineering rigor.

**This turns your excellent module into a production fortress.** 💪
