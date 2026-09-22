CREATE SCHEMA IF NOT EXISTS staging;
--CREATE SCHEMA IF NOT EXISTS core;
--CREATE SCHEMA IF NOT EXISTS business;

-- Staging für Quellsystem 1 (Helpdesk)
DROP TABLE IF EXISTS staging.stg_hd_ticket CASCADE;
CREATE TABLE staging.stg_hd_ticket (
    TicketNr INT,
    KundenNr INT,
    GeräteNr INT,
    Erstellungsdatum TIMESTAMP,
    Kategorie VARCHAR(50),
    Priorität VARCHAR(20),
    Status VARCHAR(20),
    SLA_Zielzeit_Minuten INT,
    stg_loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS staging.stg_hd_bearbeitung CASCADE;
CREATE TABLE staging.stg_hd_bearbeitung (
    BearbeitungsNr INT,
    TicketNr INT,
    MitarbeiterNr INT,
    Datum TIMESTAMP,
    Bearbeitungszeit_Minuten INT,
    Aktionstyp VARCHAR(50),
    stg_loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS staging.stg_hd_kunde CASCADE;
CREATE TABLE staging.stg_hd_kunde (
    KundenNr INT,
    Kunden_Name VARCHAR(100),
    Kundentyp VARCHAR(50),
    StandortID INT,
    stg_loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS staging.stg_hd_mitarbeiter CASCADE;
CREATE TABLE staging.stg_hd_mitarbeiter (
    MitarbeiterNr INT,
    Name VARCHAR(100),
    Team VARCHAR(50),
    Rolle VARCHAR(50),
    stg_loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Staging für Quellsystem 2 (Inventar & Wartung)
DROP TABLE IF EXISTS staging.stg_inv_standort CASCADE;
CREATE TABLE staging.stg_inv_standort (
    StandortID INT,
    Standortbezeichnung VARCHAR(100),
    Region VARCHAR(50),
    Land VARCHAR(50),
    stg_loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS staging.stg_inv_geraet CASCADE;
CREATE TABLE staging.stg_inv_geraet (
    GeräteNr INT,
    Gerätetyp VARCHAR(50),
    Hersteller VARCHAR(50),
    Modell VARCHAR(50),
    StandortID INT,
    Anschaffungsdatum DATE,
    stg_loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS staging.stg_inv_wartungsvertrag CASCADE;
CREATE TABLE staging.stg_inv_wartungsvertrag (
    VertragsNr INT,
    GeräteNr INT,
    Vertragsart VARCHAR(50),
    Beginn DATE,
    Ende DATE,
    Kosten_pro_Jahr NUMERIC(10, 2),
    stg_loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS staging.stg_inv_wartung CASCADE;
CREATE TABLE staging.stg_inv_wartung (
    WartungsNr INT,
    GeräteNr INT,
    Datum DATE,
    Wartungsart VARCHAR(50),
    TechnikerNr INT,
    Kosten NUMERIC(10, 2),
    stg_loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);