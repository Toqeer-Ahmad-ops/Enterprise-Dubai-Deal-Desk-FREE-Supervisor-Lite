-- ============================================================
-- Day 12 - Idempotency Fix
-- File: 02-day12-idempotency-fix.sql
-- Goal: 1st run in same hour -> Telegram
--       2nd run in same hour -> Set Skipped, 0 Spam
-- Key: UNIQUE(lead_id, alert_type, hour, channel)
-- Index name: ux_notification_log_hour
-- Notes:
--  - notification_log had NO hour column in information_schema.
--    This file ADDS it. Do not re-run CREATE TABLE for it.
--  - hour = Dubai hour bucket: 'YYYY-MM-DD HH24:00'
--    e.g. '2026-11-11 09:00' for 09:10 / 09:15 / 09:20 Dubai runs.
--  - lead_id is TEXT in notification_log (EXP-1201, ORD-8821, lead uuid as text)
--  - n8n Check Duplicate node must query with the SAME hour format.
-- ============================================================

-- 1) Add hour column if missing
alter table public.notification_log
  add column if not exists hour text null;

-- 2) Backfill hour from sent_at (Asia/Dubai) for old rows
update public.notification_log
set hour = to_char(sent_at at time zone 'Asia/Dubai', 'YYYY-MM-DD HH24:00')
where hour is null
  and sent_at is not null;

-- 3) Deduplicate any pre-existing duplicates before creating UNIQUE index
--    Keeps the earliest row per (lead_id, alert_type, hour, channel)
--    Run this once, check the count, then create the index below.
-- delete from public.notification_log a using public.notification_log b
-- where a.id > b.id
--   and a.lead_id is not distinct from b.lead_id
--   and a.alert_type = b.alert_type
--   and a.hour is not distinct from b.hour
--   and a.channel = b.channel;

-- 4) UNIQUE index = idempotency gate
create unique index if not exists ux_notification_log_hour
  on public.notification_log (lead_id, alert_type, hour, channel);

-- 5) Helpful index for Check Duplicate query (same order as UNIQUE)
create index if not exists idx_notification_log_check_duplicate
  on public.notification_log (lead_id, alert_type, hour, channel);

-- ------------------------------------------------------------
-- 6) What n8n does - Check Duplicate (Supabase node / SQL)
-- Run BEFORE Telegram. If a row is found -> IF Duplicate -> Set Skipped.
-- Hour in n8n must be built the SAME way:
--   {{ $now.setZone('Asia/Dubai').toFormat('yyyy-MM-dd HH:00') }}
-- Example check (replace $1..$4 with n8n values):
-- ------------------------------------------------------------
-- select id, sent_at
-- from public.notification_log
-- where lead_id = $1        -- e.g. 'EXP-1201' / 'ORD-8821' / lead_id as text
--   and alert_type = $2     -- e.g. 'finance_expense_approval' / 'order_exception' / 're_leads_audit'
--   and hour = $3           -- e.g. '2026-11-11 09:00'
--   and channel = $4        -- e.g. 'telegram'
-- limit 1;

-- ------------------------------------------------------------
-- 7) What n8n does - Log Notification (AFTER Telegram, only if not duplicate)
-- Insert with ON CONFLICT DO NOTHING as a second safety net.
-- ------------------------------------------------------------
-- insert into public.notification_log
--   (lead_id, alert_type, channel, business_type, hour, telegram_message_id, payload, sent_at)
-- values ($1, $2, 'telegram', $3, $4, $5, $6::jsonb, now())
-- on conflict (lead_id, alert_type, hour, channel) do nothing;

-- Verification:
-- 1st run in hour  -> 1 row, Telegram = 1
-- 2nd run same hour -> 0 new rows, n8n = Set Skipped, Telegram = 0
-- select lead_id, alert_type, hour, channel, count(*)
-- from public.notification_log group by 1,2,3,4 having count(*) > 1;
-- ^ Must return 0 rows after the UNIQUE index exists.
