-- =============================================================================
-- Jacobs Industries - SQL work plan (beginner-friendly)
-- =============================================================================
--
-- WHAT THIS FILE IS
--   A step-by-step checklist of SQL work that copies the Excel model's
--   "data and tables" side. Do the tasks in order: Step 1, Step 2, ...
--
-- WHAT SQL IS GOOD AT HERE
--   - Storing data in tables
--   - Filtering by day ranges (e.g. after day 90, from day 820)
--   - Adding numbers up (SUM, AVG) by region or phase
--   - Joining tables together
--   - Making simple views for a future dashboard
--
-- WHAT PYTHON DOES INSTEAD
--   Hard math: forecasts, EOQ, reorder point (ROP).
--   See: python/supply_chain_python_work.py
--
-- IMPORTANT: where data comes from
--   - Historical demand  -> data/demand_by_region.xlsx  (days 1-730)
--   - Costs, calendar, rules -> Excel Summary / game rules (NOT the demand file)
--
-- Dialects: written for PostgreSQL. Other tools (SQLite, etc.) are similar.
-- =============================================================================


-- =============================================================================
-- STEP 1 | Create small lookup tables (regions, costs, calendar)
-- Why: keep rules and costs in one place so every query uses the same numbers.
-- =============================================================================

-- List of markets we serve
CREATE TABLE IF NOT EXISTS regions (
    region_name TEXT PRIMARY KEY,   -- e.g. Calopeia
    is_home     BOOLEAN NOT NULL DEFAULT FALSE,  -- TRUE only for Calopeia
    notes       TEXT
);

-- One row per cost or rule number (like Excel named ranges)
CREATE TABLE IF NOT EXISTS cost_parameters (
    param_name  TEXT PRIMARY KEY,   -- e.g. holding_cost
    param_value NUMERIC NOT NULL,   -- e.g. 100
    unit        TEXT,               -- e.g. $/drum/year
    notes       TEXT
);

-- Important days in the game
CREATE TABLE IF NOT EXISTS game_calendar (
    event_name  TEXT PRIMARY KEY,   -- e.g. game_end
    day_number  INTEGER NOT NULL,   -- e.g. 1460
    notes       TEXT
);

-- Shipping costs and times (truck vs mail, short vs long distance)
CREATE TABLE IF NOT EXISTS transport_costs (
    route_type   TEXT NOT NULL,     -- same_region | different_region | to_fardo
    mode         TEXT NOT NULL,     -- truck | mail
    cost         NUMERIC NOT NULL,
    cost_unit    TEXT NOT NULL,     -- per_drum | per_truck
    days_in_transit NUMERIC NOT NULL,
    PRIMARY KEY (route_type, mode)
);


-- =============================================================================
-- STEP 2 | Create main data tables
-- Why: hold demand history, forecasts (from Python), and decisions.
-- =============================================================================

-- Historical demand (loaded from demand_by_region.xlsx)
-- One row = one day + one region
CREATE TABLE IF NOT EXISTS daily_demand (
    day_number  INTEGER NOT NULL,
    region_name TEXT NOT NULL REFERENCES regions (region_name),
    demand_qty  NUMERIC NOT NULL,
    PRIMARY KEY (day_number, region_name)
);

-- Optional: name the demand phases (Peak, Ramp up, etc.)
CREATE TABLE IF NOT EXISTS demand_phases (
    region_name TEXT NOT NULL REFERENCES regions (region_name),
    phase_name  TEXT NOT NULL,
    from_day    INTEGER NOT NULL,
    to_day      INTEGER NOT NULL,
    PRIMARY KEY (region_name, phase_name, from_day)
);

-- Daily forecasts written by Python later
CREATE TABLE IF NOT EXISTS forecast_daily (
    day_number   INTEGER NOT NULL,
    region_name  TEXT NOT NULL REFERENCES regions (region_name),
    forecast_qty NUMERIC NOT NULL,
    method       TEXT NOT NULL,   -- seasonal | ols | average | interarrival
    as_of_day    INTEGER NOT NULL, -- when this forecast was made (e.g. 791, 821)
    PRIMARY KEY (day_number, region_name, method, as_of_day)
);

-- Inventory policy numbers written by Python (EOQ, ROP, safety stock, ...)
CREATE TABLE IF NOT EXISTS inventory_policy (
    region_name      TEXT NOT NULL REFERENCES regions (region_name),
    as_of_day        INTEGER NOT NULL,  -- policy starts on this day
    avg_daily_demand NUMERIC,
    std_daily_demand NUMERIC,
    eoq              NUMERIC,
    practical_batch  NUMERIC,
    safety_stock     NUMERIC,
    rop              NUMERIC,
    notes            TEXT,
    PRIMARY KEY (region_name, as_of_day)
);

