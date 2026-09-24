-- Init-Skript Quellsystem 2: Geräte-/Netzwerkinventar
-- Nur Schema, keine Beispieldaten.
-- Die Beispieldaten werden separat erzeugt und eingespielt.

DROP SCHEMA IF EXISTS src_inventarsystem CASCADE;
CREATE SCHEMA src_inventarsystem;

-- ---------------------------------------------------------------
-- Quellsystem 2: Geräte-/Netzwerkinventar und Wartung
-- ---------------------------------------------------------------

CREATE TABLE src_inventarsystem.Standort (
    StandortID INT PRIMARY KEY,
    Standortbezeichnung VARCHAR(100) NOT NULL,
    Region VARCHAR(50) NOT NULL,
    Land VARCHAR(50) NOT NULL
);

CREATE TABLE src_inventarsystem.Gerät (
    GeräteNr INT PRIMARY KEY,
    Gerätetyp VARCHAR(50) NOT NULL,
    -- z.B. Firewall, Switch, Access Point, Server
    Hersteller VARCHAR(50) NOT NULL,
    Modell VARCHAR(50) NOT NULL,
    StandortID INT NOT NULL
        REFERENCES src_inventarsystem.Standort(StandortID),
    Anschaffungsdatum DATE NOT NULL,
    KundenNr INT NOT NULL
    -- Logischer Verweis auf Kunde im Ticketsystem
    -- (andere Datenbank)
);

CREATE TABLE src_inventarsystem.Wartungsvertrag (
    VertragsNr INT PRIMARY KEY,
    GeräteNr INT NOT NULL
        REFERENCES src_inventarsystem.Gerät(GeräteNr),
    Vertragsart VARCHAR(50) NOT NULL,
    -- z.B. 24/7 Premium, 8x5 Standard, Next-Business-Day
    Beginn DATE NOT NULL,
    Ende DATE NOT NULL,
    Kosten_pro_Jahr NUMERIC(10, 2) NOT NULL,
    CHECK (Ende >= Beginn)
);

CREATE TABLE src_inventarsystem.Wartung (
    WartungsNr INT PRIMARY KEY,
    GeräteNr INT NOT NULL
        REFERENCES src_inventarsystem.Gerät(GeräteNr),
    Datum DATE NOT NULL,
    Wartungsart VARCHAR(50) NOT NULL,
    -- z.B. Firmware-Update, Komponententausch, Inspektion
    Kosten NUMERIC(10, 2) NOT NULL
);