-- Init-Skript der Quellsysteme (nur Schema, keine Beispieldaten)
-- Beispieldaten werden separat erzeugt und eingespielt.

CREATE SCHEMA IF NOT EXISTS src_ticketsystem;
CREATE SCHEMA IF NOT EXISTS src_inventarsystem;

-- Vorhandene Tabellen entfernen (Kindtabellen zuerst)
DROP TABLE IF EXISTS src_ticketsystem.Bearbeitung CASCADE;
DROP TABLE IF EXISTS src_ticketsystem.Ticket CASCADE;
DROP TABLE IF EXISTS src_ticketsystem.Kundenbetreuer CASCADE;
DROP TABLE IF EXISTS src_ticketsystem.Mitarbeiter CASCADE;
DROP TABLE IF EXISTS src_ticketsystem.Kunde CASCADE;

DROP TABLE IF EXISTS src_inventarsystem.Wartung CASCADE;
DROP TABLE IF EXISTS src_inventarsystem.Wartungsvertrag CASCADE;
DROP TABLE IF EXISTS src_inventarsystem.Gerät CASCADE;
DROP TABLE IF EXISTS src_inventarsystem.Standort CASCADE;

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
    Gerätetyp VARCHAR(50) NOT NULL,   -- z.B. Firewall, Switch, Access Point, Server
    Hersteller VARCHAR(50) NOT NULL,
    Modell VARCHAR(50) NOT NULL,
    StandortID INT NOT NULL REFERENCES src_inventarsystem.Standort(StandortID),
    Anschaffungsdatum DATE NOT NULL,
    KundenNr INT NOT NULL             -- Logischer Verweis auf Kunde im Ticketsystem (andere DB-Instanz)
);

CREATE TABLE src_inventarsystem.Wartungsvertrag (
    VertragsNr INT PRIMARY KEY,
    GeräteNr INT NOT NULL REFERENCES src_inventarsystem.Gerät(GeräteNr),
    Vertragsart VARCHAR(50) NOT NULL, -- z.B. 24/7 Premium, 8x5 Standard, Next-Business-Day
    Beginn DATE NOT NULL,
    Ende DATE NOT NULL,
    Kosten_pro_Jahr NUMERIC(10, 2) NOT NULL,
    CHECK (Ende >= Beginn)
);

CREATE TABLE src_inventarsystem.Wartung (
    WartungsNr INT PRIMARY KEY,
    GeräteNr INT NOT NULL REFERENCES src_inventarsystem.Gerät(GeräteNr),
    Datum DATE NOT NULL,
    Wartungsart VARCHAR(50) NOT NULL, -- z.B. Firmware-Update, Komponententausch, Inspektion
    Kosten NUMERIC(10, 2) NOT NULL
);

-- ---------------------------------------------------------------
-- Quellsystem 1: Ticketsystem (Helpdesk/Servicemanagement)
-- ---------------------------------------------------------------

CREATE TABLE src_ticketsystem.Kunde (
    KundenNr INT PRIMARY KEY,
    Kunden_Name VARCHAR(100) NOT NULL,
    Kundentyp VARCHAR(50) NOT NULL    -- z.B. Enterprise, Mittelstand, Startup
);

CREATE TABLE src_ticketsystem.Kundenbetreuer (
    BetreuerNr INT PRIMARY KEY,
    KundenNr INT NOT NULL REFERENCES src_ticketsystem.Kunde(KundenNr),
    Name VARCHAR(100) NOT NULL,
    Team VARCHAR(50) NOT NULL
);

CREATE TABLE src_ticketsystem.Mitarbeiter (
    MitarbeiterNr INT PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Team VARCHAR(50) NOT NULL,        -- z.B. Network-Core, Security-Ops, Field-Support
    Rolle VARCHAR(50) NOT NULL
);

CREATE TABLE src_ticketsystem.Ticket (
    TicketNr INT PRIMARY KEY,
    KundenNr INT NOT NULL REFERENCES src_ticketsystem.Kunde(KundenNr),
    GeräteNr INT NOT NULL,            -- Logischer Verweis auf Gerät im Inventarsystem (andere DB-Instanz)
    Erstellungsdatum DATE NOT NULL,
    Kategorie VARCHAR(50) NOT NULL,   -- z.B. Hardware, Netzwerk, Security, Software
    Priorität VARCHAR(20) NOT NULL CHECK (Priorität IN ('Kritisch', 'Hoch', 'Normal')),
    Status VARCHAR(20) NOT NULL,      -- z.B. Gelöst, Geschlossen
    SLA_Zielzeit_Minuten INT NOT NULL
);

CREATE TABLE src_ticketsystem.Bearbeitung (
    BearbeitungsNr INT PRIMARY KEY,
    TicketNr INT NOT NULL REFERENCES src_ticketsystem.Ticket(TicketNr),
    MitarbeiterNr INT NOT NULL REFERENCES src_ticketsystem.Mitarbeiter(MitarbeiterNr),
    Datum DATE NOT NULL,
    Bearbeitungszeit_Minuten INT NOT NULL,
    Aktionstyp VARCHAR(50) NOT NULL   -- z.B. Diagnose, Patch, Konfiguration
);
