-- =========================================================
-- Init-Skript Data Warehouse
-- Datenbank: datawarehouse
-- Schemata: staging, core, business
-- Nur Struktur (Tabellen, Schlüssel), keine Daten.
-- =========================================================

-- Vor der Ausführung mit der Datenbank datawarehouse verbinden, z. B.:
--   CREATE DATABASE datawarehouse;
--   \connect datawarehouse

DROP SCHEMA IF EXISTS business CASCADE;
DROP SCHEMA IF EXISTS core CASCADE;
DROP SCHEMA IF EXISTS staging CASCADE;

CREATE SCHEMA staging;
CREATE SCHEMA core;
CREATE SCHEMA business;


-- =========================================================
-- 1. STAGING-SCHICHT
-- =========================================================
-- Unveränderte Kopie der für die Analyse benötigten Tabellen aus den
-- beiden Quellsystemen. TS_ = Ticketsystem, IS_ = Inventarsystem.
-- Die Tabellen und Spalten entsprechen 1:1 den Quellsystemen
-- (siehe 01_init_ticketsystem.sql und 01_init_inventarsystem.sql).
-- =========================================================

-- ---------------------------------------------------------
-- Inventarsystem
-- ---------------------------------------------------------

CREATE TABLE staging.IS_Standort (
    StandortID INT PRIMARY KEY,
    Standortbezeichnung VARCHAR(100) NOT NULL,
    Region VARCHAR(50) NOT NULL,
    Land VARCHAR(50) NOT NULL
);

CREATE TABLE staging.IS_Gerät (
    GeräteNr INT PRIMARY KEY,
    Gerätetyp VARCHAR(50) NOT NULL,
    Hersteller VARCHAR(50) NOT NULL,
    Modell VARCHAR(50) NOT NULL,
    StandortID INT NOT NULL,
    Anschaffungsdatum DATE NOT NULL,
    KundenNr INT NOT NULL
);

CREATE TABLE staging.IS_Wartungsvertrag (
    VertragsNr INT PRIMARY KEY,
    GeräteNr INT NOT NULL,
    Vertragsart VARCHAR(50) NOT NULL,
    Beginn DATE NOT NULL,
    Ende DATE NOT NULL,
    Kosten_pro_Jahr NUMERIC(10, 2) NOT NULL
);

CREATE TABLE staging.IS_Wartung (
    WartungsNr INT PRIMARY KEY,
    GeräteNr INT NOT NULL,
    Datum DATE NOT NULL,
    Wartungsart VARCHAR(50) NOT NULL,
    Kosten NUMERIC(10, 2) NOT NULL
);

-- ---------------------------------------------------------
-- Ticketsystem
-- ---------------------------------------------------------

CREATE TABLE staging.TS_Mitarbeiter (
    MitarbeiterNr INT PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Team VARCHAR(50) NOT NULL,
    Rolle VARCHAR(50) NOT NULL
);

CREATE TABLE staging.TS_Ticket (
    TicketNr INT PRIMARY KEY,
    KundenNr INT NOT NULL,
    GeräteNr INT NOT NULL,
    Erstellungsdatum DATE NOT NULL,
    Kategorie VARCHAR(50) NOT NULL,
    Priorität VARCHAR(20) NOT NULL,
    Status VARCHAR(20) NOT NULL,
    SLA_Zielzeit_Minuten INT NOT NULL
);

CREATE TABLE staging.TS_Bearbeitung (
    BearbeitungsNr INT PRIMARY KEY,
    TicketNr INT NOT NULL,
    MitarbeiterNr INT NOT NULL,
    Datum DATE NOT NULL,
    Bearbeitungszeit_Minuten INT NOT NULL,
    Aktionstyp VARCHAR(50) NOT NULL
);

-- Hinweis: Kunde und Kundenbetreuer werden für die beiden aktuellen
-- Fragestellungen nicht benötigt und sind deshalb kein Teil des
-- Staging-Schemas. Wird das offene Thema Dim_Standort.Kunde später über
-- eine eigene Kunden-Dimension gelöst (siehe DWH-Mapping, Variante b),
-- muss staging.TS_Kunde ergänzt werden.


-- =========================================================
-- 2. CORE-SCHICHT
-- =========================================================
-- Besteht aus zwei Bestandteilen:
--   a) je Fragestellung eine Topic-Tabelle (bzw. mehrere Topic-Tabellen,
--      wenn die Quelldaten unterschiedliche Granularität haben)
--   b) je benötigter Dimension eine Core-Dimensionstabelle mit
--      natürlichem Schlüssel
-- Spalten der Topic-Tabellen sind nach dem Muster
-- Quelltabelle_Quellspalte benannt und behalten die natürlichen
-- Schlüssel der Quellsysteme bei.
-- =========================================================

