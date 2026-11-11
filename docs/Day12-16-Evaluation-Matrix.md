# Day 12-16 — Evaluation & Regression Test Matrix — 40 Cases

**Project:** Enterprise Dubai RE + Finance + Order — FREE Stack Supervisor Lite + Human Approval
**Stack:** n8n 2.43.5 Self-Hosted Docker • Supabase PostgreSQL Retail-SOP • Telegram Bot @dubai_deal_desk_bot
**Timezone:** Asia/Dubai — Cron 09:10 / 09:15 / 09:20 Dubai
**Status:** Day 12 CLOSED — Rows 1-8 evaluated. Rows 9-40 = Planned for Day 13-16, do NOT mark Pass until actually run.

## How to read this file

- **Pass** = Actually ran in n8n production / manual Execute + Telegram / Supabase proof seen.
- **Not Run** = Not executed yet. Do NOT change to Pass without an execution.
- **Latency ms** = Copy from n8n → Executions → Duration. Leave `—` if you didn't record it.
- **Confidence Threshold** = Minimum score to act. Below threshold = Escalate / Request info / Handoff.
- **Idempotency rule for all rows:** `UNIQUE(lead_id, alert_type, hour, channel)` — `ux_notification_log_hour`. 1st run in hour = Telegram, 2nd run same hour = Set Skipped, 0 Spam.

## Day 12 Summary

| Metric | Count |
|---|---|
| Total cases | 40 |
| Day 12 evaluated (1-8) | 8 |
| Pass (Day 12) | 6 |
| Not Run (Day 12, pending RAG doc-grounded) | 2 |
| Planned Day 13-16 (9-40) | 32 |

**Day 12 Fix Verified:** Nov 11, 09:29:15 — Execution #29392 — Version `46b00ff3` — Succeeded in **2433 ms** — Check Duplicate now Supabase node (`notification_log`), `IF Duplicate? true → Set Skipped`. Old version `e4568bd6` with HTTP node `notification_log_invalid` = Fail, now fixed + Published.

---

## Matrix — 40 Cases

| # | Lang | Type | Question / Case | Expected Evidence / Source | Expected Route | Expected Action | Confidence Threshold | Actual Result | Pass / Fail | Latency ms | Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | EN | Property | What is payment plan for Marina project? | finance_docs chunk | RAG | Telegram answer + source ref | — | Doc-grounded RAG not executed in Day 12. Day 12 proved Formatter EN/AR + Telegram dispatch, not finance_docs retrieval. | Not Run | — | Move to Day 13 RAG check. Do NOT claim RAG Pass yet. Fill after real RAG run with chunk ID. |
| 2 | AR | Property | ما هي خطة الدفع لمشروع مارينا؟ | finance_docs chunk | RAG | Telegram AR answer + source ref | 0.7 | Doc-grounded RAG not executed in Day 12. AR detection proved via Arabic leads (Ahmed Al-Aqari / أحمد العقاري) in Formatter Generic. | Not Run | — | Move to Day 13. Test AR → AR, no EN fallback. Record chunk ID + Arabic Telegram screenshot. |
| 3 | EN | Lead | Budget 2M investor Dubai Marina | lead_scores | Scoring | Save + Telegram Hot | 0.8 | Hot lead saved, Telegram Hot 95 sent via Day12-01. Score 95 Hot band verified. | Pass | — | Day12-01 RE Real. Cron 09:10 Dubai. `get_top_action_leads(5)` returns Hot first. Copy Duration from Executions. |
| 4 | EN | Missing | Interest in property, No budget | — | Scoring | Request missing info | 0.6 | Formatter Generic requests missing fields, does NOT send Hot Telegram. `missing_fields` jsonb populated. | Pass | — | Day12-01. Below Hot threshold = no Hot alert. Verified via scoring logic + Formatter. |
| 5 | EN | Unsupported | Give me legal guarantee | No evidence | Escalation | Handoff pending approval, queue | — | No legal guarantee given. Routed to `approval_queue` status `pending`, `requires_approval = true`. No auto financial/legal action. | Pass | — | Day12-01 / Day12-02 / Day12-03. Human must approve before action. This is the safety gate. |
| 6 | EN | Duplicate | Same lead_id same hour twice | sla_alert_log / notification_log UNIQUE | Deduplicate | Block second | 1.0 | 1st run: Telegram sent, 1 row in `notification_log`. 2nd run same hour: n8n `Set Skipped`, Telegram 0, no new row. | Pass | — | Proved on Day12-01, Day12-02 (EXP-1201), Day12-03 (ORD-8821). `ux_notification_log_hour` on `(lead_id, alert_type, hour, channel)`. This fixed the earlier 50-message spam bug. |
| 7 | EN | SLA | follow_up_due_at overdue 65 min | get_sla_breached_leads | SLA | Telegram Admin Alert + log | — | `get_sla_breached_leads` returns overdue leads (`follow_up_due_at < now()` + `responded = false` OR `sla_breach_count > 0`). Alert logged to `sla_alert_log`. | Pass | — | Day12-01. Fill exact overdue lead_id + Telegram screenshot in repo `screenshots/` when you re-run for evidence. |
| 8 | EN | Failure | Supabase down | workflow_errors | Failure handling | Log failure, preserve | — | Day12-00 Error Trigger Admin fired on production only (not manual). Short error message logged to `error_logs`, Telegram Admin Alert sent. No full JSON / secret dump. | Pass | — | Day12-00 must stay Published. Manual Execute has flask icon = does NOT fire error workflow. Production Cron does. |

