CREATE SCHEMA IF NOT EXISTS src_helpdesk;
CREATE SCHEMA IF NOT EXISTS src_inventar;

DROP TABLE IF EXISTS src_helpdesk.Bearbeitung CASCADE;
DROP TABLE IF EXISTS src_helpdesk.Ticket CASCADE;
DROP TABLE IF EXISTS src_helpdesk.Kundenbetreuer CASCADE;
DROP TABLE IF EXISTS src_helpdesk.Mitarbeiter CASCADE;
DROP TABLE IF EXISTS src_helpdesk.Kunde CASCADE;

DROP TABLE IF EXISTS src_inventar.Wartung CASCADE;
DROP TABLE IF EXISTS src_inventar.Wartungsvertrag CASCADE;
DROP TABLE IF EXISTS src_inventar.Gerät CASCADE;
DROP TABLE IF EXISTS src_inventar.Standort CASCADE;

CREATE TABLE src_inventar.Standort (
    StandortID INT PRIMARY KEY,
    Standortbezeichnung VARCHAR(100) NOT NULL,
    Region VARCHAR(50) NOT NULL,
    Land VARCHAR(50) NOT NULL
);

CREATE TABLE src_inventar.Gerät (
    GeräteNr INT PRIMARY KEY,
    Gerätetyp VARCHAR(50) NOT NULL, -- z.B. Firewall, Switch, Access Point, Server
    Hersteller VARCHAR(50) NOT NULL,
    Modell VARCHAR(50) NOT NULL,
    StandortID INT NOT NULL REFERENCES src_inventar.Standort(StandortID),
    Anschaffungsdatum DATE NOT NULL
);

CREATE TABLE src_inventar.Wartungsvertrag (
    VertragsNr INT PRIMARY KEY,
    GeräteNr INT NOT NULL REFERENCES src_inventar.Gerät(GeräteNr),
    Vertragsart VARCHAR(50) NOT NULL, -- z.B. 24/7 Premium, 8x5 Standard, Next-Business-Day
    Beginn DATE NOT NULL,
    Ende DATE NOT NULL,
    Kosten_pro_Jahr NUMERIC(10, 2) NOT NULL
);

CREATE TABLE src_inventar.Wartung (
    WartungsNr INT PRIMARY KEY,
    GeräteNr INT NOT NULL REFERENCES src_inventar.Gerät(GeräteNr),
    Datum DATE NOT NULL,
    Wartungsart VARCHAR(50) NOT NULL, -- z.B. Firmware-Update, Komponententausch, Inspektion
    TechnikerNr INT NOT NULL,
    Kosten NUMERIC(10, 2) NOT NULL
);

CREATE TABLE src_helpdesk.Kunde (
    KundenNr INT PRIMARY KEY,
    Kunden_Name VARCHAR(100) NOT NULL,
    Kundentyp VARCHAR(50) NOT NULL, -- z.B. Enterprise, Mittelstand, Behörde
    StandortID INT NOT NULL -- Logischer Verweis auf Standort im Inventarsystem
);

CREATE TABLE src_helpdesk.Kundenbetreuer (
    BetreuerNr INT PRIMARY KEY,
    KundenNr INT NOT NULL REFERENCES src_helpdesk.Kunde(KundenNr),
    Name VARCHAR(100) NOT NULL,
    Team VARCHAR(50) NOT NULL
);

CREATE TABLE src_helpdesk.Mitarbeiter (
    MitarbeiterNr INT PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Team VARCHAR(50) NOT NULL, -- z.B. Network-Core, Security-Ops, Field-Support
    Rolle VARCHAR(50) NOT NULL
);

CREATE TABLE src_helpdesk.Ticket (
    TicketNr INT PRIMARY KEY,
    KundenNr INT NOT NULL REFERENCES src_helpdesk.Kunde(KundenNr),
    GeräteNr INT NOT NULL, -- Logischer Verweis auf Gerät im Inventarsystem
    Erstellungsdatum TIMESTAMP NOT NULL,
    Kategorie VARCHAR(50) NOT NULL, -- z.B. Hardware, Netzwerk, Security
    Priorität VARCHAR(20) NOT NULL, -- z.B. Kritisch, Hoch, Normal
    Status VARCHAR(20) NOT NULL,    -- z.B. Gelöst, Geschlossen
    SLA_Zielzeit_Minuten INT NOT NULL
);

