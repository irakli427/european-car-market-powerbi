"""Load cars_grouped_*.csv into CarsEU.dbo.raw_cars (all columns as text)."""
import glob

import pandas as pd
import pyodbc
from sqlalchemy import create_engine, text
from sqlalchemy.types import NVARCHAR

SERVER = r"localhost\MSSQLSERVER2"
DATABASE = "CarsEU"
TABLE = "raw_cars"
FILES = sorted(glob.glob("cars_grouped_20*.csv"))

COLUMNS = ["reg_year", "Country", "Man", "Mk", "Cn", "Ft", "Fm", "cars",
           "co2_sum", "co2_cars", "mass_sum", "mass_cars",
           "power_sum", "power_cars", "range_sum", "range_cars"]
LENGTHS = {"Man": 300, "Mk": 150, "Cn": 400, "Ft": 50, "Fm": 10,
           "Country": 10, "reg_year": 10}


def pick_driver():
    available = pyodbc.drivers()
    for name in ["ODBC Driver 18 for SQL Server", "ODBC Driver 17 for SQL Server",
                 "SQL Server"]:
        if name in available:
            return name
    raise SystemExit(f"No SQL Server ODBC driver found. Installed drivers: {available}")


def main():
    if not FILES:
        raise SystemExit("No cars_grouped_20*.csv files found in this folder.")
    driver = pick_driver()
    print("Using ODBC driver:", driver)
    conn_str = (f"mssql+pyodbc://@{SERVER}/{DATABASE}"
                f"?driver={driver.replace(' ', '+')}"
                "&trusted_connection=yes&TrustServerCertificate=yes")
    engine = create_engine(conn_str, fast_executemany=True)

    frames = []
    for f in FILES:
        df = pd.read_csv(f, dtype=str, keep_default_na=False, encoding="utf-8")
        df.columns = COLUMNS
        print(f"{f}: {len(df):,} rows")
        frames.append(df)
    data = pd.concat(frames, ignore_index=True)

    dtypes = {c: NVARCHAR(LENGTHS.get(c, 50)) for c in COLUMNS}
    data.to_sql(TABLE, engine, schema="dbo", if_exists="replace", index=False,
                dtype=dtypes, chunksize=10_000)
    print(f"Loaded {len(data):,} rows into {DATABASE}.dbo.{TABLE}")

    with engine.connect() as con:
        check = con.execute(text(
            f"SELECT reg_year, COUNT(*) AS rows_loaded, "
            f"SUM(CAST(CAST(cars AS float) AS bigint)) AS cars "
            f"FROM dbo.{TABLE} GROUP BY reg_year ORDER BY reg_year")).fetchall()
    for row in check:
        print(f"  {row[0]}: {row[1]:,} rows, {row[2]:,} cars")


if __name__ == "__main__":
    main()
