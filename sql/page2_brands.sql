-- Brand cleaning: ~1,100 raw spellings -> clean brand, group and origin.
-- Anything that matches no rule ends up as 'Other'.

USE CarsEU;
GO

UPDATE dbo.fact_registrations SET brand = 'UNKNOWN' WHERE brand IS NULL;
GO

-- Spelling rules, lowest priority wins
DROP TABLE IF EXISTS dbo.brand_rules;
CREATE TABLE dbo.brand_rules (
    priority     INT           NOT NULL,
    pattern      NVARCHAR(100) NOT NULL,
    brand_clean  NVARCHAR(50)  NOT NULL
);

INSERT INTO dbo.brand_rules (priority, pattern, brand_clean) VALUES
-- specific names first
(10, '%GENESIS',            'Genesis'),
(11, 'GENESIS',             'Genesis'),
(12, 'FIAT ABARTH',         'Abarth'),
(13, 'ABARTH',              'Abarth'),
(14, 'CITROEN%DS',          'DS'),
(15, 'SITROENDS',           'DS'),
(16, 'DS',                  'DS'),
(17, 'DS AUTOMOBILES',      'DS'),
(18, '%LAMBORGHIN%',        'Lamborghini'),
(19, 'JAECOO%',             'Jaecoo'),
(20, 'JAECCOO',             'Jaecoo'),
(21, 'OMODA%',              'Omoda'),
(22, 'CHERY%OMODA',         'Omoda'),
(23, 'EXEED%',              'Chery'),
-- Volkswagen Group
(30, '%VOLKSW%',            'Volkswagen'),
(31, 'VW',                  'Volkswagen'),
(32, 'VOLSKWAGEN',          'Volkswagen'),
(33, 'VOLSWAGEN',           'Volkswagen'),
(34, 'VOLKWAGEN%',          'Volkswagen'),
(35, 'WOLKSWAGEN',          'Volkswagen'),
(36, 'VOLKSVAGEN',          'Volkswagen'),
(37, 'FAW VW',              'Volkswagen'),
(38, '%KODA%',              'Skoda'),
(39, 'AUDI%',               'Audi'),
(40, 'ABT AUDI',            'Audi'),
(41, 'SEAT%',               'Seat'),
(42, 'CUPRA',               'Cupra'),
(43, 'PORSCHE%',            'Porsche'),
(44, 'PORCHE',              'Porsche'),
(45, 'PORSDCHE',            'Porsche'),
(46, 'BENTLEY%',            'Bentley'),
-- Stellantis
(50, 'PEUGEOT%',            'Peugeot'),
(51, 'AUTOMOBILES PEUGEOT', 'Peugeot'),
(52, 'CITROEN%',            'Citroen'),
(53, 'AUTOMOBILES CITROEN', 'Citroen'),
(54, 'OPEL%',               'Opel'),
(55, 'VAUXHALL',            'Opel'),
(56, 'OPEK',                'Opel'),
(57, 'FIAT%',               'Fiat'),
(58, 'FCA%',                'Fiat'),
(59, 'JEEP',                'Jeep'),
(60, 'CHRYSLER LLC JEEP',   'Jeep'),
(61, 'ALFA%ROMEO',          'Alfa Romeo'),
(62, 'LANCIA',              'Lancia'),
(63, 'LENCIA',              'Lancia'),
(64, 'MASERATI',            'Maserati'),
(65, 'CHRYSLER',            'Chrysler'),
(66, 'DODGE',               'Dodge'),
-- Renault Group
(70, 'RENAULT%',            'Renault'),
(71, 'RENALUT',             'Renault'),
(72, 'RENAUL/%',            'Renault'),
(73, 'DACIA%',              'Dacia'),
(74, 'ALPINE',              'Alpine'),
(75, 'SOCIETE DES AUTOMOBILES ALPINE%', 'Alpine'),
-- German premium
(80, 'BMW%',                'BMW'),
(81, 'B M W',               'BMW'),
(82, 'BWM',                 'BMW'),
(83, 'BAYER%BMW',           'BMW'),
(84, 'ALPINA',              'BMW'),
(85, 'MINI',                'Mini'),
(86, 'ROLLS%',              'Rolls-Royce'),
(87, '%MERCEDES%',          'Mercedes-Benz'),
(88, 'MERCEDEZ%',           'Mercedes-Benz'),
(89, 'MERCDES%',            'Mercedes-Benz'),
(90, 'MERCSDES%',           'Mercedes-Benz'),
(91, 'MERCEDS%',            'Mercedes-Benz'),
(92, '3ERCEDES%',           'Mercedes-Benz'),
(93, 'DAIMLER%',            'Mercedes-Benz'),
(94, 'SMART',               'Smart'),
-- Japan
(100, 'TOYOTA%',            'Toyota'),
(101, 'T0YOTA',             'Toyota'),
(102, 'LEXUS',              'Lexus'),
(103, 'LEXSUS',             'Lexus'),
(104, 'NISSAN',             'Nissan'),
(105, 'HONDA%',             'Honda'),
(106, 'MAZDA%',             'Mazda'),
(107, 'SUZUKI%',            'Suzuki'),
(108, '%SUZUKI',            'Suzuki'),
(109, 'SUBARU%',            'Subaru'),
(110, 'FUJI HEAVY%',        'Subaru'),
(111, 'MITSUBISHI%',        'Mitsubishi'),
-- Korea
(120, 'HYUNDAI%',           'Hyundai'),
(121, 'HUUNDAI',            'Hyundai'),
(122, 'KIA%',               'Kia'),
(123, '%SSANG%',            'KGM (SsangYong)'),
(124, 'SANGYONG',           'KGM (SsangYong)'),
(125, 'SAANGYONG',          'KGM (SsangYong)'),
(126, 'SSNGYONG',           'KGM (SsangYong)'),
(127, 'SSAYNGYONG',         'KGM (SsangYong)'),
(128, 'KG MOB%',            'KGM (SsangYong)'),
(129, 'KGM%',               'KGM (SsangYong)'),
-- USA
(130, 'FORD%',              'Ford'),
(131, 'F0RD%',              'Ford'),
(132, 'DROF',               'Ford'),
(133, 'TESLA%',             'Tesla'),
(134, 'CHEVROLET',          'Chevrolet'),
(135, 'CHERVOLET',          'Chevrolet'),
(136, 'CADILLAC',           'Cadillac'),
(137, '%FISKER%',           'Fisker'),
(138, 'LUCID%',             'Lucid'),
-- Geely Holding and others in Europe
(140, 'VOLVO%',             'Volvo'),
(141, 'VOVLO',              'Volvo'),
(142, 'POLESTAR',           'Polestar'),
(143, 'LYNK%',              'Lynk & Co'),
(144, 'LINK&CO',            'Lynk & Co'),
(145, 'ZEEKR%',             'Zeekr'),
(146, 'GEELY',              'Geely'),
(147, 'LOTUS%',             'Lotus'),
(150, 'JAGUAR%',            'Jaguar'),
(151, 'LAND%ROVER%',        'Land Rover'),
(152, 'LANDROVER%',         'Land Rover'),
(153, 'RANGE%ROVER',        'Land Rover'),
(154, 'FERRARI',            'Ferrari'),
(155, 'ASTON%',             'Aston Martin'),
(156, 'MCLAREN%',           'McLaren'),
(157, 'MC LAREN',           'McLaren'),
(158, 'INEOS%',             'Ineos'),
(159, 'INESO',              'Ineos'),
(160, 'DR',                 'DR'),
(161, 'DR AUTOMOBILES%',    'DR'),
(162, 'EBRO',               'Ebro'),
(163, 'EVO',                'EVO'),
(164, 'EMC',                'EMC'),
-- China
(170, 'BYD',                'BYD'),
(171, 'DENZA',              'BYD'),
(172, 'MG%',                'MG'),
(173, 'M G',                'MG'),
(174, 'SAIC MG',            'MG'),
(175, 'ROEWE',              'MG'),
(176, 'MAXUS%',             'Maxus'),
(177, 'CHERY%',             'Chery'),
(178, 'XPENG',              'XPeng'),
(179, 'LEAPMOTOR',          'Leapmotor'),
(180, 'NIO',                'NIO'),
(181, 'XIAOMI',             'Xiaomi'),
(182, 'AIWAYS',             'Aiways'),
(183, 'BAIC%',              'BAIC'),
(184, 'DAIC%',              'BAIC'),
(185, 'BEIJING AUTOMOTIVE%','BAIC'),
(186, 'GREAT WALL%',        'Great Wall (GWM)'),
(187, 'ORA',                'Great Wall (GWM)'),
(188, 'WEY',                'Great Wall (GWM)'),
(189, 'HAVAL',              'Great Wall (GWM)'),
(190, 'TANK',               'Great Wall (GWM)'),
(191, 'DFSK%',              'DFSK / Seres'),
(192, 'SERES%',             'DFSK / Seres'),
(193, 'DONG%FENG',          'Dongfeng'),
(194, 'DFM',                'Dongfeng'),
(195, 'VOYAH',              'Dongfeng'),
(196, 'FORTHING%',          'Dongfeng'),
(197, 'JAC',                'JAC'),
(198, 'SKYWELL%',           'Skywell'),
(199, 'SKYWORTH',           'Skywell'),
(200, 'HONGQI%',            'Hongqi'),
(201, 'HONG QI',            'Hongqi'),
(202, 'CHANGAN%',           'Changan'),
(203, 'DEEPAL%',            'Changan'),
(204, 'FAW',                'FAW'),
(205, 'SWM%',               'SWM'),
(206, 'SHINERAY%',          'SWM'),
(207, 'MORGAN%',            'Morgan'),
(208, 'CATERHAM%',          'Caterham'),
-- other origins
(210, 'LADA%',              'Lada'),
(211, 'AVTOVAZ',            'Lada'),
(212, 'MAHINDRA',           'Mahindra'),
(213, 'VINFAST',            'VinFast'),
(214, 'TOGG',               'Togg'),
(215, 'T%RKIYE%',           'Togg'),
-- missing brand
(900, 'UNKNOWN',            'Unknown');
GO

