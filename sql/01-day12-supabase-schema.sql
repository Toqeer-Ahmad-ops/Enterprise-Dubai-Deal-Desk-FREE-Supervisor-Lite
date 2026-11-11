-- ============================================================
-- Day 12 - Supabase Schema
-- Project: Retail-SOP (generic / demo)
-- File: 01-day12-supabase-schema.sql
-- Tables: notification_log + approval_queue + sla_alert_log
-- View: v_deployments_dashboard
-- Notes:
--  - RLS disabled for demo tables in Day 12.
--  - No secrets, no URLs, no service_role keys in this file.
--  - Column names / types match Supabase information_schema
--    output exactly. Do NOT rename columns - n8n nodes depend on them.
--  - leads, finance_expenses_sim, ecom_orders_sim, error_logs
--    already exist in the project and are NOT re-created here.
--    notification_log.lead_id is TEXT on purpose: it holds
--    RE lead_id (uuid as text) + EXP-1201 + ORD-8821.
-- ============================================================

-- Required for gen_random_uuid()
create extension if not exists "pgcrypto";

-- ------------------------------------------------------------
-- 1) notification_log - idempotency + send audit
-- ------------------------------------------------------------
create table if not exists public.notification_log (
  id uuid not null primary key default gen_random_uuid(),
  lead_id text null,
  alert_type text not null,
  channel text not null,
  business_type text not null,
  telegram_message_id text null,
  gmail_message_id text null,
  payload jsonb null,
  sent_at timestamptz not null default now(),
  created_at timestamptz null default now()
);

create index if not exists idx_notification_log_sent_at
  on public.notification_log (sent_at desc);
create index if not exists idx_notification_log_business_type
  on public.notification_log (business_type, sent_at desc);
create index if not exists idx_notification_log_alert_type
  on public.notification_log (alert_type, sent_at desc);

-- ------------------------------------------------------------
-- 2) approval_queue - human approval: pending -> approved / rejected
-- ------------------------------------------------------------
create table if not exists public.approval_queue (
  id uuid not null primary key default gen_random_uuid(),
  lead_id uuid null,
  alert_type text not null,
  business_type text not null,
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'rejected')),
  requires_approval boolean not null default true,
  requested_at timestamptz not null default now(),
  decided_at timestamptz null,
  decided_by text null
);

create index if not exists idx_approval_queue_status
  on public.approval_queue (status, requested_at desc);
create index if not exists idx_approval_queue_business_type
  on public.approval_queue (business_type, status);

-- ------------------------------------------------------------
-- 3) sla_alert_log - SLA breach alerts
-- ------------------------------------------------------------
create table if not exists public.sla_alert_log (
  id uuid not null primary key default gen_random_uuid(),
  lead_id uuid not null,
  alert_type text not null,
  sent_at timestamptz not null default now(),
  gmail_message_id text null,
  channel text null,
  external_id text null,
  delivery_status text null,
  business_type text null,
  payload jsonb null
);

create index if not exists idx_sla_alert_log_sent_at
  on public.sla_alert_log (sent_at desc);
create index if not exists idx_sla_alert_log_lead_id
  on public.sla_alert_log (lead_id, sent_at desc);

-- ------------------------------------------------------------
-- 4) v_deployments_dashboard - dashboard view for Telegram / n8n
-- Uses only columns that exist in the 3 tables above.
-- Grain: one row per business_type + day (Asia/Dubai) + channel
-- ------------------------------------------------------------
create or replace view public.v_deployments_dashboard as
select
  n.business_type,
  (n.sent_at at time zone 'Asia/Dubai')::date as day_dubai,
  n.channel,
  count(*) as notifications_sent,
  count(distinct n.lead_id) as distinct_leads_notified,
  count(distinct n.alert_type) as distinct_alert_types,
  max(n.sent_at) as last_sent_at
from public.notification_log n
group by
  n.business_type,
  (n.sent_at at time zone 'Asia/Dubai')::date,
  n.channel;

-- Quick check (run in Supabase SQL Editor):
-- select * from public.v_deployments_dashboard order by day_dubai desc, business_type limit 20;