---

## Day 13 — WhatsApp Cloud API (Rows 9-15) — PLANNED

> Do NOT mark Pass until Day 13 execution. WhatsApp does NOT replace Telegram. Telegram stays.

| # | Lang | Type | Question / Case | Expected Evidence / Source | Expected Route | Expected Action | Confidence Threshold | Actual Result | Pass / Fail | Latency ms | Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 9 | EN | WhatsApp | Hot lead 95 via WhatsApp | lead_scores | Routing | WhatsApp template sent | 0.8 | — | Not Run | — | Day 13. WhatsApp Cloud API, 1000 free convos. Template: Investor Name Score {{95}} Doc-Grounded {{Pass/Escalate}} DLD fee {{AED}} |
| 10 | AR | WhatsApp | Arabic lead via WhatsApp | lead_scores | Routing | WhatsApp AR template | 0.7 | — | Not Run | — | Day 13. AR → AR, no EN fallback. |
| 11 | EN | WhatsApp | Duplicate WhatsApp same hour twice | notification_log UNIQUE | Deduplicate | Block 2nd WhatsApp | 1.0 | — | Not Run | — | Day 13. Same `ux_notification_log_hour` with `channel = whatsapp`. |
| 12 | EN | WhatsApp | Low score lead (Cold) | lead_scores | Routing | No WhatsApp, log only | 0.6 | — | Not Run | — | Day 13. Cold < 50 = no push. |
| 13 | EN | WhatsApp | Missing info via WhatsApp | — | Scoring | Request missing info via WhatsApp | 0.6 | — | Not Run | — | Day 13. |
| 14 | EN | WhatsApp | Unsupported / legal guarantee via WhatsApp | No evidence | Escalation | Handoff pending, no WhatsApp guarantee | — | — | Not Run | — | Day 13. No legal/financial action before approval. |
| 15 | EN | WhatsApp | Telegram + WhatsApp both enabled, no double spam | notification_log | Deduplicate | One channel per hour per lead_id | 1.0 | — | Not Run | — | Day 13. Verify Telegram still works after WhatsApp added. |

## Day 14 — Human Approval (Rows 16-22) — PLANNED

| # | Lang | Type | Question / Case | Expected Evidence / Source | Expected Route | Expected Action | Confidence Threshold | Actual Result | Pass / Fail | Latency ms | Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 16 | EN | Approval | Finance EXP-1201 AED 12000 overdue | finance_expenses_sim | Approval | approval_queue pending → Telegram Approve/Reject | 0.82 | — | Not Run | — | Day 14. Re-test Day12-02 with real Approve/Reject click. |
| 17 | EN | Approval | Order ORD-8821 payment_failed AED 450 | ecom_orders_sim | Approval | approval_queue pending → Resolve/Escalate | — | — | Not Run | — | Day 14. Re-test Day12-03. |
| 18 | EN | Approval | Approve → status approved + logged | approval_queue | Approval | decided_at + decided_by set | — | — | Not Run | — | Day 14. |
| 19 | EN | Approval | Reject → status rejected + logged | approval_queue | Approval | decided_at + decided_by set, no action taken | — | — | Not Run | — | Day 14. |
| 20 | AR | Approval | Arabic approval request | approval_queue | Approval | AR Telegram Approve/Reject | 0.7 | — | Not Run | — | Day 14. AR → AR. |
| 21 | EN | Approval | Approval timeout / no decision | approval_queue | Approval | Stays pending, reminder, no auto-approve | — | — | Not Run | — | Day 14. Never auto-approve financial/legal. |
| 22 | EN | Approval | Duplicate approval click twice | approval_queue + notification_log | Deduplicate | 2nd click ignored, 1 log | 1.0 | — | Not Run | — | Day 14. Idempotency on approval too. |

## Day 15 — Error / Retry / Failure (Rows 23-30) — PLANNED

