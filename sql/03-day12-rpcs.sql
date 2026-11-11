-- ============================================================
-- Day 12 - RPCs (Postgres Functions called from n8n Supabase node)
-- File: 03-day12-rpcs.sql
-- Functions:
--  - get_daily_ops_metrics()
--  - get_top_action_leads(p_limit int)
--  - get_sla_breached_leads(p_limit int)
-- Notes:
--  - Uses ONLY columns that exist in information_schema output.
--  - leads.created_at / updated_at are timestamp WITHOUT time zone.
--  - leads.follow_up_due_at / last_sla_alert_at are timestamptz.
--  - lead_score is integer. Bands: Hot >= 80, Warm 50-79, Cold < 50.
--  - No secrets. RLS disabled for demo in Day 12.
-- ============================================================

-- ------------------------------------------------------------
-- 1) get_daily_ops_metrics() - Day12-01 RE Leads Audit
-- Returns one row per day (Dubai) with counts for the Telegram digest.
-- ------------------------------------------------------------
create or replace function public.get_daily_ops_metrics()
returns table (
  day_dubai date,
  total_leads bigint,
  hot_leads bigint,
  warm_leads bigint,
  cold_leads bigint,
  leads_today bigint,
  sla_breach_leads bigint,
  notifications_today bigint
)
language sql
stable
as $$
  with lead_stats as (
    select
      (l.created_at at time zone 'Asia/Dubai')::date as day_dubai,
      count(*) as total_leads,
      count(*) filter (where coalesce(l.lead_score, 0) >= 80) as hot_leads,
      count(*) filter (where coalesce(l.lead_score, 0) between 50 and 79) as warm_leads,
      count(*) filter (where coalesce(l.lead_score, 0) < 50) as cold_leads,
      count(*) filter (where (l.created_at at time zone 'Asia/Dubai')::date = (now() at time zone 'Asia/Dubai')::date) as leads_today,
      count(*) filter (where coalesce(l.sla_breach_count, 0) > 0) as sla_breach_leads
    from public.leads l
    group by (l.created_at at time zone 'Asia/Dubai')::date
  ),
  notif_today as (
    select count(*) as notifications_today
    from public.notification_log n
    where (n.sent_at at time zone 'Asia/Dubai')::date = (now() at time zone 'Asia/Dubai')::date
  )
  select
    s.day_dubai,
    s.total_leads,
    s.hot_leads,
    s.warm_leads,
    s.cold_leads,
    s.leads_today,
    s.sla_breach_leads,
    (select notifications_today from notif_today) as notifications_today
  from lead_stats s
  order by s.day_dubai desc
  limit 30;
$$;

-- ------------------------------------------------------------
-- 2) get_top_action_leads(p_limit int) - Top N leads to act on now
-- Ordered by lead_score DESC, then created_at DESC.
-- Used by Day12-01 Formatter Generic (EN/AR) for Top 5.
-- ------------------------------------------------------------
create or replace function public.get_top_action_leads(p_limit int default 5)
returns table (
  id uuid,
  lead_id uuid,
  name text,
  phone text,
  email text,
  lead_score int,
  qualification_status text,
  routing_reason text,
  owner text,
  status text,
  language text,
  created_at timestamp without time zone,
  follow_up_due_at timestamptz,
  sla_breach_count int
)
language sql
stable
as $$
  select
    l.id,
    l.lead_id,
    l.name,
    l.phone,
    l.email,
    l.lead_score,
    l.qualification_status,
    l.routing_reason,
    l.owner,
    l.status,
    l.language,
    l.created_at,
    l.follow_up_due_at,
    l.sla_breach_count
  from public.leads l
  where coalesce(l.lead_score, 0) >= 50
  order by l.lead_score desc nulls last, l.created_at desc nulls last
  limit greatest(1, least(coalesce(p_limit, 5), 20));
$$;

-- ------------------------------------------------------------
-- 3) get_sla_breached_leads(p_limit int) - SLA breached / overdue follow-up
-- Breach = follow_up_due_at in past AND not responded
--          OR sla_breach_count > 0
-- Used by Day12-01 SLA section + sla_alert_log.
-- ------------------------------------------------------------
create or replace function public.get_sla_breached_leads(p_limit int default 10)
returns table (
  id uuid,
  lead_id uuid,
  name text,
  phone text,
  lead_score int,
  routing_reason text,
  owner text,
  status text,
  follow_up_due_at timestamptz,
  last_sla_alert_at timestamptz,
  sla_breach_count int,
  responded boolean
)
language sql
stable
as $$
  select
    l.id,
    l.lead_id,
    l.name,
    l.phone,
    l.lead_score,
    l.routing_reason,
    l.owner,
    l.status,
    l.follow_up_due_at,
    l.last_sla_alert_at,
    l.sla_breach_count,
    l.responded
  from public.leads l
  where (
    (l.follow_up_due_at is not null and l.follow_up_due_at < now() and coalesce(l.responded, false) = false)
    or coalesce(l.sla_breach_count, 0) > 0
  )
  order by l.follow_up_due_at asc nulls last, l.lead_score desc nulls last
  limit greatest(1, least(coalesce(p_limit, 10), 50));
$$;

-- Verification (run in Supabase SQL Editor):
-- select * from public.get_daily_ops_metrics() limit 5;
-- select * from public.get_top_action_leads(5);
-- select * from public.get_sla_breached_leads(10);
