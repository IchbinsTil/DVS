-- Init-Skript Quellsystem 1: Ticketsystem
-- Nur Schema, keine Beispieldaten.
-- Die Beispieldaten werden separat erzeugt und eingespielt.

DROP SCHEMA IF EXISTS src_ticketsystem CASCADE;
CREATE SCHEMA src_ticketsystem;

-- ---------------------------------------------------------------
-- Quellsystem 1: Ticketsystem (Helpdesk/Servicemanagement)
-- ---------------------------------------------------------------

CREATE TABLE src_ticketsystem.Kunde (
    KundenNr INT PRIMARY KEY,
    Kunden_Name VARCHAR(100) NOT NULL,
    Kundentyp VARCHAR(50) NOT NULL
    -- z.B. Enterprise, Mittelstand, Startup
);

CREATE TABLE src_ticketsystem.Kundenbetreuer (
    BetreuerNr INT PRIMARY KEY,
    KundenNr INT NOT NULL
        REFERENCES src_ticketsystem.Kunde(KundenNr),
    Name VARCHAR(100) NOT NULL,
    Team VARCHAR(50) NOT NULL
);

CREATE TABLE src_ticketsystem.Mitarbeiter (
    MitarbeiterNr INT PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Team VARCHAR(50) NOT NULL,
    -- z.B. Network-Core, Security-Ops, Field-Support
    Rolle VARCHAR(50) NOT NULL
);

CREATE TABLE src_ticketsystem.Ticket (
    TicketNr INT PRIMARY KEY,
    KundenNr INT NOT NULL
        REFERENCES src_ticketsystem.Kunde(KundenNr),
    GeräteNr INT NOT NULL,
    -- Logischer Verweis auf Gerät im Inventarsystem
    -- (andere Datenbank)
    Erstellungsdatum DATE NOT NULL,
    Kategorie VARCHAR(50) NOT NULL,
    -- z.B. Hardware, Netzwerk, Security, Software
    Priorität VARCHAR(20) NOT NULL
        CHECK (Priorität IN ('Kritisch', 'Hoch', 'Normal')),
    Status VARCHAR(20) NOT NULL,
    -- z.B. Gelöst, Geschlossen
    SLA_Zielzeit_Minuten INT NOT NULL
);

CREATE TABLE src_ticketsystem.Bearbeitung (
    BearbeitungsNr INT PRIMARY KEY,
    TicketNr INT NOT NULL
        REFERENCES src_ticketsystem.Ticket(TicketNr),
    MitarbeiterNr INT NOT NULL
        REFERENCES src_ticketsystem.Mitarbeiter(MitarbeiterNr),
    Datum DATE NOT NULL,
    Bearbeitungszeit_Minuten INT NOT NULL,
    Aktionstyp VARCHAR(50) NOT NULL
    -- z.B. Diagnose, Patch, Konfiguration
);