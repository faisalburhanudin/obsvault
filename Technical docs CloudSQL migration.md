This docs is for comparing pros and cons, also how we will perform migration.
## Performance
Local → GCE vs Fly  
- Reads: Fly slightly faster (up to ~26%)
- Writes: Fly slower (~10–25%)
Fly → GCE vs Fly  
- Reads & Writes: Fly much faster (~60–85%)

```

Query Performance (Local → GCE vs Fly)
-----------------
query                              | CloudSQL    | Fly        | delta  |
-----------------------------------+-------------+------------+--------|
count public.purchases             | 302.09 ms   | 287.72 ms  | -4.8%  |
limit 1000 public.purchases        | 644.32 ms   | 477.07 ms  | -26.0% |
count public.analytics_events      | 277.21 ms   | 291.90 ms  | +5.3%  |
limit 1000 public.analytics_events | 10615.12 ms | 9241.14 ms | -12.9% |

Write Performance (TEMP table)
------------------------------
operation   | CloudSQL  | Fly       | delta  |
------------+-----------+-----------+--------|
temp insert | 259.81 ms | 311.98 ms | +20.1% |
temp update | 249.77 ms | 273.97 ms | +9.7%  |
temp delete | 244.52 ms | 307.08 ms | +25.6% |
temp total  | 775.40 ms | 886.08 ms | +14.3% |
```

```
Query Performance (Fly → GCE vs Fly)
-----------------
query                              | CloudSQL   | Fly       | delta  |
-----------------------------------+------------+-----------+--------|
count public.purchases             | 87.45 ms   | 21.72 ms  | -75.2% |
limit 1000 public.purchases        | 91.63 ms   | 15.13 ms  | -83.5% |
count public.analytics_events      | 66.15 ms   | 22.17 ms  | -66.5% |
limit 1000 public.analytics_events | 1196.78 ms | 498.65 ms | -58.3% |
Write Performance (TEMP table)
------------------------------
operation   | CloudSQL  | Fly      | delta  |
------------+-----------+----------+--------|
temp insert | 53.03 ms  | 14.91 ms | -71.9% |
temp update | 45.92 ms  | 6.61 ms  | -85.6% |
temp delete | 45.62 ms  | 5.99 ms  | -86.9% |
temp total  | 144.45 ms | 28.35 ms | -80.4% |
```

## Maintainability
In my opinion, maintaining only Fly is much simpler. We don’t need to set up a separate proxy like we do on GCE, and network access can be handled through Fly Proxy, so Tailscale is no longer necessary.

Right now, we only use GCP for the database and the MCP server, which we plan to decommission in the future. So, reducing our dependency on another provider feels like the right approach to me.
## How we will perform migration
### Option 1: Offline migration
This is the simplest approach operationally, but it requires planned downtime.
#### Steps
1. Announce a maintenance window.
2. Stop production traffic or put the app in maintenance mode.
3. Stop all writes to Cloud SQL.
4. Run `pg_dump` from Cloud SQL.
5. Run `pg_restore` into the new Fly Postgres database.
6. Validate the restored database:
    - schema
    - row counts
    - extensions
    - indexes
    - sequences
    - app smoke test
7. Update application connection strings to point to the new database.
8. Restart / redeploy services.
9. Monitor errors, latency, and database metrics.
10. Keep Cloud SQL temporarily for rollback, then decommission it later.

#### Cons
Because everything happens during one cutover window, any unexpected issue can directly disrupt production traffic.

---
### Option 2: Online migration using logical replication

This approach reduces downtime and overall migration risk, but it is more complex.

We can use `pgcopydb` because it supports both the initial database copy and Change Data Capture through Postgres logical decoding. Its `clone --follow` mode is intended for online migration, although the docs also warn that online migration is more complex than offline migration.

#### Steps

1. Prepare the new Fly Postgres database.
2. Make sure required extensions, users, roles, permissions, and network access are ready.
3. Set up a temporary sync server that can access both Cloud SQL and Fly Postgres.
4. Run a test migration first without traffic cutover.
5. Start `pgcopydb clone --follow` from Cloud SQL to Fly Postgres.
    - This performs the initial copy.
    - Then it keeps replaying changes using CDC.
6. Monitor replication until the target database is fully caught up.
7. Validate the target database:
    - schema
    - row counts
    - important tables
    - indexes
    - sequences
    - app smoke test
8. Prepare two DB credentials:
    - read-only
    - read-write
9. Start switching low-risk services or read-only workloads to Fly Postgres.
10. During final cutover:
    - briefly freeze writes to Cloud SQL
    - wait until replication lag reaches zero
    - sync sequences if needed
    - switch write traffic to Fly Postgres
11. Monitor production closely.
12. Keep Cloud SQL temporarily as rollback safety.
13. After confidence period, clean up replication resources and decommission Cloud SQL.
#### Pros
This reduces downtime because most data is copied before the final cutover. The final migration window should only need to handle write freeze, final catch-up, validation, and connection switching.
#### Cons
It has more moving parts: replication setup, lag monitoring, cutover coordination, sequence handling, and cleanup.
### My suggestion
The logical replication approach is more complex, but it reduces downtime and lowers the risk of doing everything in a single migration window.