-- ---------------------------------------------------------
-- 2a. Topic-Tabelle Frage 1: SLA-Konformität
-- ---------------------------------------------------------
-- Granularität: ein Bearbeitungsvorgang. Bearbeitung -> Ticket -> Gerät
-- sowie Bearbeitung -> Mitarbeiter sind jeweils n:1-Beziehungen, ein
-- Join dieser Tabellen erzeugt daher keine Mehrfachzählung.

CREATE TABLE core.Topic_SLA_Bearbeitung (
    Bearbeitung_BearbeitungsNr INT PRIMARY KEY,
    Bearbeitung_MitarbeiterNr INT NOT NULL,
    Bearbeitung_Datum DATE NOT NULL,
    Bearbeitung_Bearbeitungszeit_Minuten INT NOT NULL,
    Ticket_TicketNr INT NOT NULL,
    Ticket_Priorität VARCHAR(20) NOT NULL,
    Ticket_SLA_Zielzeit_Minuten INT NOT NULL,
    Gerät_GeräteNr INT NOT NULL,
    Gerät_StandortID INT NOT NULL
);

-- ---------------------------------------------------------
-- 2b. Topic-Tabellen Frage 2: Wartungs- und Vertragskosten
-- ---------------------------------------------------------
-- Wartungen, Wartungsverträge und Tickets hängen alle n:1 an einem
-- Gerät, aber n:m zueinander (ein Gerät hat mehrere Wartungen, mehrere
-- Verträge und mehrere Tickets unabhängig voneinander). Ein direkter
-- Join dieser drei Tabellen würde die Zeilen vervielfachen. Deshalb
-- bleiben sie in der Core-Schicht als drei eigene Topic-Tabellen in
-- ihrer jeweiligen Ursprungsgranularität erhalten. Die Zusammenführung
-- je Gerätetyp, Standort und Monat (inklusive Aufteilung der
-- Vertragskosten auf die Monate der Laufzeit) erfolgt beim Laden der
-- Faktentabelle business.Wartung_Kosten_Facts.

CREATE TABLE core.Topic_Wartungskosten_Wartung (
    Wartung_WartungsNr INT PRIMARY KEY,
    Wartung_Datum DATE NOT NULL,
    Wartung_Kosten NUMERIC(10, 2) NOT NULL,
    Gerät_GeräteNr INT NOT NULL,
    Gerät_Gerätetyp VARCHAR(50) NOT NULL,
    Gerät_StandortID INT NOT NULL
);

CREATE TABLE core.Topic_Wartungskosten_Vertrag (
    Wartungsvertrag_VertragsNr INT PRIMARY KEY,
    Wartungsvertrag_Beginn DATE NOT NULL,
    Wartungsvertrag_Ende DATE NOT NULL,
    Wartungsvertrag_Kosten_pro_Jahr NUMERIC(10, 2) NOT NULL,
    Gerät_GeräteNr INT NOT NULL,
    Gerät_Gerätetyp VARCHAR(50) NOT NULL,
    Gerät_StandortID INT NOT NULL
);

CREATE TABLE core.Topic_Wartungskosten_Ticket (
    Ticket_TicketNr INT PRIMARY KEY,
    Ticket_Erstellungsdatum DATE NOT NULL,
    Gerät_GeräteNr INT NOT NULL,
    Gerät_Gerätetyp VARCHAR(50) NOT NULL,
    Gerät_StandortID INT NOT NULL
);

-- ---------------------------------------------------------
-- 2c. Core-Dimensionstabellen (natürlicher Schlüssel)
-- ---------------------------------------------------------

CREATE TABLE core.Core_Geraet (
    GeräteNr INT PRIMARY KEY,
    Hersteller VARCHAR(50) NOT NULL,
    Gerätetyp VARCHAR(50) NOT NULL
);

CREATE TABLE core.Core_Mitarbeiter (
    MitarbeiterNr INT PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Team VARCHAR(50) NOT NULL
);

CREATE TABLE core.Core_Prioritaet (
    Priorität VARCHAR(20) PRIMARY KEY
);

CREATE TABLE core.Core_Geraetetyp (
    Gerätetyp VARCHAR(50) PRIMARY KEY
);

CREATE TABLE core.Core_Standort (
    StandortID INT PRIMARY KEY,
    Standortbezeichnung VARCHAR(100) NOT NULL,
    -- Offen: Kunde ist mit dem aktuellen Datenmodell nicht je Standort
    -- eindeutig (siehe DWH-Mapping, Blatt Dimensionen). Bis zur Klärung
    -- bleibt die Spalte nullable.
    Kunde VARCHAR(100)
);

CREATE TABLE core.Core_Datum (
    Datum DATE PRIMARY KEY,
    Jahr INT NOT NULL,
    Quartal INT NOT NULL,
    Monat INT NOT NULL
);