-- Which factory / warehouse serves which region, and during which days
CREATE TABLE IF NOT EXISTS network_routing (
    from_day        INTEGER NOT NULL,
    to_day          INTEGER NOT NULL,
    factory         TEXT NOT NULL,
    warehouse       TEXT NOT NULL,
    fulfills_region TEXT NOT NULL REFERENCES regions (region_name),
    PRIMARY KEY (from_day, to_day, factory, warehouse, fulfills_region)
);

-- Build / skip decisions for new factories and warehouses
CREATE TABLE IF NOT EXISTS build_decisions (
    location         TEXT NOT NULL,
    option_type      TEXT NOT NULL,  -- factory_and_warehouse | warehouse_only
    saving_per_drum  NUMERIC,
    breakeven_volume NUMERIC,
    forecast_volume  NUMERIC,
    net_gain         NUMERIC,
    decision         TEXT NOT NULL,  -- Skip | WH only | Factory + WH
    PRIMARY KEY (location, option_type)
);


-- =============================================================================
-- STEP 3 | Fill in regions, costs, and calendar
-- Why: these do NOT come from demand_by_region.xlsx.
--      Copy values from the Excel Summary sheet / game rules.
-- =============================================================================

INSERT INTO regions (region_name, is_home, notes) VALUES
    ('Calopeia', TRUE,  'Home region - already has factory + warehouse'),
    ('Sorange',  FALSE, NULL),
    ('Tyran',    FALSE, NULL),
    ('Entworpe', FALSE, NULL),
    ('Fardo',    FALSE, 'Off the main continent - longer shipping')
ON CONFLICT (region_name) DO NOTHING;

INSERT INTO game_calendar (event_name, day_number, notes) VALUES
    ('history_end',      730,  'Last day of historical demand data'),
    ('revision_791',     791,  'Update forecasts around this day'),
    ('rop_window_start', 820,  'ROP uses demand from this day onward'),
    ('revision_821',     821,  'Another forecast update'),
    ('decay_start',     1430,  'Demand starts falling to zero'),
    ('production_stop', 1445,  'Stop making more product'),
    ('game_end',        1460,  'Game ends')
ON CONFLICT (event_name) DO NOTHING;

-- TODO: fill real numbers from Excel Summary (examples shown)
-- INSERT INTO cost_parameters (param_name, param_value, unit, notes) VALUES
--     ('variable_production_cost', 1000, '$/drum', NULL),
--     ('setup_cost_per_batch',     1500, '$/batch', NULL),
--     ('holding_cost',              100, '$/drum/year', NULL),
--     ('truck_capacity',            200, 'drums', NULL),
--     ('base_capacity_calopeia',     70, 'drums/day', NULL);

-- TODO: INSERT INTO transport_costs (...) VALUES (...);


-- =============================================================================
-- STEP 4 | Load historical demand
-- Why: this IS the only step that starts from demand_by_region.xlsx.
-- How (simple path):
--   1. In Python (Step P1), turn the Excel file into a long CSV:
--        day_number, region_name, demand_qty
--   2. Then load that CSV here.
-- =============================================================================

-- Example (PostgreSQL):
-- COPY daily_demand (day_number, region_name, demand_qty)
-- FROM '/path/to/daily_demand.csv'
-- WITH (FORMAT csv, HEADER true);


-- =============================================================================
-- STEP 5 | Average and std of demand (simple summaries)
-- Why: Excel Consolidated data does AVERAGE / STDEV after day 90.
--      SQL is great at this kind of "group and summarize" work.
-- =============================================================================

-- Average daily demand by region AFTER day 90
CREATE OR REPLACE VIEW v_avg_demand_after_day_90 AS
SELECT
    region_name,
    AVG(demand_qty) AS avg_demand,
    -- STDDEV_SAMP = sample standard deviation (like Excel STDEV)
    STDDEV_SAMP(demand_qty) AS std_demand,
    COUNT(*) AS number_of_days
FROM daily_demand
WHERE day_number > 90
GROUP BY region_name;

-- Try it:
-- SELECT * FROM v_avg_demand_after_day_90;


-- =============================================================================
-- STEP 6 | Demand by phase
-- Why: Excel Summary adds demand inside each phase (Peak, Ramp up, ...).
-- Need: demand_phases filled in first, then this view joins it to daily_demand.
-- =============================================================================

