-- Clean fact table + country and fuel dimensions (raw_cars stays untouched)

USE CarsEU;
GO

-- Fact table. Some numbers come as '15.0', so cast to float first
DROP TABLE IF EXISTS dbo.fact_registrations;
GO

SELECT
    CAST(TRY_CAST(reg_year AS float) AS int)                   AS registration_year,
    UPPER(LTRIM(RTRIM(Country)))                                AS country_code,
    NULLIF(UPPER(LTRIM(RTRIM(Man))), '')                        AS manufacturer,
    NULLIF(UPPER(LTRIM(RTRIM(Mk))), '')                         AS brand,
    NULLIF(UPPER(LTRIM(RTRIM(Cn))), '')                         AS model,
    LOWER(ISNULL(NULLIF(LTRIM(RTRIM(Ft)), ''), 'unknown'))      AS fuel_type,
    UPPER(ISNULL(NULLIF(LTRIM(RTRIM(Fm)), ''), '?'))            AS fuel_mode,
    CAST(TRY_CAST(cars       AS float) AS bigint)               AS registrations,
    TRY_CAST(co2_sum   AS float)                                AS co2_total,
    CAST(TRY_CAST(co2_cars   AS float) AS bigint)               AS co2_count,
    TRY_CAST(mass_sum  AS float)                                AS mass_total_kg,
    CAST(TRY_CAST(mass_cars  AS float) AS bigint)               AS mass_count,
    TRY_CAST(power_sum AS float)                                AS power_total_kw,
    CAST(TRY_CAST(power_cars AS float) AS bigint)               AS power_count,
    TRY_CAST(range_sum AS float)                                AS range_total_km,
    CAST(TRY_CAST(range_cars AS float) AS bigint)               AS range_count
INTO dbo.fact_registrations
FROM dbo.raw_cars;
GO

-- EL -> GR
UPDATE dbo.fact_registrations SET country_code = 'GR' WHERE country_code = 'EL';
GO

-- single join key for dim_fuel
ALTER TABLE dbo.fact_registrations ADD fuel_key AS (fuel_type + '|' + fuel_mode);
GO

-- Countries
DROP TABLE IF EXISTS dbo.dim_country;
GO

CREATE TABLE dbo.dim_country (
    country_code  NVARCHAR(10)  NOT NULL PRIMARY KEY,
    country_name  NVARCHAR(100) NOT NULL,
    region        NVARCHAR(50)  NOT NULL,
    east_west     NVARCHAR(10)  NOT NULL,
    eu_member     BIT           NOT NULL
);

INSERT INTO dbo.dim_country VALUES
('AT','Austria','Western','West',1),
('BE','Belgium','Western','West',1),
('DE','Germany','Western','West',1),
('FR','France','Western','West',1),
('IE','Ireland','Western','West',1),
('LU','Luxembourg','Western','West',1),
('NL','Netherlands','Western','West',1),
('DK','Denmark','Northern','West',1),
('FI','Finland','Northern','West',1),
('SE','Sweden','Northern','West',1),
('EE','Estonia','Northern','East',1),
('LV','Latvia','Northern','East',1),
('LT','Lithuania','Northern','East',1),
('IS','Iceland','Northern','West',0),
('NO','Norway','Northern','West',0),
('CY','Cyprus','Southern','West',1),
('ES','Spain','Southern','West',1),
('GR','Greece','Southern','West',1),
('IT','Italy','Southern','West',1),
('MT','Malta','Southern','West',1),
('PT','Portugal','Southern','West',1),
('HR','Croatia','Southern','East',1),
('SI','Slovenia','Southern','East',1),
('BG','Bulgaria','Central-Eastern','East',1),
('CZ','Czechia','Central-Eastern','East',1),
('HU','Hungary','Central-Eastern','East',1),
('PL','Poland','Central-Eastern','East',1),
('RO','Romania','Central-Eastern','East',1),
('SK','Slovakia','Central-Eastern','East',1);
GO

-- Fuel groups. Fm = 'H' hybrids are stored as petrol/diesel
DROP TABLE IF EXISTS dbo.dim_fuel;
GO

SELECT DISTINCT
    fuel_key,
    fuel_type,
    fuel_mode,
    CASE
        WHEN fuel_type = 'unknown'                            THEN 'Other'
        WHEN fuel_type = 'electric'                           THEN 'BEV'
        WHEN fuel_mode = 'P'                                  THEN 'PHEV'
        WHEN fuel_mode = 'H' OR fuel_type LIKE '%electric%'   THEN 'Hybrid'
        WHEN fuel_type = 'petrol'                             THEN 'Petrol'
        WHEN fuel_type = 'diesel'                             THEN 'Diesel'
        ELSE 'Other'
    END AS fuel_group
INTO dbo.dim_fuel
FROM dbo.fact_registrations;
GO

-- sort order for charts
ALTER TABLE dbo.dim_fuel ADD fuel_group_order AS (
    CASE fuel_group WHEN 'BEV' THEN 1 WHEN 'PHEV' THEN 2 WHEN 'Hybrid' THEN 3
                    WHEN 'Petrol' THEN 4 WHEN 'Diesel' THEN 5 ELSE 6 END);
GO

-- Checks
-- totals should match the Python output (2021: 9,920,521 ... 2025: 10,833,597)
SELECT registration_year, SUM(registrations) AS registrations
FROM dbo.fact_registrations
GROUP BY registration_year
ORDER BY registration_year;

-- country codes without a name (expect none)
SELECT DISTINCT f.country_code
FROM dbo.fact_registrations f
LEFT JOIN dbo.dim_country c ON c.country_code = f.country_code
WHERE c.country_code IS NULL;

-- fuel mix per year
SELECT f.registration_year, d.fuel_group,
       SUM(f.registrations) AS registrations,
       CAST(100.0 * SUM(f.registrations)
            / SUM(SUM(f.registrations)) OVER (PARTITION BY f.registration_year) AS decimal(5,1)) AS share_pct
FROM dbo.fact_registrations f
JOIN dbo.dim_fuel d ON d.fuel_key = f.fuel_key
GROUP BY f.registration_year, d.fuel_group
ORDER BY f.registration_year, share_pct DESC;