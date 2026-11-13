"""Aggregate the EEA CO2 cars downloads (raw/*.csv) into cars_grouped_<year>.csv.

Values are stored as sums + counts so weighted averages can be computed later.
Source: https://co2cars.apps.eea.europa.eu/
"""
import glob
import os

import pandas as pd

RAW_DIR = "raw"
GROUP_COLS = ["year", "Country", "Man", "Mk", "Cn", "Ft", "Fm"]
VALUE_COLS = {
    "co2": "Ewltp (g/km)",
    "mass": "m (kg)",
    "power": "ep (KW)",
    "range": "Electric range (km)",
}
USE_COLS = GROUP_COLS + ["r"] + list(VALUE_COLS.values())
CHUNK = 500_000


def group_chunk(df):
    df["r"] = pd.to_numeric(df["r"], errors="coerce").fillna(1)
    out = {"cars": df["r"]}
    for short, col in VALUE_COLS.items():
        v = pd.to_numeric(df[col], errors="coerce")
        out[f"{short}_sum"] = v * df["r"]
        out[f"{short}_cars"] = df["r"].where(v.notna(), 0)
    tmp = pd.concat([df[GROUP_COLS], pd.DataFrame(out)], axis=1)
    return tmp.groupby(GROUP_COLS, dropna=False).sum().reset_index()


def main():
    files = sorted(glob.glob(os.path.join(RAW_DIR, "*.csv")))
    if not files:
        raise SystemExit(f"No CSV files found in {RAW_DIR}\\")
    parts = []
    for path in files:
        print(f"Reading {path}")
        for i, chunk in enumerate(pd.read_csv(path, usecols=lambda c: c in USE_COLS,
                                              dtype=str, chunksize=CHUNK,
                                              encoding="utf-8", low_memory=False)):
            missing = [c for c in USE_COLS if c not in chunk.columns]
            if missing:
                raise SystemExit(f"{path} is missing columns: {missing}")
            parts.append(group_chunk(chunk))
            print(f"  chunk {i + 1} done")
    result = pd.concat(parts).groupby(GROUP_COLS, dropna=False).sum().reset_index()
    order = GROUP_COLS + ["cars"] + [f"{s}_{k}" for s in VALUE_COLS for k in ("sum", "cars")]
    result = result[order]
    for year, df in result.groupby("year"):
        out_file = f"cars_grouped_{year}.csv"
        df.to_csv(out_file, index=False, lineterminator="\n", encoding="utf-8")
        print(f"Saved {out_file}: {len(df):,} rows, {int(df['cars'].sum()):,} cars")


if __name__ == "__main__":
    main()
