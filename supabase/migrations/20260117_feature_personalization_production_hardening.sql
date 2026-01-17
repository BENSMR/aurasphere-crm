-- Feature Personalization Production Hardening
-- Migration: 20260117_feature_personalization_production_hardening.sql
-- 
-- Key improvements:
-- - Add helper functions (is_org_owner, is_org_member) for safer RLS
-- - Fix FK nullability issues
-- - Add feature count validation triggers
-- - Convert audit log details to JSONB
-- - Add indexes supporting RLS and common filters
-- - Replace auth.role() checks with actual org membership checks
-- - More granular RLS policies for different user roles
--
-- Apply this AFTER: 20260117_add_feature_personalization.sql

-- ============================================================================
-- 1) Helper Functions: is_org_owner + is_org_member
-- ============================================================================

create or replace function public.is_org_owner(p_org_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.organizations o
    where o.id = p_org_id
      and o.owner_id = auth.uid()
  );
$$;

create or replace function public.is_org_member(p_org_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.org_members m
    where m.org_id = p_org_id and m.user_id = auth.uid()
  ) or exists (
    -- Owners are implicitly members
    select 1 from public.organizations o
    where o.id = p_org_id and o.owner_id = auth.uid()
  );
$$;

-- Restrict execution to postgres and admin only (services use service_role which bypasses RLS)
revoke execute on function public.is_org_owner(uuid) from anon, authenticated;
revoke execute on function public.is_org_member(uuid) from anon, authenticated;
grant execute on function public.is_org_owner(uuid) to postgres, supabase_admin;
grant execute on function public.is_org_member(uuid) to postgres, supabase_admin;

-- ============================================================================
-- 2) Devices Table: Fix FK nullability + add trigger for registered_by
-- ============================================================================

-- Make registered_by nullable to match ON DELETE SET NULL behavior
alter table public.devices
  alter column registered_by drop not null;

-- Trigger: Auto-set registered_by to current user if not provided
create or replace function public.set_registered_by_default()
returns trigger
language plpgsql
as $$
begin
  if new.registered_by is null then
    new.registered_by := auth.uid();
  end if;
  return new;
end;
$$;

drop trigger if exists trg_devices_registered_by_default on public.devices;
create trigger trg_devices_registered_by_default
  before insert on public.devices
  for each row
  execute function public.set_registered_by_default();

-- Trigger: Auto-set updated_at timestamp
drop trigger if exists update_devices_updated_at on public.devices;
create trigger update_devices_updated_at
  before update on public.devices
  for each row
  execute function public.update_updated_at_column();

-- ============================================================================
-- 3) Feature Personalization: Add feature count validation
-- ============================================================================

create or replace function public.check_feature_limits()
returns trigger
language plpgsql
as $$
declare
  feature_count int;
begin
  if new.selected_features is null then
    return new;
  end if;

  feature_count := coalesce(array_length(new.selected_features, 1), 0);

  if new.device_type = 'mobile' and feature_count > 6 then
    raise exception 'Mobile devices can have at most 6 features';
  elsif new.device_type = 'tablet' and feature_count > 8 then
    raise exception 'Tablet devices can have at most 8 features';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_feature_limits on public.feature_personalization;
create trigger trg_feature_limits
  before insert or update on public.feature_personalization
  for each row
  execute function public.check_feature_limits();

-- ============================================================================
-- 4) Feature Audit Log: Convert details to JSONB for structured queries
-- ============================================================================

alter table public.feature_audit_log
  alter column details type jsonb using
    case
      when details is null then null
      when details ~ '^[\\s\\t\\n\\r]*\\{' then details::jsonb
      else jsonb_build_object('message', details)
    end;

-- ============================================================================
-- 5) Indexes Supporting RLS and Common Filters
-- ============================================================================

-- Devices: Quick lookup by org and active status
create index if not exists idx_devices_org_active 
  on public.devices(org_id, is_active);

-- Feature personalization: RLS predicate + common lookups
create index if not exists idx_feature_pers_user_org_device 
  on public.feature_personalization(user_id, org_id, device_type);

-- Audit log: RLS predicate + timestamp for sorting
create index if not exists idx_feature_audit_log_org_ts 
  on public.feature_audit_log(org_id, timestamp);

-- ============================================================================
-- 6) RLS Policies: Replace auth.role() with org membership checks
-- ============================================================================

-- --- Devices Table ---

drop policy if exists "Users can view devices in their org" on public.devices;
drop policy if exists "Owners can register devices for their org" on public.devices;
drop policy if exists "Owners can update devices in their org" on public.devices;
drop policy if exists "Owners can delete devices in their org" on public.devices;
drop policy if exists "Authenticated users view devices" on public.devices;

-- SELECT: org members (including owner) can view devices
create policy "org members can view devices"
  on public.devices
  for select
  to authenticated
  using (public.is_org_member(org_id));

