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
├── data/        raw historical demand data
├── analysis/    working Excel model (forecasts, EOQ/ROP, breakeven, cash flow)
├── sql/         SQL work plan - schema, set-based analytics, BI marts
├── python/      Python work plan - forecasts, EOQ/ROP math, scenarios
└── docs/        written report / methodology notes
```

## Tools

- **Excel** - original end-to-end model (`analysis/supply-chain-model.xlsx`)
- **SQL** - data model, demand windows, capacity/breakeven tables, dashboard marts
  (`sql/supply_chain_sql_work.sql`)
- **Python** - region forecasts, EOQ / newsvendor ROP, cash-flow scenarios, Excel
  parity checks (`python/supply_chain_python_work.py`)
- **Power BI / Tableau** - dashboard (planned after SQL + Python replication)

## Usage

### Excel (baseline)

Open `analysis/supply-chain-model.xlsx` in Excel (or a compatible spreadsheet
application). The workbook covers all five regions - **Calopeia**, **Sorange**,
**Tyran**, **Fardo**, and **Entworpe** - with a **Summary** sheet, a
**Consolidated data** sheet, and per-region detail sheets. Named ranges are
used throughout (e.g. `SS_Calopeia`, `Holding_cost`, `Cycle_length_Fardo`) to
make formulas easier to trace back to the **Summary** sheet.

### SQL + Python (replication in progress)

Both files are beginner-friendly step-by-step checklists. Do the steps in order.

| File | Role |
|---|---|
| `sql/supply_chain_sql_work.sql` | Tables, load demand, averages by day/phase, store results, dashboard views later |
| `python/supply_chain_python_work.py` | Read Excel, forecasts, EOQ/ROP math, build & cash-flow decisions, save CSV for SQL |

Only **demand history** starts from `data/demand_by_region.xlsx`. Costs and game-day rules come from the Excel Summary / scenario rules.

Dashboard work (Power BI or Tableau) starts after SQL + Python can match the Excel Summary outputs.

## Acknowledgments & License

The Jacobs Industries scenario is based on the **Supply Chain Game**,
developed by Professors Sunil Chopra and Philipp Afeche at the Kellogg School
of Management, Northwestern University. It was completed as coursework for
**MGT 267: Applied Business Forecasting** at the University of California,
Riverside, guided by Professor Suri Gurmurthi.

This repository contains original analysis, forecasting, and optimization
work produced for that course. The underlying simulation and scenario content
belong to their original authors/institution.
