```sql
-- ============================================================
-- INBOXCART · Metabase Dashboard Queries (Postgres)
-- All purchase/value cards scoped to USD only, so every
-- number reconciles against the same USD purchase universe.
-- ============================================================

-- 1. Users Connected (Number)
SELECT count(*) AS users_connected
FROM inboxcart_users
WHERE refresh_token IS NOT NULL AND refresh_token != '';

-- 2. Users with Purchases (Number) — USD only
SELECT count(DISTINCT user_id) AS users_with_purchases
FROM inboxcart_purchases
WHERE total_price_currency = 'USD';

-- 3. Total Purchase Value — USD (Number, currency format)
SELECT COALESCE(sum(total_price_amount), 0) AS total_value_usd
FROM inboxcart_purchases
WHERE total_price_currency = 'USD';

-- 4. Total Purchased Items (Number) — items from USD purchases only
SELECT COALESCE(sum(oi.quantity), 0) AS total_items
FROM inboxcart_order_items oi
JOIN inboxcart_purchases p ON p.id = oi.purchase_order_id
WHERE p.total_price_currency = 'USD';

-- 5. Purchases by Platform (Row chart) — USD only
SELECT
  COALESCE(NULLIF(trim(platform), ''), 'Unknown') AS platform,
  count(*) AS orders
FROM inboxcart_purchases
WHERE total_price_currency = 'USD'
GROUP BY 1
ORDER BY orders DESC;

-- 6. Top Merchants (Table) — USD only
SELECT
  COALESCE(NULLIF(trim(store_name), ''), 'Unknown') AS store_name,
  count(*) AS orders,
  COALESCE(sum(total_price_amount), 0) AS value_usd
FROM inboxcart_purchases
WHERE total_price_currency = 'USD'
GROUP BY 1
ORDER BY value_usd DESC, orders DESC
LIMIT 10;

-- 7. User Signups Over Time (Bar chart) — swap 'day' -> 'hour' to mirror reference
SELECT
  date_trunc('day', created_at) AS bucket,
  count(*) AS signups
FROM inboxcart_users
GROUP BY 1
ORDER BY 1;

-- 8. Monthly Purchases Trend (Bar + trend line) — USD, grouped on email internal_date
SELECT
  date_trunc('month', e.internal_date) AS month,
  sum(p.total_price_amount) AS purchase_value_usd
FROM inboxcart_purchases p
JOIN inboxcart_emails e ON e.id = p.email_id
WHERE p.total_price_currency = 'USD'
  AND e.internal_date IS NOT NULL
GROUP BY 1
ORDER BY 1;

-- 9. Backfill Completion % (Number, percent format)
SELECT
  round(
    100.0 * count(*) FILTER (WHERE backfill_complete)
    / NULLIF(count(*), 0)
  , 1) AS backfill_complete_pct
FROM inboxcart_users
WHERE refresh_token IS NOT NULL AND refresh_token != '';

-- 10. Users Pending Backfill (Number)
SELECT count(*) AS pending_backfill
FROM inboxcart_users
WHERE refresh_token IS NOT NULL AND refresh_token != ''
  AND backfill_complete = false;

-- 11. Backfill Coverage by quarter reached (Bar chart)
SELECT
  date_trunc('quarter', backfill_before) AS reached_quarter,
  count(*) AS users
FROM inboxcart_users
WHERE refresh_token IS NOT NULL AND refresh_token != ''
  AND backfill_before IS NOT NULL
GROUP BY 1
ORDER BY 1;

-- 12. Sync Health — last_sync recency (Row chart / Table)
SELECT
  CASE
    WHEN last_sync IS NULL                         THEN '4 · never'
    WHEN last_sync >= now() - interval '24 hours'  THEN '1 · < 24h'
    WHEN last_sync >= now() - interval '7 days'    THEN '2 · 1–7d'
    ELSE                                                '3 · > 7d'
  END AS recency,
  count(*) AS users
FROM inboxcart_users
WHERE refresh_token IS NOT NULL AND refresh_token != ''
GROUP BY 1
ORDER BY 1;

-- 13. Total Discounts Given — USD (Number)
SELECT COALESCE(sum(discount), 0) AS total_discount_usd
FROM inboxcart_purchases
WHERE total_price_currency = 'USD';

-- 14. Average Order Value — USD (Number)
SELECT round(avg(total_price_amount), 2) AS avg_order_value_usd
FROM inboxcart_purchases
WHERE total_price_currency = 'USD' AND total_price_amount IS NOT NULL;

-- 15. Orders by Status (Row chart) — USD only
SELECT
  COALESCE(NULLIF(trim(status), ''), 'unknown') AS status,
  count(*) AS orders
FROM inboxcart_purchases
WHERE total_price_currency = 'USD'
GROUP BY 1
ORDER BY orders DESC;

-- 16. Email Classification Split (Row chart) — email-level, not currency-scoped
SELECT
  CASE
    WHEN is_purchase_email IS TRUE  THEN 'purchase'
    WHEN is_purchase_email IS FALSE THEN 'non-purchase'
    ELSE 'unclassified'
  END AS classification,
  count(*) AS emails
FROM inboxcart_emails
GROUP BY 1
ORDER BY emails DESC;

```