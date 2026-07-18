"""
Jacobs Industries - Python work plan (beginner-friendly)
========================================================

WHAT THIS FILE IS
  A step-by-step checklist of Python work that copies the Excel model's
  "math and forecasting" side. Do the steps in order: Step 1, Step 2, ...

WHAT PYTHON IS GOOD AT HERE
  - Reading Excel files
  - Forecasting demand (different method per region)
  - Inventory math: EOQ, safety stock, reorder point (ROP)
  - "What if" scenarios (build a warehouse? expand capacity?)
  - Saving results so SQL / a dashboard can use them later

WHAT SQL DOES INSTEAD
  Storing tables, adding up demand by day/phase, dashboard views.
  See: sql/supply_chain_sql_work.sql

IMPORTANT: where data comes from
  - Historical demand  -> data/demand_by_region.xlsx   (days 1-730 only)
  - Costs & game days  -> Excel Summary / game rules   (NOT the demand file)

STATUS
  This is a learning scaffold. Each step has a function to fill in later.
  Run this file anytime:  python python/supply_chain_python_work.py
"""

from pathlib import Path

# Packages you will likely need later (install when you start coding a step):
#   pip install pandas openpyxl numpy scipy

# Project folders
PROJECT_ROOT = Path(__file__).resolve().parents[1]
DEMAND_FILE = PROJECT_ROOT / "data" / "demand_by_region.xlsx"
EXCEL_MODEL = PROJECT_ROOT / "analysis" / "supply-chain-model.xlsx"
OUTPUT_FOLDER = PROJECT_ROOT / "python" / "outputs"

REGIONS = ["Calopeia", "Sorange", "Tyran", "Entworpe", "Fardo"]


# =============================================================================
# STEP 1 | Load historical demand
# Start from: data/demand_by_region.xlsx
# Goal: turn wide Excel (one column per region) into a simple table:
#       day_number | region_name | demand_qty
# =============================================================================

def step1_load_demand(path=DEMAND_FILE):
    """
    Read demand_by_region.xlsx and return a long table.

    Expected Excel layout:
      day | Calopeia | Sorange | Tyran | Entworpe | Fardo
      1   | 11       | 0       | ...

    TODO:
      1. Use pandas.read_excel(path)
      2. Use melt / stack to make one region column
      3. Check that days run from 1 to 730
    """
    raise NotImplementedError("Fill in Step 1")


# =============================================================================
# STEP 2 | Game calendar and cost numbers
# Start from: Excel Summary sheet / game rules (NOT the demand file)
# Goal: keep important numbers in one clear place.
# =============================================================================

# Important days in the game (from the Excel model)
HISTORY_END = 730
REVISION_DAY_791 = 791
ROP_START_DAY = 820
REVISION_DAY_821 = 821
DECAY_START = 1430
PRODUCTION_STOP = 1445
GAME_END = 1460

# Cost examples from the game (fill any missing values from Excel Summary)
VARIABLE_COST_PER_DRUM = 1000
SETUP_COST_PER_BATCH = 1500
HOLDING_COST_PER_DRUM_YEAR = 100
TRUCK_CAPACITY = 200
BASE_CAPACITY_CALOPEIA = 70
# TODO: add revenue, factory_cost, warehouse_cost, capacity_cost, interest, etc.


def step2_print_key_numbers():
    """Print the calendar so you can confirm the numbers look right."""
    print("Key game days:")
    print(f"  History ends:           {HISTORY_END}")
    print(f"  Forecast revision:      {REVISION_DAY_791}")
    print(f"  ROP window starts:      {ROP_START_DAY}")
    print(f"  Forecast revision:      {REVISION_DAY_821}")
    print(f"  Demand decay starts:    {DECAY_START}")
    print(f"  Stop production:        {PRODUCTION_STOP}")
    print(f"  Game ends:              {GAME_END}")


# =============================================================================
# STEP 3 | Forecast demand (one method per region)
# Start from: Step 1 demand table + Step 2 calendar
# Goal: predict daily demand from day 731 through day 1460.
#
# Methods used in Excel:
#   Calopeia  -> seasonal index (repeats each year)
#   Sorange   -> linear growth (straight line / regression)
#   Tyran     -> simple average after demand stabilizes
#   Fardo     -> simple average (similar idea to Tyran)
#   Entworpe  -> inter-arrival timing (orders of 250 drums at random times)
#
# Also: from day 1430 to 1460, demand falls in a straight line to zero.
# =============================================================================