-- Group and origin per brand
DROP TABLE IF EXISTS dbo.brand_info;
CREATE TABLE dbo.brand_info (
    brand_clean         NVARCHAR(50) NOT NULL PRIMARY KEY,
    manufacturer_group  NVARCHAR(50) NOT NULL,
    origin_country      NVARCHAR(50) NOT NULL,
    origin_region       NVARCHAR(20) NOT NULL
);

INSERT INTO dbo.brand_info VALUES
('Volkswagen','Volkswagen Group','Germany','Europe'),
('Audi','Volkswagen Group','Germany','Europe'),
('Skoda','Volkswagen Group','Czechia','Europe'),
('Seat','Volkswagen Group','Spain','Europe'),
('Cupra','Volkswagen Group','Spain','Europe'),
('Porsche','Volkswagen Group','Germany','Europe'),
('Lamborghini','Volkswagen Group','Italy','Europe'),
('Bentley','Volkswagen Group','United Kingdom','Europe'),
('Peugeot','Stellantis','France','Europe'),
('Citroen','Stellantis','France','Europe'),
('DS','Stellantis','France','Europe'),
('Opel','Stellantis','Germany','Europe'),
('Fiat','Stellantis','Italy','Europe'),
('Abarth','Stellantis','Italy','Europe'),
('Alfa Romeo','Stellantis','Italy','Europe'),
('Lancia','Stellantis','Italy','Europe'),
('Maserati','Stellantis','Italy','Europe'),
('Jeep','Stellantis','USA','USA'),
('Chrysler','Stellantis','USA','USA'),
('Dodge','Stellantis','USA','USA'),
('Renault','Renault Group','France','Europe'),
('Dacia','Renault Group','Romania','Europe'),
('Alpine','Renault Group','France','Europe'),
('BMW','BMW Group','Germany','Europe'),
('Mini','BMW Group','United Kingdom','Europe'),
('Rolls-Royce','BMW Group','United Kingdom','Europe'),
('Mercedes-Benz','Mercedes-Benz Group','Germany','Europe'),
('Smart','Mercedes-Benz & Geely (JV)','Germany','Europe'),
('Toyota','Toyota Group','Japan','Japan'),
('Lexus','Toyota Group','Japan','Japan'),
('Nissan','Nissan','Japan','Japan'),
('Honda','Honda','Japan','Japan'),
('Mazda','Mazda','Japan','Japan'),
('Suzuki','Suzuki','Japan','Japan'),
('Subaru','Subaru','Japan','Japan'),
('Mitsubishi','Mitsubishi','Japan','Japan'),
('Hyundai','Hyundai Motor Group','South Korea','Korea'),
('Kia','Hyundai Motor Group','South Korea','Korea'),
('Genesis','Hyundai Motor Group','South Korea','Korea'),
('KGM (SsangYong)','KG Mobility','South Korea','Korea'),
('Ford','Ford','USA','USA'),
('Tesla','Tesla','USA','USA'),
('Chevrolet','General Motors','USA','USA'),
('Cadillac','General Motors','USA','USA'),
('Fisker','Fisker','USA','USA'),
('Lucid','Lucid','USA','USA'),
('Volvo','Geely Holding','Sweden','Europe'),
('Polestar','Geely Holding','Sweden','Europe'),
('Lotus','Geely Holding','United Kingdom','Europe'),
('Lynk & Co','Geely Holding','China','China'),
('Zeekr','Geely Holding','China','China'),
('Geely','Geely Holding','China','China'),
('Jaguar','Tata Motors (JLR)','United Kingdom','Europe'),
('Land Rover','Tata Motors (JLR)','United Kingdom','Europe'),
('Ferrari','Ferrari','Italy','Europe'),
('Aston Martin','Aston Martin','United Kingdom','Europe'),
('McLaren','McLaren','United Kingdom','Europe'),
('Ineos','Ineos','United Kingdom','Europe'),
('DR','DR Automobiles','Italy','Europe'),
('Ebro','Ebro','Spain','Europe'),
('EVO','EVO','Italy','Europe'),
('EMC','EMC','Spain','Europe'),
('BYD','BYD','China','China'),
('MG','SAIC Motor','China','China'),
('Maxus','SAIC Motor','China','China'),
('Chery','Chery','China','China'),
('Omoda','Chery','China','China'),
('Jaecoo','Chery','China','China'),
('XPeng','XPeng','China','China'),
('Leapmotor','Leapmotor','China','China'),
('NIO','NIO','China','China'),
('Xiaomi','Xiaomi','China','China'),
('Aiways','Aiways','China','China'),
('BAIC','BAIC','China','China'),
('Great Wall (GWM)','Great Wall Motor','China','China'),
('DFSK / Seres','Seres','China','China'),
('Dongfeng','Dongfeng','China','China'),
('JAC','JAC','China','China'),
('Skywell','Skywell','China','China'),
('Hongqi','FAW','China','China'),
('Changan','Changan','China','China'),
('FAW','FAW','China','China'),
('SWM','SWM','China','China'),
('Morgan','Morgan','United Kingdom','Europe'),
('Caterham','Caterham','United Kingdom','Europe'),
('Lada','AvtoVAZ','Russia','Other'),
('Mahindra','Mahindra','India','Other'),
('VinFast','VinFast','Vietnam','Other'),
('Togg','Togg','Turkey','Other'),
('Unknown','Unknown','Unknown','Unknown'),
('Other','Other','Other','Other');
GO