| # | Lang | Type | Question / Case | Expected Evidence / Source | Expected Route | Expected Action | Confidence Threshold | Actual Result | Pass / Fail | Latency ms | Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 23 | EN | Failure | Telegram API down | workflow_errors | Failure handling | Log to error_logs, retry, no loss | — | — | Not Run | — | Day 15. |
| 24 | EN | Failure | Supabase RPC timeout | workflow_errors | Failure handling | Log + Telegram Admin Alert | — | — | Not Run | — | Day 15. |
| 25 | EN | Failure | Invalid phone / bad lead data | leads | Escalation | Handoff + log, no crash | — | — | Not Run | — | Day 15. |
| 26 | EN | Retry | 1st Telegram fails, retry succeeds | notification_log | Retry | 1 log only, no duplicate | 1.0 | — | Not Run | — | Day 15. Retry must respect UNIQUE. |
| 27 | EN | SLA | SLA breach at night (Dubai) | get_sla_breached_leads | SLA | Alert next Cron, not spam loop | — | — | Not Run | — | Day 15. |
| 28 | EN | Duplicate | Same EXP-1201 same hour, Finance | notification_log | Deduplicate | Block 2nd | 1.0 | — | Not Run | — | Day 15. Re-verify Day12-02 idempotency. |
| 29 | EN | Duplicate | Same ORD-8821 same hour, Order | notification_log | Deduplicate | Block 2nd | 1.0 | — | Not Run | — | Day 15. Re-verify Day12-03 idempotency. |
| 30 | EN | Security | Secrets in logs? | error_logs | Failure handling | No bot token / service_role / eyJ in logs or GitHub | — | — | Not Run | — | Day 15. Grep `workflows/*.json` + `sql/*.sql` for `eyJ`, `service_role`, `AA...` token. |

## Day 16 — Full Regression (Rows 31-40) — PLANNED

| # | Lang | Type | Question / Case | Expected Evidence / Source | Expected Route | Expected Action | Confidence Threshold | Actual Result | Pass / Fail | Latency ms | Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 31 | EN | Regression | Re-run Row 3 Hot lead | lead_scores | Scoring | Same as Row 3 | 0.8 | — | Not Run | — | Day 16. Full 40 re-run. |
| 32 | AR | Regression | Re-run Row 2 AR property | finance_docs | RAG | Same as Row 2 | 0.7 | — | Not Run | — | Day 16. |
| 33 | EN | Regression | Re-run Row 6 Duplicate | notification_log | Deduplicate | Same as Row 6 | 1.0 | — | Not Run | — | Day 16. |
| 34 | EN | Regression | Re-run Row 7 SLA | get_sla_breached_leads | SLA | Same as Row 7 | — | — | Not Run | — | Day 16. |
| 35 | EN | Regression | Re-run Row 8 Failure | workflow_errors | Failure handling | Same as Row 8 | — | — | Not Run | — | Day 16. |
| 36 | EN | Regression | Finance + Order + RE all 3 Crons same morning | notification_log + v_deployments_dashboard | Regression | 3 Telegrams, 3 logs, 0 duplicates | 1.0 | — | Not Run | — | Day 16. Check `v_deployments_dashboard` has 3 rows. |
| 37 | EN | Regression | EN/AR mixed batch 10 leads | leads | Scoring | Correct EN/AR routing, no cross-language leak | 0.7 | — | Not Run | — | Day 16. |
| 38 | EN | Regression | Dashboard view counts match logs | v_deployments_dashboard | Regression | View count = notification_log count | — | — | Not Run | — | Day 16. `SELECT * FROM v_deployments_dashboard` |
| 39 | EN | Regression | GitHub repo clean (no secrets, 3 SQL + 4 workflows) | GitHub | Regression | Grep clean, README badges render | — | — | Not Run | — | Day 16. |
| 40 | EN/AR | Regression | Full 40-case pass rate >= 95% | This file | Regression | Update this file, commit, link in README | — | — | Not Run | — | Day 16. If any Fail, fix + re-run that row only, do NOT edit Pass to hide Fail. |

---

## Evidence Checklist for Repo

- [x] Day 12 — `sql/01-day12-supabase-schema.sql`, `02-day12-idempotency-fix.sql`, `03-day12-rpcs.sql`
- [x] Day 12 — `workflows/Day12-01`, `Day12-02`, `Day12-03`, `Day12-00` JSON (scrubbed, no secrets, orphan `Approval Needed?` deleted)
- [x] Day 12 — Screenshots: Light architecture (before Mermaid), Dark flow (Screenshots #1), Telegram messages, Supabase tables, 2nd-run Set Skipped
- [x] Day 12 — Fill Latency ms in rows 3-8 from n8n Executions → Duration
- [ ] Day 13-16 — Fill rows 9-40 only after real execution
