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
└── docs/        business requirements, methodology, decision log
```

## Tools

Currently: Excel. Planned: SQL, Python, and a BI dashboard (Power BI/Tableau).

## Usage

Open `analysis/supply-chain-model.xlsx` in Excel (or a compatible spreadsheet
application). The workbook covers all five regions - **Calopeia**, **Sorange**,
**Tyran**, **Fardo**, and **Entworpe** - with a **Summary** sheet, a
**Consolidated data** sheet, and per-region detail sheets. Named ranges are
used throughout (e.g. `SS_Calopeia`, `Holding_cost`, `Cycle_length_Fardo`) to
make formulas easier to trace back to the **Summary** sheet.

## Acknowledgments & License

The Jacobs Industries scenario is based on the **Supply Chain Game**,
developed by Professors Sunil Chopra and Philipp Afeche at the Kellogg School
of Management, Northwestern University. It was completed as coursework for
**MGT 267: Applied Business Forecasting** at the University of California,
Riverside, guided by Professor Suri Gurmurthi.

This repository contains original analysis, forecasting, and optimization
work produced for that course. The underlying simulation and scenario content
belong to their original authors/institution.