CREATE TABLE src_helpdesk.Bearbeitung (
    BearbeitungsNr INT PRIMARY KEY,
    TicketNr INT NOT NULL REFERENCES src_helpdesk.Ticket(TicketNr),
    MitarbeiterNr INT NOT NULL REFERENCES src_helpdesk.Mitarbeiter(MitarbeiterNr),
    Datum TIMESTAMP NOT NULL,
    Bearbeitungszeit_Minuten INT NOT NULL,
    Aktionstyp VARCHAR(50) NOT NULL -- z.B. Diagnose, Patch, Konfiguration
);

INSERT INTO src_inventar.Standort (StandortID, Standortbezeichnung, Region, Land) VALUES
(1, 'HQ Frankfurt', 'Hessen', 'Deutschland'),
(2, 'Niederlassung München', 'Bayern', 'Deutschland'),
(3, 'Logistikzentrum Leipzig', 'Sachsen', 'Deutschland'),
(4, 'Campus Berlin', 'Berlin', 'Deutschland'),
(5, 'Zweigstelle Hamburg', 'Hamburg', 'Deutschland'),
(6, 'Datacenter Nürnberg', 'Bayern', 'Deutschland');

-- 25 Geräte (verteilt auf Standorte 1 bis 6)
INSERT INTO src_inventar.Gerät (GeräteNr, Gerätetyp, Hersteller, Modell, StandortID, Anschaffungsdatum)
SELECT 
    i AS GeräteNr,
    (ARRAY['Firewall', 'Core-Switch', 'Access Point', 'Server', 'Storage-Node'])[((i - 101) % 5) + 1] AS Gerätetyp,
    (ARRAY['Fortinet', 'Cisco', 'Aruba', 'Dell', 'NetApp'])[((i - 101) % 5) + 1] AS Hersteller,
    'Modell-Serie-' || chr(65 + ((i - 101) % 5)) || ((i - 101) * 10)::text AS Modell,
    ((i - 101) % 6) + 1 AS StandortID,
    ('2021-01-01'::date + (i * 37 % 900) * interval '1 day')::date AS Anschaffungsdatum
FROM generate_series(101, 125) AS i;

-- 25 Wartungsverträge (1 pro Gerät)
INSERT INTO src_inventar.Wartungsvertrag (VertragsNr, GeräteNr, Vertragsart, Beginn, Ende, Kosten_pro_Jahr)
SELECT 
    5000 + (i - 100) AS VertragsNr,
    i AS GeräteNr,
    (ARRAY['24/7 Premium', '8x5 Standard', 'Next-Business-Day'])[((i - 101) % 3) + 1] AS Vertragsart,
    '2024-01-01'::date AS Beginn,
    '2024-12-31'::date AS Ende,
    (ARRAY[4800.00, 2400.00, 1200.00, 6000.00, 3600.00])[((i - 101) % 5) + 1] AS Kosten_pro_Jahr
FROM generate_series(101, 125) AS i;

-- 50 Wartungseinsätze (verteilt über das Jahr 2024)
INSERT INTO src_inventar.Wartung (WartungsNr, GeräteNr, Datum, Wartungsart, TechnikerNr, Kosten)
SELECT 
    9000 + i AS WartungsNr,
    101 + ((i * 7) % 25) AS GeräteNr,
    ('2024-01-10'::date + ((i * 7) % 340) * interval '1 day')::date AS Datum,
    (ARRAY['Firmware-Update', 'Komponententausch', 'Regelprüfung', 'Sicherheitsaudit'])[((i - 1) % 4) + 1] AS Wartungsart,
    80 + (i % 5) AS TechnikerNr,
    ((150 + ((i * 33) % 850))::numeric)::numeric(10, 2) AS Kosten
FROM generate_series(1, 50) AS i;

-- 10 Firmenkunden
INSERT INTO src_helpdesk.Kunde (KundenNr, Kunden_Name, Kundentyp, StandortID) VALUES
(201, 'FinTech Global AG', 'Enterprise', 1),
(202, 'Bavaria Industrie GmbH', 'Mittelstand', 2),
(203, 'Saxony Express Logistik', 'Mittelstand', 3),
(204, 'Capital City Media', 'Enterprise', 4),
(205, 'Hanseatic Trade Corp', 'Enterprise', 5),
(206, 'Franconia Chip Design', 'Mittelstand', 6),
(207, 'Rhein-Main Software', 'Startup', 1),
(208, 'Alpine Sensorik AG', 'Mittelstand', 2),
(209, 'Elbe Retail Hub', 'Startup', 3),
(210, 'Nordic Cloud Systems', 'Enterprise', 5);

