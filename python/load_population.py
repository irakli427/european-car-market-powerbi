"""Load Eurostat population (tps00001, 1 January) into CarsEU.dbo.population."""
import glob

import pandas as pd
import pyodbc
from sqlalchemy import create_engine, text
from sqlalchemy.types import Integer, BigInteger, NVARCHAR

SERVER = r"localhost\MSSQLSERVER2"
DATABASE = "CarsEU"
YEARS = [2021, 2022, 2023, 2024, 2025]

NAMES = {
    "Austria": "AT", "Belgium": "BE", "Bulgaria": "BG", "Croatia": "HR", "Cyprus": "CY",
    "Czechia": "CZ", "Denmark": "DK", "Estonia": "EE", "Finland": "FI", "France": "FR",
    "Germany": "DE", "Greece": "GR", "Hungary": "HU", "Ireland": "IE", "Italy": "IT",
    "Latvia": "LV", "Lithuania": "LT", "Luxembourg": "LU", "Malta": "MT",
    "Netherlands": "NL", "Poland": "PL", "Portugal": "PT", "Romania": "RO",
    "Slovakia": "SK", "Slovenia": "SI", "Spain": "ES", "Sweden": "SE",
    "Iceland": "IS", "Norway": "NO",
}
CODES = set(NAMES.values())


def to_code(geo):
    geo = str(geo).strip()
    part = geo.split(":")[0].strip()
    if part == "EL":
        return "GR"
    if part in CODES:
        return part
    return NAMES.get(geo.split(":")[-1].strip())


def pick_driver():
    for name in ["ODBC Driver 18 for SQL Server", "ODBC Driver 17 for SQL Server", "SQL Server"]:
        if name in pyodbc.drivers():
            return name
    raise SystemExit(f"No SQL Server ODBC driver found: {pyodbc.drivers()}")


def main():
    files = sorted(glob.glob("tps00001*.csv"))
    if not files:
        raise SystemExit("No file starting with tps00001 and ending with .csv in this folder.")
    raw = pd.read_csv(files[0], dtype=str)
    cols = {c.lower(): c for c in raw.columns}
    for need in ["geo", "time_period", "obs_value"]:
        if need not in cols:
            raise SystemExit(f"Column '{need}' not found. Columns are: {list(raw.columns)}")

    df = pd.DataFrame({
        "country_code": raw[cols["geo"]].map(to_code),
        "registration_year": pd.to_numeric(raw[cols["time_period"]].str[:4], errors="coerce"),
        "population": pd.to_numeric(raw[cols["obs_value"]], errors="coerce"),
    }).dropna()
    df = df[df["registration_year"].isin(YEARS)]
    df = df.drop_duplicates(["country_code", "registration_year"])
    df["registration_year"] = df["registration_year"].astype(int)
    df["population"] = df["population"].astype("int64")

    missing = [(c, y) for c in sorted(CODES) for y in YEARS
               if not ((df.country_code == c) & (df.registration_year == y)).any()]
    print(f"{len(df)} rows for {df.country_code.nunique()} countries")
    if missing:
        print("Missing country/year combinations:", missing)

    driver = pick_driver()
    engine = create_engine(
        f"mssql+pyodbc://@{SERVER}/{DATABASE}?driver={driver.replace(' ', '+')}"
        "&trusted_connection=yes&TrustServerCertificate=yes", fast_executemany=True)
    df.to_sql("population", engine, schema="dbo", if_exists="replace", index=False,
              dtype={"country_code": NVARCHAR(10), "registration_year": Integer(),
                     "population": BigInteger()})
    with engine.connect() as con:
        rows = con.execute(text(
            "SELECT registration_year, SUM(population) FROM dbo.population "
            "GROUP BY registration_year ORDER BY registration_year")).fetchall()
    for y, p in rows:
        print(f"  {y}: {p:,} people")


if __name__ == "__main__":
    main()
