-- =========================================================
-- Ladeprozeduren (ETL)
-- Ausführen in der Datenbank: datawarehouse
-- Aufruf des Gesamtlaufs: CALL etl.load_dwh();
-- Jeder Lauf ist wiederholbar (Full Load) und läuft in einer
-- Transaktion. Bei einem Fehler wird nichts übernommen.
-- =========================================================


-- =========================================================
-- 1. Quellsysteme -> Staging (1:1-Kopie)
-- =========================================================
CREATE OR REPLACE PROCEDURE etl.load_staging()
LANGUAGE plpgsql AS $$
BEGIN
    TRUNCATE staging.IS_Standort,
             staging.IS_Gerät,
             staging.IS_Wartungsvertrag,
             staging.IS_Wartung,
             staging.TS_Mitarbeiter,
             staging.TS_Ticket,
             staging.TS_Bearbeitung;

    -- Inventarsystem
    INSERT INTO staging.IS_Standort
        SELECT * FROM fdw_inventarsystem.Standort;
    INSERT INTO staging.IS_Gerät
        SELECT * FROM fdw_inventarsystem.Gerät;
    INSERT INTO staging.IS_Wartungsvertrag
        SELECT * FROM fdw_inventarsystem.Wartungsvertrag;
    INSERT INTO staging.IS_Wartung
        SELECT * FROM fdw_inventarsystem.Wartung;

    -- Ticketsystem
    INSERT INTO staging.TS_Mitarbeiter
        SELECT * FROM fdw_ticketsystem.Mitarbeiter;
    INSERT INTO staging.TS_Ticket
        SELECT * FROM fdw_ticketsystem.Ticket;
    INSERT INTO staging.TS_Bearbeitung
        SELECT * FROM fdw_ticketsystem.Bearbeitung;
END $$;


