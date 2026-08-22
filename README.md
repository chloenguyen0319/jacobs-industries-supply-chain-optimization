# Jacobs Industries - Multi-Region Supply Chain Optimization

## What This Project Does

Jacobs Industries makes an industrial insulating foam chemical, sold so far
only in its home region (Calopeia) through one factory and one warehouse. Four
new regional markets have been identified but not yet served. A competing
technology will make the entire product line obsolete on a fixed future date,
with demand decaying to zero in the final 30 days before that.

This project answers: **which new markets should Jacobs enter, when, and with
what factory/warehouse/inventory setup - to maximize cash by the end date?**

## Project Status

| Component | Status |
|---|---|
| Excel model (`analysis/supply-chain-model.xlsx`) | Complete |
| Written report (`docs/Jacobs-Industries-Supply-Chain-Report.pdf`) | Complete |
| SQL pipeline (`sql/`) | Coming soon |
| Python replication (`python/`) | Coming soon |
| Dashboard (Power BI / Tableau) | Planned |

The current source of truth is the Excel workbook and business report. SQL and
Python will replicate that analysis for reproducibility and downstream
dashboarding.

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
├── data/       demand_by_region.csv  (historical demand, days 1-730)
├── analysis/   Excel model (complete — full solution)
├── docs/       written report (complete)
├── sql/        PostgreSQL pipeline (coming soon)
└── python/     Python replication of Excel logic (coming soon)
```

## Tools

- **Excel** — complete model (`analysis/supply-chain-model.xlsx`)
- **SQL (pgAdmin 4 / PostgreSQL)** — coming soon (`sql/`)
- **Python** — coming soon (`python/`)
- **Power BI / Tableau** — planned after SQL + Python

## How to use this repo

### A. Review the completed analysis (available now)

1. Open `analysis/supply-chain-model.xlsx` for the full model (forecasts, EOQ/ROP,
   build decisions, cash flow).
2. Read `docs/Jacobs-Industries-Supply-Chain-Report.pdf` for the business
   recommendations and rationale.
3. Use `data/demand_by_region.csv` for the underlying historical demand inputs.

### B. SQL pipeline (coming soon)

The SQL layer will load demand data into PostgreSQL and expose the same
calculations as views/tables for querying and dashboarding. Planned files:

- `sql/pgadmin_run_me.sql` — schema, transforms, and step-by-step workflow
- `sql/load_demand_by_region.sql` — CSV import helper

### C. Python replication (coming soon)

`python/supply_chain_python_work.py` will mirror the Excel math in code:
forecasts → EOQ/ROP → capacity → build decisions → cash flow, with results
written back to SQL tables (`forecast_daily`, `inventory_policy`,
`build_decisions`).

### D. Dashboard (planned)

Power BI or Tableau on the SQL tables/views once the SQL and Python layers
match the Excel model.

## Acknowledgments & License

The Jacobs Industries scenario is based on the **Supply Chain Game**,
developed by Professors Sunil Chopra and Philipp Afeche at the Kellogg School
of Management, Northwestern University. It was completed as coursework for
**MGT 267: Applied Business Forecasting** at the University of California,
Riverside, guided by Professor Suri Gurmurthi.

This repository contains original analysis, forecasting, and optimization
work produced for that course. The underlying simulation and scenario content
belong to their original authors/institution.
