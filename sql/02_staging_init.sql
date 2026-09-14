-- Staging Helpdesk
TRUNCATE TABLE staging.stg_hd_ticket;
INSERT INTO staging.stg_hd_ticket (TicketNr, KundenNr, GeräteNr, Erstellungsdatum, Kategorie, Priorität, Status, SLA_Zielzeit_Minuten)
SELECT TicketNr, KundenNr, GeräteNr, Erstellungsdatum, Kategorie, Priorität, Status, SLA_Zielzeit_Minuten 
FROM fdw_helpdesk.ticket;

TRUNCATE TABLE staging.stg_hd_bearbeitung;
INSERT INTO staging.stg_hd_bearbeitung (BearbeitungsNr, TicketNr, MitarbeiterNr, Datum, Bearbeitungszeit_Minuten, Aktionstyp)
SELECT BearbeitungsNr, TicketNr, MitarbeiterNr, Datum, Bearbeitungszeit_Minuten, Aktionstyp 
FROM fdw_helpdesk.bearbeitung;

TRUNCATE TABLE staging.stg_hd_kunde;
INSERT INTO staging.stg_hd_kunde (KundenNr, Kunden_Name, Kundentyp, StandortID)
SELECT KundenNr, Kunden_Name, Kundentyp, StandortID 
FROM fdw_helpdesk.kunde;

TRUNCATE TABLE staging.stg_hd_mitarbeiter;
INSERT INTO staging.stg_hd_mitarbeiter (MitarbeiterNr, Name, Team, Rolle)
SELECT MitarbeiterNr, Name, Team, Rolle 
FROM fdw_helpdesk.mitarbeiter;

-- Staging Inventar & Wartung
TRUNCATE TABLE staging.stg_inv_standort;
INSERT INTO staging.stg_inv_standort (StandortID, Standortbezeichnung, Region, Land)
SELECT StandortID, Standortbezeichnung, Region, Land 
FROM fdw_inventar.standort;

TRUNCATE TABLE staging.stg_inv_geraet;
INSERT INTO staging.stg_inv_geraet (GeräteNr, Gerätetyp, Hersteller, Modell, StandortID, Anschaffungsdatum)
SELECT GeräteNr, Gerätetyp, Hersteller, Modell, StandortID, Anschaffungsdatum 
FROM fdw_inventar.gerät;

TRUNCATE TABLE staging.stg_inv_wartungsvertrag;
INSERT INTO staging.stg_inv_wartungsvertrag (VertragsNr, GeräteNr, Vertragsart, Beginn, Ende, Kosten_pro_Jahr)
SELECT VertragsNr, GeräteNr, Vertragsart, Beginn, Ende, Kosten_pro_Jahr 
FROM fdw_inventar.wartungsvertrag;

TRUNCATE TABLE staging.stg_inv_wartung;
INSERT INTO staging.stg_inv_wartung (WartungsNr, GeräteNr, Datum, Wartungsart, TechnikerNr, Kosten)
SELECT WartungsNr, GeräteNr, Datum, Wartungsart, TechnikerNr, Kosten 
FROM fdw_inventar.wartung;