-- =========================================================
-- 3. BUSINESS-SCHICHT
-- =========================================================
-- Umsetzung der beiden Star Schemas. Die natürlichen Schlüssel der
-- Core-Dimensionstabellen werden durch künstliche Schlüssel (Surrogate
-- Keys) ersetzt. Dim_Standort und Dim_Datum werden von beiden Star
-- Schemas gemeinsam genutzt (konformierte Dimensionen).
-- =========================================================

-- ---------------------------------------------------------
-- 3a. Dimensionstabellen
-- ---------------------------------------------------------

CREATE TABLE business.Dim_Geraet (
    Geraet_SK SERIAL PRIMARY KEY,
    Geraetenummer INT NOT NULL UNIQUE,
    Hersteller VARCHAR(50) NOT NULL,
    Geraetetyp VARCHAR(50) NOT NULL
);

CREATE TABLE business.Dim_Mitarbeiter (
    Mitarbeiter_SK SERIAL PRIMARY KEY,
    Mitarbeiter_NK INT NOT NULL UNIQUE,
    Name VARCHAR(100) NOT NULL,
    Team VARCHAR(50) NOT NULL
);

CREATE TABLE business.Dim_Prioritaet (
    Prioritaet_SK SERIAL PRIMARY KEY,
    Prioritaet_NK VARCHAR(20) NOT NULL UNIQUE,
    Bezeichnung VARCHAR(20) NOT NULL
);

CREATE TABLE business.Dim_Geraetetyp (
    Geraetetyp_SK SERIAL PRIMARY KEY,
    Geraetetyp_NK VARCHAR(50) NOT NULL UNIQUE,
    Bezeichnung VARCHAR(50) NOT NULL
);

CREATE TABLE business.Dim_Standort (
    Standort_SK SERIAL PRIMARY KEY,
    Standort_NK INT NOT NULL UNIQUE,
    Standortname VARCHAR(100) NOT NULL,
    -- Offen, siehe core.Core_Standort.Kunde
    Kunde VARCHAR(100)
);

CREATE TABLE business.Dim_Datum (
    Datum_SK SERIAL PRIMARY KEY,
    Datum DATE NOT NULL UNIQUE,
    Jahr INT NOT NULL,
    Quartal INT NOT NULL,
    Monat INT NOT NULL
);

-- ---------------------------------------------------------
-- 3b. Faktentabelle Frage 1: SLA_Bearbeitung_Facts
-- ---------------------------------------------------------
-- Granularität: ein Bearbeitungsvorgang eines Tickets.

CREATE TABLE business.SLA_Bearbeitung_Facts (
    Bearbeitung_NR INT PRIMARY KEY,
    Ticket_NR INT NOT NULL,
    Geraet_SK INT NOT NULL REFERENCES business.Dim_Geraet(Geraet_SK),
    Standort_SK INT NOT NULL REFERENCES business.Dim_Standort(Standort_SK),
    Mitarbeiter_SK INT NOT NULL REFERENCES business.Dim_Mitarbeiter(Mitarbeiter_SK),
    Prioritaet_SK INT NOT NULL REFERENCES business.Dim_Prioritaet(Prioritaet_SK),
    Datum_SK INT NOT NULL REFERENCES business.Dim_Datum(Datum_SK),
    Bearbeitungszeit_Minuten INT NOT NULL,
    SLA_Zielzeit_Minuten INT NOT NULL,
    -- Abgeleitet: Bearbeitungszeit_Minuten - SLA_Zielzeit_Minuten
    SLA_Abweichung_Minuten INT NOT NULL
);

-- ---------------------------------------------------------
-- 3c. Faktentabelle Frage 2: Wartung_Kosten_Facts
-- ---------------------------------------------------------
-- Granularität: Kombination aus Gerätetyp, Standort und Monat.
-- Vertragskosten_pro_Jahr enthält beim Laden den anteiligen Monatswert
-- (Kosten_pro_Jahr / 12 je Monat der Vertragslaufzeit), damit die Summe
-- über 12 Monate wieder den Jahreswert ergibt (siehe DWH-Mapping,
-- Hinweis in Blatt Fakten).

CREATE TABLE business.Wartung_Kosten_Facts (
    Geraetetyp_SK INT NOT NULL REFERENCES business.Dim_Geraetetyp(Geraetetyp_SK),
    Standort_SK INT NOT NULL REFERENCES business.Dim_Standort(Standort_SK),
    Datum_SK INT NOT NULL REFERENCES business.Dim_Datum(Datum_SK),
    Wartungskosten NUMERIC(12, 2) NOT NULL DEFAULT 0,
    Vertragskosten_pro_Jahr NUMERIC(12, 2) NOT NULL DEFAULT 0,
    Anzahl_Tickets INT NOT NULL DEFAULT 0,
    PRIMARY KEY (Geraetetyp_SK, Standort_SK, Datum_SK)
);