-- INSERT: only org owner can register new devices
create policy "owners can insert devices"
  on public.devices
  for insert
  to authenticated
  with check (public.is_org_owner(org_id));

-- UPDATE: only org owner can modify devices
create policy "owners can update devices"
  on public.devices
  for update
  to authenticated
  using (public.is_org_owner(org_id))
  with check (public.is_org_owner(org_id));

-- DELETE: only org owner can delete devices
create policy "owners can delete devices"
  on public.devices
  for delete
  to authenticated
  using (public.is_org_owner(org_id));

-- --- Feature Personalization Table ---

drop policy if exists "Users can view their own features" on public.feature_personalization;
drop policy if exists "Users can update own features if not enforced" on public.feature_personalization;
drop policy if exists "Users can insert own features" on public.feature_personalization;
drop policy if exists "Authenticated users view features" on public.feature_personalization;
drop policy if exists "Users can delete own feature rows" on public.feature_personalization;

-- SELECT: users see their own rows; owner sees all rows in org
create policy "users see own feature rows"
  on public.feature_personalization
  for select
  to authenticated
  using (auth.uid() = user_id);

create policy "owner sees org feature rows"
  on public.feature_personalization
  for select
  to authenticated
  using (public.is_org_owner(org_id));

-- INSERT: users insert only for themselves in their org
create policy "users insert own feature rows"
  on public.feature_personalization
  for insert
  to authenticated
  with check (
    auth.uid() = user_id 
    and public.is_org_member(org_id)
  );

-- UPDATE: users update own row if not enforced by owner; owner can update any
create policy "users update own if not enforced"
  on public.feature_personalization
  for update
  to authenticated
  using (
    auth.uid() = user_id 
    and is_owner_enforced = false
  )
  with check (
    auth.uid() = user_id 
    and is_owner_enforced = false
  );

create policy "owner updates any in org"
  on public.feature_personalization
  for update
  to authenticated
  using (public.is_org_owner(org_id))
  with check (public.is_org_owner(org_id));

-- DELETE: owner-only (users cannot delete their own rows)
create policy "owner deletes in org"
  on public.feature_personalization
  for delete
  to authenticated
  using (public.is_org_owner(org_id));

-- --- Feature Audit Log Table ---

drop policy if exists "Only org owner can view audit log" on public.feature_audit_log;
drop policy if exists "Services can insert audit logs" on public.feature_audit_log;
drop policy if exists "Authenticated users cannot see audit logs" on public.feature_audit_log;

-- SELECT: org owner only (audit logs are sensitive)
create policy "owner view audit log"
  on public.feature_audit_log
  for select
  to authenticated
  using (public.is_org_owner(org_id));

-- INSERT: allow from authenticated (edge functions, service layer)
-- This is safe because we check org_member before insert
create policy "insert audit logs with org"
  on public.feature_audit_log
  for insert
  to authenticated
  with check (
    org_id is not null 
    and public.is_org_member(org_id)
  );

-- ============================================================================
-- 7) Verify RLS is enabled on all tables
-- ============================================================================

alter table public.devices enable row level security;
alter table public.feature_personalization enable row level security;
alter table public.feature_audit_log enable row level security;

-- ============================================================================
-- 8) Add comments for documentation
-- ============================================================================

comment on function public.is_org_owner(uuid) is 
  'Check if current user is owner of given organization. SECURITY DEFINER: only for postgres/admin.';

comment on function public.is_org_member(uuid) is 
  'Check if current user is member of given organization (includes owners). SECURITY DEFINER: only for postgres/admin.';

comment on function public.set_registered_by_default() is 
  'Auto-set registered_by to current user (auth.uid()) if not provided at insert time.';

comment on function public.check_feature_limits() is 
  'Enforce database-level feature count limits: mobile max 6, tablet max 8.';

comment on table public.devices is 
  'Device registration with multi-tenant support. Ownership controlled by org_id + RLS policies.';

comment on table public.feature_personalization is 
  'User feature selection per device. Enforcement status and audit fields track owner control.';

comment on table public.feature_audit_log is 
  'Audit trail for feature management changes. Visible to org owner only via RLS.';

-- ============================================================================
-- Summary
-- ============================================================================

-- This migration improves:
-- ✅ RLS safety: replaced auth.role() checks with actual org membership verification
-- ✅ Data integrity: feature count validation at DB level, prevents client bypass
-- ✅ Performance: new indexes align with RLS predicates for faster policy evaluation
-- ✅ Auditability: structured JSONB for richer audit trail querying
-- ✅ Maintainability: helper functions reduce RLS complexity and centralize logic
-- ✅ Compliance: tighter access control matching Supabase best practices
--
-- Verify deployment:
-- 1. As org owner: can view all devices, feature_personalization, and audit logs in their org
-- 2. As org member: can view devices and own feature_personalization, cannot see audit logs
-- 3. As unauthorized user: cannot access any org data
-- 4. Feature count validation: attempt to add 7+ features to mobile device will be rejected
