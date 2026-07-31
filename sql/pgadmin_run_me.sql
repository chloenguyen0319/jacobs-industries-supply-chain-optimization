-- =============================================================================
-- Jacobs Industries - START FROM THE VERY BEGINNING (pgAdmin 4)
-- File: sql/pgadmin_run_me.sql
-- =============================================================================
--
-- Follow this exact order. Run ONE step at a time:
--   1. Highlight only that step's SQL
--   2. Press F5
--   3. Read Messages / Data Output
--
-- After STEP 1, you MUST import the CSV in pgAdmin (clicks), then continue.
--
-- ------------------------------------------------------------
-- Already have demand_by_region / data? Which approach?
--
--   START OVER (recommended here)
--     -> Run STEP 1 as written (DROP ... IF EXISTS, then CREATE)
--     -> Then import the CSV again
--     Why: deletes old table + old rows so import starts clean.
--          CREATE TABLE IF NOT EXISTS would KEEP the old table/data,
--          so you would not truly start from the beginning.
--
--   KEEP existing table and data
--     -> SKIP STEP 1
--     -> Run STEP 2 to check row_count
--     -> If row_count = 730, jump to STEP 3
--
--   KEEP table structure, but replace rows only
--     -> SKIP the DROP/CREATE in STEP 1
--     -> Run instead:  TRUNCATE demand_by_region;
--     -> Then Import CSV again
--     -> Then STEP 2
-- ------------------------------------------------------------
-- =============================================================================


-- =============================================================================
-- STEP 1 | DELETE old objects (if any), then create EMPTY demand_by_region
-- Yes: delete first, then create. Do NOT use IF NOT EXISTS for this restart.
-- =============================================================================

DROP TABLE IF EXISTS daily_demand CASCADE;
DROP TABLE IF EXISTS demand_phases CASCADE;
DROP TABLE IF EXISTS forecast_daily CASCADE;
DROP TABLE IF EXISTS inventory_policy CASCADE;
DROP TABLE IF EXISTS network_routing CASCADE;
DROP TABLE IF EXISTS build_decisions CASCADE;
DROP TABLE IF EXISTS transport_costs CASCADE;
DROP TABLE IF EXISTS cost_parameters CASCADE;
DROP TABLE IF EXISTS game_calendar CASCADE;
DROP TABLE IF EXISTS regions CASCADE;
DROP VIEW IF EXISTS v_avg_demand_after_day_90 CASCADE;
DROP VIEW IF EXISTS v_transport_cost_per_drum CASCADE;
DROP VIEW IF EXISTS v_first_demand_day CASCADE;
DROP TABLE IF EXISTS demand_by_region CASCADE;

CREATE TABLE demand_by_region (
    day      INTEGER PRIMARY KEY,  -- one row per day (unique)
    calopeia NUMERIC,
    sorange  NUMERIC,
    tyran    NUMERIC,
    entworpe NUMERIC,
    fardo    NUMERIC
);

-- ============================================================
-- STOP after STEP 1. Do NOT run STEP 1 again after loading data.
--
-- NEXT: load the 730 rows. Prefer Method A (more reliable).
--
-- METHOD A (recommended) - run SQL load file
--   1. File -> Open -> sql/load_demand_by_region.sql
--   2. Press F5 (runs TRUNCATE + INSERT of all 730 rows)
--   3. You should see row_count = 730
--   4. Come back to this file and continue with STEP 3
--      (STEP 2 is optional if Method A already showed 730)
--
-- METHOD B - pgAdmin Import/Export UI (often tricky for beginners)
--   1. Schemas -> public -> Tables -> Refresh
--   2. Right-click demand_by_region -> Import/Export Data...
--   3. Import, csv, Header Yes, file:
--        .../data/demand_by_region.csv
--   4. Then run STEP 2 in this file
--
-- About "Refresh":
--   Refreshing the left-panel table list does NOT load data.
--   After a successful load, re-run the SELECT (F5) to see rows.
--   If SELECT still shows only headers, the table is still empty.
-- ============================================================


-- =============================================================================
-- STEP 2 | Confirm the import (expect 730 rows)
-- Highlight ONLY these SELECTs, then F5
-- =============================================================================

SELECT COUNT(*) AS row_count FROM demand_by_region;
-- If this is 0, the table is empty. Import the CSV before continuing.