def step3_forecast_calopeia(demand):
    """Seasonal index forecast for Calopeia."""
    raise NotImplementedError("Fill in Step 3 - Calopeia")


def step3_forecast_sorange(demand):
    """Linear growth forecast for Sorange."""
    raise NotImplementedError("Fill in Step 3 - Sorange")


def step3_forecast_average(demand, region_name, start_day=670):
    """
    Simple average forecast (Tyran / Fardo).
    Tip: start after ramp-up (e.g. day 670), not from the first zero days.
    """
    raise NotImplementedError("Fill in Step 3 - average method")


def step3_forecast_entworpe(demand):
    """Inter-arrival forecast for Entworpe (orders of 250 drums)."""
    raise NotImplementedError("Fill in Step 3 - Entworpe")


def step3_apply_decay(forecast):
    """From day 1430 to 1460, reduce demand in a straight line down to 0."""
    raise NotImplementedError("Fill in Step 3 - end-of-life decay")


# =============================================================================
# STEP 4 | Average and std for ROP inputs
# Start from: demand or forecast table
# Goal: get mean and standard deviation for a day window
#       (Excel uses "after day 90" and "from day 820").
# =============================================================================

def step4_mean_and_std(demand_or_forecast, from_day):
    """
    Return average and std of demand for days >= from_day.

    TODO:
      filter rows where day_number >= from_day
      compute mean and std (pandas or numpy)
    """
    raise NotImplementedError("Fill in Step 4")


# =============================================================================
# STEP 5 | EOQ (how big should each production batch be?)
# Start from: setup cost, holding cost, demand rate (Step 2 + Step 3/4)
# Formula: EOQ = sqrt(2 * D * S / H)
#   D = demand per year
#   S = setup cost per batch
#   H = holding cost per drum per year
# =============================================================================

def step5_eoq(demand_per_year, setup_cost, holding_cost):
    """Return the economic order quantity."""
    raise NotImplementedError("Fill in Step 5")


def step5_practical_batch(eoq_value, truck_capacity=TRUCK_CAPACITY):
    """
    Adjust EOQ to a practical size (often related to truck size = 200).
    Exact rounding rule: match what Excel Summary uses.
    """
    raise NotImplementedError("Fill in Step 5")


# =============================================================================
# STEP 6 | Reorder point (ROP) and safety stock
# Start from: lead-time demand stats + cost tradeoff (Cu vs Co)
# Simple idea:
#   1. Choose a service level from costs:  SL = Cu / (Cu + Co)
#   2. Turn SL into a z-score (normal table / scipy)
#   3. Safety stock = z * std of lead-time demand
#   4. ROP = average lead-time demand + safety stock
#
# ROP is NOT fixed forever. Recalculate when demand changes, for example:
#   - new forecast at day 791 or 821
#   - ROP window from day 820
#   - near the end: cut all ROPs by 50%
# =============================================================================

def step6_service_level(cu, co):
    """Return Cu / (Cu + Co)."""
    raise NotImplementedError("Fill in Step 6")


def step6_z_score(service_level):
    """Turn service level into a z value (use scipy later)."""
    raise NotImplementedError("Fill in Step 6")


def step6_safety_stock(z, std_lead_time_demand):
    """Return z * std."""
    raise NotImplementedError("Fill in Step 6")


def step6_rop(avg_lead_time_demand, safety_stock):
    """Return average lead-time demand + safety stock."""
    raise NotImplementedError("Fill in Step 6")


def step6_build_rop_table(forecast):
    """
    Build a table of ROP by region and start day.
    Include the end-of-life rule: reduce ROP by 50% when production stops.
    """
    raise NotImplementedError("Fill in Step 6")


# =============================================================================
# STEP 7 | Capacity check
# Start from: forecast + base capacity 70 + build times
# Goal: see if we need more capacity, and estimate lost sales during builds.
# =============================================================================

