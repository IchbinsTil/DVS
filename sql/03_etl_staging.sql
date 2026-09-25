-- Quell-Schemas temporär als Fremdschemas einbinden
CREATE SCHEMA IF NOT EXISTS fdw_ticketsystem;
CREATE SCHEMA IF NOT EXISTS fdw_inventarsystem;

IMPORT FOREIGN SCHEMA src_ticketsystem FROM SERVER src_server_ts INTO fdw_ticketsystem;
IMPORT FOREIGN SCHEMA src_inventarsystem FROM SERVER src_server_is INTO fdw_inventarsystem;

-- Staging Helpdesk
TRUNCATE TABLE staging.stg_ts_ticket;
INSERT INTO staging.stg_ts_ticket (TicketNr, KundenNr, GeräteNr, Erstellungsdatum, Kategorie, Priorität, Status, SLA_Zielzeit_Minuten)
SELECT TicketNr, KundenNr, GeräteNr, Erstellungsdatum, Kategorie, Priorität, Status, SLA_Zielzeit_Minuten
FROM fdw_ticketsystem.ticket;

TRUNCATE TABLE staging.stg_ts_bearbeitung;
INSERT INTO staging.stg_ts_bearbeitung (BearbeitungsNr, TicketNr, MitarbeiterNr, Datum, Bearbeitungszeit_Minuten, Aktionstyp)
SELECT BearbeitungsNr, TicketNr, MitarbeiterNr, Datum, Bearbeitungszeit_Minuten, Aktionstyp
FROM fdw_ticketsystem.bearbeitung;

TRUNCATE TABLE staging.stg_ts_kunde;
INSERT INTO staging.stg_ts_kunde (KundenNr, Kunden_Name, Kundentyp)
SELECT KundenNr, Kunden_Name, Kundentyp
FROM fdw_ticketsystem.kunde;

TRUNCATE TABLE staging.stg_ts_mitarbeiter;
INSERT INTO staging.stg_ts_mitarbeiter (MitarbeiterNr, Name, Team, Rolle)
SELECT MitarbeiterNr, Name, Team, Rolle
FROM fdw_ticketsystem.mitarbeiter;

-- Staging Inventar & Wartung
TRUNCATE TABLE staging.stg_inv_standort;
INSERT INTO staging.stg_inv_standort (StandortID, Standortbezeichnung, Region, Land)
SELECT StandortID, Standortbezeichnung, Region, Land
FROM fdw_inventarsystem.standort;

TRUNCATE TABLE staging.stg_inv_geraet;
INSERT INTO staging.stg_inv_geraet (GeräteNr, Gerätetyp, Hersteller, Modell, StandortID, Anschaffungsdatum, KundenNr)
SELECT GeräteNr, Gerätetyp, Hersteller, Modell, StandortID, Anschaffungsdatum, KundenNr
FROM fdw_inventarsystem.gerät;

TRUNCATE TABLE staging.stg_inv_wartungsvertrag;
INSERT INTO staging.stg_inv_wartungsvertrag (VertragsNr, GeräteNr, Vertragsart, Beginn, Ende, Kosten_pro_Jahr)
SELECT VertragsNr, GeräteNr, Vertragsart, Beginn, Ende, Kosten_pro_Jahr
FROM fdw_inventarsystem.wartungsvertrag;

TRUNCATE TABLE staging.stg_inv_wartung;
INSERT INTO staging.stg_inv_wartung (WartungsNr, GeräteNr, Datum, Wartungsart, Kosten)
SELECT WartungsNr, GeräteNr, Datum, Wartungsart, Kosten
FROM fdw_inventarsystem.wartung;