SELECT * FROM demand_by_region ORDER BY day LIMIT 5;

SELECT * FROM demand_by_region ORDER BY day DESC LIMIT 5;

-- Pass check:
--   row_count = 730
--   first row: day 1, Calopeia about 11
--   last row:  day 730
--
-- If row_count = 0, the import failed. Redo the Import/Export steps above.


-- =============================================================================
-- STEP 3 | Create lookup tables
-- =============================================================================

CREATE TABLE regions (
    region_name TEXT PRIMARY KEY,
    is_home     BOOLEAN NOT NULL DEFAULT FALSE,
    notes       TEXT
);

CREATE TABLE cost_parameters (
    param_name  TEXT PRIMARY KEY,
    param_value NUMERIC NOT NULL,
    unit        TEXT,
    notes       TEXT
);

CREATE TABLE game_calendar (
    event_name  TEXT PRIMARY KEY,
    day_number  INTEGER NOT NULL,
    notes       TEXT
);

CREATE TABLE transport_costs (
    route_type      TEXT NOT NULL,
    mode            TEXT NOT NULL,
    cost            NUMERIC NOT NULL,
    cost_unit       TEXT NOT NULL,
    days_in_transit NUMERIC NOT NULL,
    PRIMARY KEY (route_type, mode)
);


-- =============================================================================
-- STEP 4 | Create analysis tables
-- =============================================================================

CREATE TABLE daily_demand (
    day_number  INTEGER NOT NULL,
    region_name TEXT NOT NULL REFERENCES regions (region_name),
    demand_qty  NUMERIC NOT NULL,
    PRIMARY KEY (day_number, region_name)
);

CREATE TABLE demand_phases (
    region_name TEXT NOT NULL REFERENCES regions (region_name),
    phase_name  TEXT NOT NULL,
    from_day    INTEGER NOT NULL,
    to_day      INTEGER NOT NULL,
    PRIMARY KEY (region_name, phase_name, from_day)
);

CREATE TABLE forecast_daily (
    day_number   INTEGER NOT NULL,
    region_name  TEXT NOT NULL REFERENCES regions (region_name),
    forecast_qty NUMERIC NOT NULL,
    method       TEXT NOT NULL,
    as_of_day    INTEGER NOT NULL,
    PRIMARY KEY (day_number, region_name, method, as_of_day)
);

CREATE TABLE inventory_policy (
    region_name      TEXT NOT NULL REFERENCES regions (region_name),
    as_of_day        INTEGER NOT NULL,
    avg_daily_demand NUMERIC,
    std_daily_demand NUMERIC,
    eoq              NUMERIC,
    practical_batch  NUMERIC,
    safety_stock     NUMERIC,
    rop              NUMERIC,
    notes            TEXT,
    PRIMARY KEY (region_name, as_of_day)
);

CREATE TABLE network_routing (
    from_day        INTEGER NOT NULL,
    to_day          INTEGER NOT NULL,
    factory         TEXT NOT NULL,
    warehouse       TEXT NOT NULL,
    fulfills_region TEXT NOT NULL REFERENCES regions (region_name),
    PRIMARY KEY (from_day, to_day, factory, warehouse, fulfills_region)
);

CREATE TABLE build_decisions (
    location         TEXT NOT NULL,
    option_type      TEXT NOT NULL,
    saving_per_drum  NUMERIC,
    breakeven_volume NUMERIC,
    forecast_volume  NUMERIC,
    net_gain         NUMERIC,
    decision         TEXT NOT NULL,
    PRIMARY KEY (location, option_type)
);


-- =============================================================================
-- STEP 5 | Fill regions, calendar, costs, transport
-- =============================================================================

INSERT INTO regions (region_name, is_home, notes) VALUES
    ('Calopeia', TRUE,  'Home region - already has factory + warehouse'),
    ('Sorange',  FALSE, NULL),
    ('Tyran',    FALSE, NULL),
    ('Entworpe', FALSE, NULL),
    ('Fardo',    FALSE, 'Off the main continent - longer shipping');