-- 6 Kundenbetreuer
INSERT INTO src_helpdesk.Kundenbetreuer (BetreuerNr, KundenNr, Name, Team) VALUES
(301, 201, 'Sarah Weber', 'Key Accounts'),
(302, 202, 'Markus Lang', 'Regional Süd'),
(303, 203, 'Elena Koch', 'Regional Ost'),
(304, 204, 'David Wagner', 'Key Accounts'),
(305, 205, 'Julia Neumann', 'Regional Nord'),
(306, 206, 'Markus Lang', 'Regional Süd');

-- 8 Helpdesk-Mitarbeiter
INSERT INTO src_helpdesk.Mitarbeiter (MitarbeiterNr, Name, Team, Rolle) VALUES
(401, 'Felix Richter', 'Security-Ops', 'Senior Security Engineer'),
(402, 'Lisa Bauer', 'Network-Core', 'Network Specialist'),
(403, 'Jan Vogel', 'Field-Support', 'Support Engineer'),
(404, 'Laura Schmidt', 'Security-Ops', 'Security Analyst'),
(405, 'Tim Keller', 'Network-Core', 'Network Administrator'),
(406, 'Sophie Meier', 'Field-Support', 'Junior Technician'),
(407, 'Christian Wolf', 'App-Support', 'Application Specialist'),
(408, 'Anna Becker', 'App-Support', 'Senior Application Engineer');

-- 50 Tickets (verteilt auf Kunden, Geräte, Kategorien und SLAs)
INSERT INTO src_helpdesk.Ticket (TicketNr, KundenNr, GeräteNr, Erstellungsdatum, Kategorie, Priorität, Status, SLA_Zielzeit_Minuten)
SELECT 
    1000 + i AS TicketNr,
    201 + (i % 10) AS KundenNr,
    101 + ((i * 3) % 25) AS GeräteNr,
    ('2024-01-05 08:00:00'::timestamp + ((i * 7) % 340) * interval '1 day' + (i * 37 % 600) * interval '1 minute') AS Erstellungsdatum,
    (ARRAY['Hardware', 'Netzwerk', 'Security', 'Software'])[((i - 1) % 4) + 1] AS Kategorie,
    (CASE 
        WHEN i % 5 = 0 THEN 'Kritisch'
        WHEN i % 3 = 0 THEN 'Hoch'
        ELSE 'Normal'
     END) AS Priorität,
    'Geschlossen' AS Status,
    (CASE 
        WHEN i % 5 = 0 THEN 120   -- Kritisch: 2h
        WHEN i % 3 = 0 THEN 240   -- Hoch: 4h
        ELSE 480                  -- Normal: 8h
     END) AS SLA_Zielzeit_Minuten
FROM generate_series(1, 50) AS i;

-- 75 Bearbeitungsschritte (1 bis 2 Schritte pro Ticket, realistischer SLA-Mix)
INSERT INTO src_helpdesk.Bearbeitung (BearbeitungsNr, TicketNr, MitarbeiterNr, Datum, Bearbeitungszeit_Minuten, Aktionstyp)
SELECT 
    8000 + i AS BearbeitungsNr,
    1000 + (((i - 1) % 50) + 1) AS TicketNr,
    401 + (i % 8) AS MitarbeiterNr,
    ('2024-01-05 08:30:00'::timestamp + ((i * 5) % 340) * interval '1 day' + (i * 45 % 400) * interval '1 minute') AS Datum,
    -- Variierende Zeiten: Manche unterschreiten, manche überziehen die SLA-Zeit deutlich
    (CASE 
        WHEN i % 7 = 0 THEN 280   -- Überschreitung bei kritischen/hohen Tickets
        WHEN i % 4 = 0 THEN 160
        WHEN i % 3 = 0 THEN 90
        ELSE 45
     END) AS Bearbeitungszeit_Minuten,
    (ARRAY['Diagnose', 'Konfiguration', 'Patch', 'Komponententausch', 'Abschlusstest'])[((i - 1) % 5) + 1] AS Aktionstyp
FROM generate_series(1, 75) AS i;