-- dim_brand: one row per raw spelling
DROP TABLE IF EXISTS dbo.dim_brand;
GO

WITH spellings AS (
    SELECT DISTINCT brand FROM dbo.fact_registrations
),
matched AS (
    SELECT s.brand,
           ISNULL((SELECT TOP 1 r.brand_clean
                   FROM dbo.brand_rules r
                   WHERE s.brand LIKE r.pattern
                   ORDER BY r.priority), 'Other') AS brand_clean
    FROM spellings s
)
SELECT m.brand,
       m.brand_clean,
       i.manufacturer_group,
       i.origin_country,
       i.origin_region
INTO dbo.dim_brand
FROM matched m
JOIN dbo.brand_info i ON i.brand_clean = m.brand_clean;
GO

-- Checks
-- duplicates (expect none)
SELECT brand, COUNT(*) AS n FROM dbo.dim_brand GROUP BY brand HAVING COUNT(*) > 1;

-- % of registrations mapped to a real brand
SELECT CAST(100.0 * SUM(CASE WHEN d.brand_clean NOT IN ('Other','Unknown') THEN f.registrations ELSE 0 END)
            / SUM(f.registrations) AS decimal(6,3)) AS pct_mapped
FROM dbo.fact_registrations f
JOIN dbo.dim_brand d ON d.brand = f.brand;

-- biggest spellings left as 'Other'
SELECT TOP 30 f.brand, SUM(f.registrations) AS registrations
FROM dbo.fact_registrations f
JOIN dbo.dim_brand d ON d.brand = f.brand
WHERE d.brand_clean = 'Other'
GROUP BY f.brand
ORDER BY registrations DESC;

-- top 20 brands
SELECT TOP 20 d.brand_clean, d.manufacturer_group, d.origin_region, SUM(f.registrations) AS registrations
FROM dbo.fact_registrations f
JOIN dbo.dim_brand d ON d.brand = f.brand
GROUP BY d.brand_clean, d.manufacturer_group, d.origin_region
ORDER BY registrations DESC;