-- =========================================================
-- 2. Staging -> Core
-- =========================================================
CREATE OR REPLACE PROCEDURE etl.load_core()
LANGUAGE plpgsql AS $$
BEGIN
    TRUNCATE core.Topic_SLA_Bearbeitung,
             core.Topic_Wartungskosten_Wartung,
             core.Topic_Wartungskosten_Vertrag,
             core.Topic_Wartungskosten_Ticket,
             core.Core_Geraet,
             core.Core_Mitarbeiter,
             core.Core_Prioritaet,
             core.Core_Geraetetyp,
             core.Core_Standort,
             core.Core_Datum;

    -- -----------------------------------------------------
    -- Topic-Tabelle Frage 1: SLA-Konformität
    -- -----------------------------------------------------
    INSERT INTO core.Topic_SLA_Bearbeitung (
        Bearbeitung_BearbeitungsNr, Bearbeitung_MitarbeiterNr,
        Bearbeitung_Datum, Bearbeitung_Bearbeitungszeit_Minuten,
        Ticket_TicketNr, Ticket_Priorität, Ticket_SLA_Zielzeit_Minuten,
        Gerät_GeräteNr, Gerät_StandortID)
    SELECT b.BearbeitungsNr, b.MitarbeiterNr,
           b.Datum, b.Bearbeitungszeit_Minuten,
           t.TicketNr, t.Priorität, t.SLA_Zielzeit_Minuten,
           g.GeräteNr, g.StandortID
    FROM staging.TS_Bearbeitung b
    JOIN staging.TS_Ticket t ON t.TicketNr = b.TicketNr
    JOIN staging.IS_Gerät  g ON g.GeräteNr = t.GeräteNr;

    -- -----------------------------------------------------
    -- Topic-Tabellen Frage 2: Wartungs- und Vertragskosten
    -- (drei getrennte Tabellen wegen n:m-Beziehungen)
    -- -----------------------------------------------------
    INSERT INTO core.Topic_Wartungskosten_Wartung (
        Wartung_WartungsNr, Wartung_Datum, Wartung_Kosten,
        Gerät_GeräteNr, Gerät_Gerätetyp, Gerät_StandortID)
    SELECT w.WartungsNr, w.Datum, w.Kosten,
           g.GeräteNr, g.Gerätetyp, g.StandortID
    FROM staging.IS_Wartung w
    JOIN staging.IS_Gerät g ON g.GeräteNr = w.GeräteNr;

    INSERT INTO core.Topic_Wartungskosten_Vertrag (
        Wartungsvertrag_VertragsNr, Wartungsvertrag_Beginn,
        Wartungsvertrag_Ende, Wartungsvertrag_Kosten_pro_Jahr,
        Gerät_GeräteNr, Gerät_Gerätetyp, Gerät_StandortID)
    SELECT v.VertragsNr, v.Beginn,
           v.Ende, v.Kosten_pro_Jahr,
           g.GeräteNr, g.Gerätetyp, g.StandortID
    FROM staging.IS_Wartungsvertrag v
    JOIN staging.IS_Gerät g ON g.GeräteNr = v.GeräteNr;

    INSERT INTO core.Topic_Wartungskosten_Ticket (
        Ticket_TicketNr, Ticket_Erstellungsdatum,
        Gerät_GeräteNr, Gerät_Gerätetyp, Gerät_StandortID)
    SELECT t.TicketNr, t.Erstellungsdatum,
           g.GeräteNr, g.Gerätetyp, g.StandortID
    FROM staging.TS_Ticket t
    JOIN staging.IS_Gerät g ON g.GeräteNr = t.GeräteNr;

    -- -----------------------------------------------------
    -- Core-Dimensionen (natürliche Schlüssel)
    -- -----------------------------------------------------
    INSERT INTO core.Core_Geraet (GeräteNr, Hersteller, Gerätetyp)
    SELECT GeräteNr, Hersteller, Gerätetyp
    FROM staging.IS_Gerät;

    INSERT INTO core.Core_Mitarbeiter (MitarbeiterNr, Name, Team)
    SELECT MitarbeiterNr, Name, Team
    FROM staging.TS_Mitarbeiter;

    INSERT INTO core.Core_Prioritaet (Priorität)
    SELECT DISTINCT Priorität
    FROM staging.TS_Ticket;

    INSERT INTO core.Core_Geraetetyp (Gerätetyp)
    SELECT DISTINCT Gerätetyp
    FROM staging.IS_Gerät;

    -- Kunde bleibt vorerst NULL (offenes Thema, siehe DWH-Mapping)
    INSERT INTO core.Core_Standort (StandortID, Standortbezeichnung, Kunde)
    SELECT StandortID, Standortbezeichnung, NULL
    FROM staging.IS_Standort;

    -- Datumsdimension: lückenlos vom ersten Monat bis zum letzten
    -- Datum aller relevanten Datumsspalten
    INSERT INTO core.Core_Datum (Datum, Jahr, Quartal, Monat)
    SELECT d::date,
           EXTRACT(YEAR    FROM d)::int,
           EXTRACT(QUARTER FROM d)::int,
           EXTRACT(MONTH   FROM d)::int
    FROM (
        SELECT generate_series(
                   date_trunc('month', MIN(dt)::timestamp),
                   MAX(dt)::timestamp,
                   interval '1 day') AS d
        FROM (
            SELECT Datum AS dt              FROM staging.TS_Bearbeitung
            UNION ALL SELECT Erstellungsdatum FROM staging.TS_Ticket
            UNION ALL SELECT Datum            FROM staging.IS_Wartung
            UNION ALL SELECT Beginn           FROM staging.IS_Wartungsvertrag
            UNION ALL SELECT Ende             FROM staging.IS_Wartungsvertrag
        ) alle
    ) tage;
END $$;