INSERT INTO game_calendar (event_name, day_number, notes) VALUES
    ('history_end',      730,  'Last day in the CSV / historical demand'),
    ('revision_791',     791,  'Update forecasts around this day'),
    ('rop_window_start', 820,  'ROP uses demand from this day onward'),
    ('revision_821',     821,  'Another forecast update'),
    ('decay_start',     1430,  'Demand starts falling to zero'),
    ('production_stop', 1445,  'Stop making more product'),
    ('game_end',        1460,  'Game ends');

INSERT INTO cost_parameters (param_name, param_value, unit, notes) VALUES
    ('variable_production_cost', 1000, '$/drum', 'Production cost per drum'),
    ('setup_cost_per_batch',     1500, '$/batch', 'Fixed cost each production run'),
    ('holding_cost',              100, '$/drum/year', 'Holding cost per drum per year'),
    ('truck_capacity',            200, 'drums', 'Drums per truck'),
    ('base_capacity_calopeia',     70, 'drums/day', 'Starting factory capacity'),
    ('interest_rate',            0.10, 'per year', 'Opportunity cost of cash');

INSERT INTO transport_costs (route_type, mode, cost, cost_unit, days_in_transit) VALUES
    ('same_region',      'truck', 15000, 'per_truck', 7),
    ('same_region',      'mail',    150, 'per_drum',  1),
    ('different_region', 'truck', 20000, 'per_truck', 7),
    ('different_region', 'mail',    200, 'per_drum',  1),
    ('to_fardo',         'truck', 45000, 'per_truck', 14),
    ('to_fardo',         'mail',    400, 'per_drum',  2);


-- =============================================================================
-- STEP 6 | Reshape wide demand_by_region -> long daily_demand
-- expect 730 x 5 = 3650 rows
-- =============================================================================

INSERT INTO daily_demand (day_number, region_name, demand_qty)
SELECT day, 'Calopeia', calopeia FROM demand_by_region
UNION ALL
SELECT day, 'Sorange',  sorange  FROM demand_by_region
UNION ALL
SELECT day, 'Tyran',    tyran    FROM demand_by_region
UNION ALL
SELECT day, 'Entworpe', entworpe FROM demand_by_region
UNION ALL
SELECT day, 'Fardo',    fardo    FROM demand_by_region;


-- =============================================================================
-- STEP 7 | Check daily_demand
-- =============================================================================

SELECT COUNT(*) AS total_rows FROM daily_demand;

SELECT region_name, COUNT(*) AS days, ROUND(SUM(demand_qty)::numeric, 0) AS total_demand
FROM daily_demand
GROUP BY region_name
ORDER BY region_name;

SELECT *
FROM daily_demand
WHERE region_name = 'Calopeia'
ORDER BY day_number
LIMIT 10;


-- =============================================================================
-- STEP 8 | Create Excel-style summary views
-- =============================================================================

CREATE OR REPLACE VIEW v_avg_demand_after_day_90 AS
SELECT
    region_name,
    ROUND(AVG(demand_qty)::numeric, 2) AS avg_demand,
    ROUND(STDDEV_SAMP(demand_qty)::numeric, 2) AS std_demand,
    COUNT(*) AS number_of_days
FROM daily_demand
WHERE day_number > 90
GROUP BY region_name;

CREATE OR REPLACE VIEW v_transport_cost_per_drum AS
SELECT
    route_type,
    mode,
    CASE
        WHEN cost_unit = 'per_truck' THEN ROUND((cost / 200.0)::numeric, 2)
        ELSE cost
    END AS cost_per_drum,
    days_in_transit
FROM transport_costs;

CREATE OR REPLACE VIEW v_first_demand_day AS
SELECT
    region_name,
    MIN(day_number) AS first_day_with_demand
FROM daily_demand
WHERE demand_qty > 0
GROUP BY region_name;


-- =============================================================================
-- STEP 9 | Final checks
-- =============================================================================

SELECT current_database() AS database_name;

SELECT tablename
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

SELECT * FROM regions ORDER BY region_name;

SELECT * FROM game_calendar ORDER BY day_number;

SELECT * FROM v_first_demand_day ORDER BY first_day_with_demand, region_name;

SELECT * FROM v_avg_demand_after_day_90 ORDER BY region_name;

SELECT * FROM v_transport_cost_per_drum ORDER BY route_type, mode;


-- =============================================================================
-- DONE with SQL setup
-- Next: python/supply_chain_python_work.py for forecasts, EOQ, ROP, decisions
-- =============================================================================