CREATE OR REPLACE VIEW v_demand_by_phase AS
SELECT
    p.region_name,
    p.phase_name,
    p.from_day,
    p.to_day,
    SUM(d.demand_qty) AS total_demand,
    AVG(d.demand_qty) AS avg_demand,
    COUNT(*) AS number_of_days
FROM demand_phases AS p
JOIN daily_demand AS d
  ON d.region_name = p.region_name
 AND d.day_number BETWEEN p.from_day AND p.to_day
GROUP BY p.region_name, p.phase_name, p.from_day, p.to_day;

-- Try it:
-- SELECT * FROM v_demand_by_phase;


-- =============================================================================
-- STEP 7 | Remaining forecast demand (for capacity questions)
-- Why: Excel asks "how much demand is left after day 820?"
-- Need: forecast_daily filled by Python first.
-- =============================================================================

-- Example query (run after Python writes forecasts):
-- SELECT
--     region_name,
--     SUM(forecast_qty) AS remaining_demand
-- FROM forecast_daily
-- WHERE day_number >= 820
--   AND day_number < 1430
-- GROUP BY region_name;


-- =============================================================================
-- STEP 8 | Transport cost per drum
-- Why: Excel compares truck/mail costs; we need $ per drum for fair comparison.
-- =============================================================================

CREATE OR REPLACE VIEW v_transport_cost_per_drum AS
SELECT
    route_type,
    mode,
    CASE
        WHEN cost_unit = 'per_truck' THEN cost / 200.0   -- truck holds 200 drums
        ELSE cost
    END AS cost_per_drum,
    days_in_transit
FROM transport_costs;

-- Try it:
-- SELECT * FROM v_transport_cost_per_drum;


-- =============================================================================
-- STEP 9 | Store build decisions (after you calculate them)
-- Why: Excel §5-§6 decides Skip / WH only / Factory + WH.
--      You can calculate savings in Python or with simple SQL, then INSERT here.
-- Tip for beginners: calculate in Python first (clearer), then save the answer
-- into build_decisions for reporting / dashboard later.
-- =============================================================================

-- Example shape of a row (do not run until numbers are real):
-- INSERT INTO build_decisions (
--     location, option_type, saving_per_drum, breakeven_volume,
--     forecast_volume, net_gain, decision
-- ) VALUES (
--     'Sorange', 'warehouse_only', 10, 50000, 80000, 300000, 'WH only'
-- );


-- =============================================================================
-- STEP 10 | Latest ROP per region (for reporting)
-- Why: Python computes ROP; SQL just stores and shows the latest values.
-- =============================================================================

CREATE OR REPLACE VIEW v_latest_rop AS
SELECT
    region_name,
    as_of_day,
    avg_daily_demand,
    std_daily_demand,
    practical_batch,
    safety_stock,
    rop,
    notes
FROM inventory_policy
-- For each region, keep the row with the largest as_of_day
WHERE (region_name, as_of_day) IN (
    SELECT region_name, MAX(as_of_day)
    FROM inventory_policy
    GROUP BY region_name
);

-- Try it:
-- SELECT * FROM v_latest_rop;


-- =============================================================================
-- STEP 11 | End-of-life demand check (simple query)
-- Why: Excel §9 - demand fades from day 1430 to 1460; stop production day 1445.
-- =============================================================================

-- Example:
-- SELECT
--     region_name,
--     SUM(CASE WHEN day_number BETWEEN 1430 AND 1460 THEN forecast_qty ELSE 0 END)
--         AS demand_during_decay,
--     SUM(CASE WHEN day_number BETWEEN 1445 AND 1460 THEN forecast_qty ELSE 0 END)
--         AS demand_after_production_stops
-- FROM forecast_daily
-- GROUP BY region_name;


-- =============================================================================
-- STEP 12 | Dashboard views (do this LAST - after Power BI / Tableau starts)
-- Why: give the dashboard clean, ready-made tables so it does not rebuild logic.
-- =============================================================================

-- Ideas for later (create when needed):
--   v_dashboard_daily_demand     -> day, region, actual demand, forecast
--   v_dashboard_build_decisions  -> location, savings, decision
--   v_dashboard_rop_timeline     -> region, day, ROP, safety stock


-- =============================================================================
-- QUICK MAP: SQL steps vs Python steps
--   SQL Step 1-3  = set up empty tables + rules/costs
--   SQL Step 4    = load demand (after Python turns xlsx into CSV)  [uses demand file]
--   SQL Step 5-8  = summaries and cost helpers
--   Python P1-P11 = forecasts, EOQ, ROP, scenarios, then write into SQL tables
--   SQL Step 9-12 = store decisions, show ROP, prepare dashboard
-- =============================================================================