def step7_capacity_plan(forecast, with_fardo_factory=False):
    """Compare demand to capacity; return min capacity needed (+ 10% buffer)."""
    raise NotImplementedError("Fill in Step 7")


# =============================================================================
# STEP 8 | Should we build a factory or warehouse?
# Start from: shipping savings per drum + build cost + forecast volume
# Simple idea:
#   breakeven = build_cost / saving_per_drum
#   if forecast volume > breakeven -> building can pay off
# =============================================================================

def step8_saving_per_drum(cost_from_calopeia, cost_from_local):
    """How much cheaper is local shipping than shipping from Calopeia?"""
    return cost_from_calopeia - cost_from_local


def step8_breakeven(build_cost, saving_per_drum):
    """How many drums until savings pay back the build cost?"""
    raise NotImplementedError("Fill in Step 8")


def step8_decide_builds(forecast):
    """
    For each region option, return Skip / WH only / Factory + WH.
    Save results into SQL build_decisions later (Step 10).
    """
    raise NotImplementedError("Fill in Step 8")


# =============================================================================
# STEP 9 | Cash flow check
# Start from: build decisions + timing of cash needs
# Goal: make sure we can afford builds without running out of cash.
# =============================================================================

def step9_cash_flow_check(build_plan, cash_over_time):
    """Return whether the plan is affordable day by day."""
    raise NotImplementedError("Fill in Step 9")


# =============================================================================
# STEP 10 | End-of-life checklist (already filled in - use as a reminder)
# =============================================================================

def step10_wind_down_checklist():
    """Important actions near the end of the game."""
    return [
        (DECAY_START, "Demand starts falling to zero (all regions)"),
        (PRODUCTION_STOP, "Stop production at both factories"),
        (PRODUCTION_STOP, "Cut all ROPs by 50%"),
        (GAME_END, "Game ends; leftover inventory is worth $0"),
    ]


# =============================================================================
# STEP 11 | Save results for SQL / future dashboard
# Goal: write CSV files that match the SQL table columns.
# =============================================================================

def step11_save_outputs(forecast, rop_table, build_decisions):
    """
    Save CSV files into python/outputs/, for example:
      forecast_daily.csv
      inventory_policy.csv
      build_decisions.csv
    Column names should match sql/supply_chain_sql_work.sql tables.
    """
    raise NotImplementedError("Fill in Step 11")


# =============================================================================
# STEP 12 | Compare a few answers to Excel
# Goal: before building a dashboard, check that Python matches Excel closely.
# =============================================================================

def step12_check_against_excel(python_value, excel_value, label, allowed_diff=1.0):
    """Print OK or FAIL when comparing one number to Excel."""
    diff = abs(python_value - excel_value)
    if diff <= allowed_diff:
        print(f"OK  | {label}: python={python_value}, excel={excel_value}")
    else:
        print(f"FAIL| {label}: python={python_value}, excel={excel_value}, diff={diff}")


# =============================================================================
# Run this file to see the roadmap
# =============================================================================

def main():
    OUTPUT_FOLDER.mkdir(parents=True, exist_ok=True)

    print("=" * 60)
    print("Jacobs Industries - Python work plan")
    print("=" * 60)
    print()
    print("Do the steps in order. Each step is a function above.")
    print()
    print("Step 1  Load demand from data/demand_by_region.xlsx")
    print("Step 2  Set calendar + cost numbers (from Excel / rules)")
    print("Step 3  Forecast each region")
    print("Step 4  Mean / std for ROP")
    print("Step 5  EOQ + practical batch")
    print("Step 6  Safety stock + ROP (update when demand changes)")
    print("Step 7  Capacity check")
    print("Step 8  Build vs skip decisions")
    print("Step 9  Cash flow check")
    print("Step 10 End-of-life checklist")
    print("Step 11 Save CSV outputs for SQL")
    print("Step 12 Compare key numbers to Excel")
    print()
    step2_print_key_numbers()
    print()
    print("End-of-life reminder:")
    for day, action in step10_wind_down_checklist():
        print(f"  Day {day}: {action}")
    print()
    print("SQL companion file:")
    print(f"  {PROJECT_ROOT / 'sql' / 'supply_chain_sql_work.sql'}")


if __name__ == "__main__":
    main()
