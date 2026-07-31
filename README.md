# Jacobs Industries - Multi-Region Supply Chain Optimization

## What This Project Does

Jacobs Industries makes an industrial insulating foam chemical, sold so far
only in its home region (Calopeia) through one factory and one warehouse. Four
new regional markets have been identified but not yet served. A competing
technology will make the entire product line obsolete on a fixed future date,
with demand decaying to zero in the final 30 days before that.

This project answers: **which new markets should Jacobs enter, when, and with
what factory/warehouse/inventory setup - to maximize cash by the end date?**

## Key Decisions Analyzed

- Which markets to serve, and when to start
- Whether to expand the existing factory, and by how much
- Whether to build new factories or warehouses in the new regions
- How to size production batches and reorder points
- Truck vs. mail for shipping
- Which warehouse serves which market

## Methods Used

- **Demand forecasting** - different technique per region depending on its
  pattern: seasonal index (stable seasonal demand), linear regression (growing
  demand), historical averaging (stable demand), and inter-arrival timing (fixed
  quantity, random-timing orders)
- **EOQ** - optimal production batch sizing
- **Reorder point with safety stock**, sized using a **newsvendor / critical
  ratio service level** (balances lost-sale cost against holding cost, rather
  than assuming an arbitrary fixed service level). ROP is not a one-time,
  static number - it's recalculated whenever the demand inputs behind it
  change, e.g. when a region's forecast is revised at a specific point in the
  game (day 791, day 821), when the model switches to a new
  average/std-dev-of-demand window (day 820 onward), and during the
  end-of-life wind-down (ROPs cut by half as demand decays toward the game's
  end)
- **Breakeven / net gain analysis** for every warehouse and factory build
  decision
- **Cash flow feasibility check** for simultaneous infrastructure investment

## Results Summary

| Decision | Outcome |
|---|---|
| Serve all 5 markets? | Yes |
| Expand existing factory? | Yes |
| Build warehouses in new regions? | Yes, in most - except where demand is too unpredictable |
| Build new factories elsewhere? | No - not worth the fixed building cost vs. expanding existing factory, except one region where local production also cut a costly long-distance shipping leg |
| Shipping mode | Truck throughout |

## Repo Structure

```
├── data/       demand_by_region.xlsx / .csv  (historical demand, days 1-730)
├── analysis/   Excel model (original full solution)
├── sql/        pgadmin_run_me.sql  (only SQL file - run in pgAdmin 4)
├── python/     supply_chain_python_work.py  (forecasts, EOQ, ROP, decisions)
└── docs/       written report
```

## Tools

- **Excel** - original model (`analysis/supply-chain-model.xlsx`)
- **SQL (pgAdmin 4)** - one file: `sql/pgadmin_run_me.sql`
- **Python** - forecasts / EOQ / ROP / build & cash-flow (`python/supply_chain_python_work.py`)
- **Power BI / Tableau** - dashboard later

## How to replicate the Excel work

### A. SQL first (pgAdmin 4) — start from zero (including CSV import)

1. Close any old Query Tool tab, open a new one on your database
2. **File → Open** → `sql/pgadmin_run_me.sql`
3. Run **STEP 1** only (highlight → F5) — wipes old tables, creates empty `demand_by_region`
4. **Load the CSV data** (pick one):
   - **Recommended:** open `sql/load_demand_by_region.sql` → F5 (loads all 730 rows)
   - Or use pgAdmin Import/Export on `demand_by_region` with `data/demand_by_region.csv`
5. Run **STEP 2** — expect `row_count = 730`
6. Run **STEP 3 → STEP 9** one step at a time

Note: refreshing the left-panel table list does not load data. Re-run the SELECT after loading.

### B. Python next (math that Excel did)

Open `python/supply_chain_python_work.py` and implement steps in order:
forecasts → EOQ/ROP → capacity → build decisions → cash flow → save results
back into the SQL tables (`forecast_daily`, `inventory_policy`, `build_decisions`).

### C. Dashboard later

Power BI or Tableau on the SQL tables/views after A + B match Excel.

## Acknowledgments & License

The Jacobs Industries scenario is based on the **Supply Chain Game**,
developed by Professors Sunil Chopra and Philipp Afeche at the Kellogg School
of Management, Northwestern University. It was completed as coursework for
**MGT 267: Applied Business Forecasting** at the University of California,
Riverside, guided by Professor Suri Gurmurthi.

This repository contains original analysis, forecasting, and optimization
work produced for that course. The underlying simulation and scenario content
belong to their original authors/institution.