-- =========================================================
-- 3. Core -> Business (Star Schemas)
-- =========================================================
CREATE OR REPLACE PROCEDURE etl.load_business()
LANGUAGE plpgsql AS $$
BEGIN
    -- Fakten zuerst leeren, Dimensionen bleiben bestehen,
    -- damit die Surrogate Keys stabil bleiben.
    TRUNCATE business.SLA_Bearbeitung_Facts,
             business.Wartung_Kosten_Facts;

    -- -----------------------------------------------------
    -- Dimensionen (neue Werte einfügen, bestehende aktualisieren)
    -- -----------------------------------------------------
    INSERT INTO business.Dim_Geraet (Geraetenummer, Hersteller, Geraetetyp)
    SELECT GeräteNr, Hersteller, Gerätetyp
    FROM core.Core_Geraet
    ON CONFLICT (Geraetenummer) DO UPDATE
        SET Hersteller = EXCLUDED.Hersteller,
            Geraetetyp = EXCLUDED.Geraetetyp;

    INSERT INTO business.Dim_Mitarbeiter (Mitarbeiter_NK, Name, Team)
    SELECT MitarbeiterNr, Name, Team
    FROM core.Core_Mitarbeiter
    ON CONFLICT (Mitarbeiter_NK) DO UPDATE
        SET Name = EXCLUDED.Name,
            Team = EXCLUDED.Team;

    INSERT INTO business.Dim_Prioritaet (Prioritaet_NK, Bezeichnung)
    SELECT Priorität, Priorität
    FROM core.Core_Prioritaet
    ON CONFLICT (Prioritaet_NK) DO UPDATE
        SET Bezeichnung = EXCLUDED.Bezeichnung;

    INSERT INTO business.Dim_Geraetetyp (Geraetetyp_NK, Bezeichnung)
    SELECT Gerätetyp, Gerätetyp
    FROM core.Core_Geraetetyp
    ON CONFLICT (Geraetetyp_NK) DO UPDATE
        SET Bezeichnung = EXCLUDED.Bezeichnung;

    INSERT INTO business.Dim_Standort (Standort_NK, Standortname, Kunde)
    SELECT StandortID, Standortbezeichnung, Kunde
    FROM core.Core_Standort
    ON CONFLICT (Standort_NK) DO UPDATE
        SET Standortname = EXCLUDED.Standortname,
            Kunde        = EXCLUDED.Kunde;

    INSERT INTO business.Dim_Datum (Datum, Jahr, Quartal, Monat)
    SELECT Datum, Jahr, Quartal, Monat
    FROM core.Core_Datum
    ON CONFLICT (Datum) DO NOTHING;

    -- -----------------------------------------------------
    -- Fakten Frage 1: SLA_Bearbeitung_Facts
    -- Granularität: ein Bearbeitungsvorgang
    -- -----------------------------------------------------
    INSERT INTO business.SLA_Bearbeitung_Facts (
        Bearbeitung_NR, Ticket_NR, Geraet_SK, Standort_SK,
        Mitarbeiter_SK, Prioritaet_SK, Datum_SK,
        Bearbeitungszeit_Minuten, SLA_Zielzeit_Minuten,
        SLA_Abweichung_Minuten)
    SELECT t.Bearbeitung_BearbeitungsNr,
           t.Ticket_TicketNr,
           dg.Geraet_SK,
           ds.Standort_SK,
           dm.Mitarbeiter_SK,
           dp.Prioritaet_SK,
           dd.Datum_SK,
           t.Bearbeitung_Bearbeitungszeit_Minuten,
           t.Ticket_SLA_Zielzeit_Minuten,
           t.Bearbeitung_Bearbeitungszeit_Minuten
             - t.Ticket_SLA_Zielzeit_Minuten
    FROM core.Topic_SLA_Bearbeitung t
    JOIN business.Dim_Geraet      dg ON dg.Geraetenummer  = t.Gerät_GeräteNr
    JOIN business.Dim_Standort    ds ON ds.Standort_NK    = t.Gerät_StandortID
    JOIN business.Dim_Mitarbeiter dm ON dm.Mitarbeiter_NK = t.Bearbeitung_MitarbeiterNr
    JOIN business.Dim_Prioritaet  dp ON dp.Prioritaet_NK  = t.Ticket_Priorität
    JOIN business.Dim_Datum        dd ON dd.Datum         = t.Bearbeitung_Datum;

    -- -----------------------------------------------------
    -- Fakten Frage 2: Wartung_Kosten_Facts
    -- Granularität: Gerätetyp, Standort, Monat
    -- Der Monat wird über den ersten Tag des Monats in
    -- Dim_Datum abgebildet.
    -- Vertragskosten: Kosten_pro_Jahr / 12 je Monat der Laufzeit
    -- -----------------------------------------------------
    INSERT INTO business.Wartung_Kosten_Facts (
        Geraetetyp_SK, Standort_SK, Datum_SK,
        Wartungskosten, Vertragskosten_pro_Jahr, Anzahl_Tickets)
    WITH wk AS (
        SELECT Gerät_Gerätetyp AS gerätetyp,
               Gerät_StandortID AS standort_id,
               date_trunc('month', Wartung_Datum::timestamp)::date AS monat,
               SUM(Wartung_Kosten) AS kosten
        FROM core.Topic_Wartungskosten_Wartung
        GROUP BY 1, 2, 3
    ),
    vk AS (
        SELECT v.Gerät_Gerätetyp AS gerätetyp,
               v.Gerät_StandortID AS standort_id,
               m::date AS monat,
               SUM(v.Wartungsvertrag_Kosten_pro_Jahr / 12) AS kosten
        FROM core.Topic_Wartungskosten_Vertrag v
        CROSS JOIN LATERAL generate_series(
            date_trunc('month', v.Wartungsvertrag_Beginn::timestamp),
            date_trunc('month', v.Wartungsvertrag_Ende::timestamp),
            interval '1 month') AS m
        GROUP BY 1, 2, 3
    ),
    tk AS (
        SELECT Gerät_Gerätetyp AS gerätetyp,
               Gerät_StandortID AS standort_id,
               date_trunc('month', Ticket_Erstellungsdatum::timestamp)::date AS monat,
               COUNT(*) AS anzahl
        FROM core.Topic_Wartungskosten_Ticket
        GROUP BY 1, 2, 3
    ),
    schluessel AS (
        SELECT gerätetyp, standort_id, monat FROM wk
        UNION
        SELECT gerätetyp, standort_id, monat FROM vk
        UNION
        SELECT gerätetyp, standort_id, monat FROM tk
    )
    SELECT dgt.Geraetetyp_SK,
           ds.Standort_SK,
           dd.Datum_SK,
           COALESCE(wk.kosten, 0),
           COALESCE(vk.kosten, 0),
           COALESCE(tk.anzahl, 0)
    FROM schluessel s
    LEFT JOIN wk ON (wk.gerätetyp, wk.standort_id, wk.monat)
                  = (s.gerätetyp,  s.standort_id,  s.monat)
    LEFT JOIN vk ON (vk.gerätetyp, vk.standort_id, vk.monat)
                  = (s.gerätetyp,  s.standort_id,  s.monat)
    LEFT JOIN tk ON (tk.gerätetyp, tk.standort_id, tk.monat)
                  = (s.gerätetyp,  s.standort_id,  s.monat)
    JOIN business.Dim_Geraetetyp dgt ON dgt.Geraetetyp_NK = s.gerätetyp
    JOIN business.Dim_Standort   ds  ON ds.Standort_NK    = s.standort_id
    JOIN business.Dim_Datum      dd  ON dd.Datum          = s.monat;
END $$;


-- =========================================================
-- 4. Gesamtlauf
-- =========================================================
CREATE OR REPLACE PROCEDURE etl.load_dwh()
LANGUAGE plpgsql AS $$
BEGIN
    CALL etl.load_staging();
    CALL etl.load_core();
    CALL etl.load_business();
END $$;
