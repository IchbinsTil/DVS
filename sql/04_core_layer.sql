WIP
-- ============================================================
-- 04_core_layer.sql
-- DWH-Core-Schicht: Themenorientierte Tabellen (Topic Tables)
-- Gemäß Mapping-Matrix für Fragestellung 1 & 2
-- ============================================================

DROP SCHEMA IF EXISTS core CASCADE;
CREATE SCHEMA core;

-- ============================================================
-- 1. DDL: TOPIC-TABELLEN IM CORE-SCHEMA ANLEGEN
-- ============================================================

-- Fragestellung 1: Topic-Tabelle für SLA- & Bearbeitungszeiten
DROP TABLE IF EXISTS core.topic_sla_bearbeitung CASCADE;
CREATE TABLE core.topic_sla_bearbeitung (
    "Gerät_GeräteNr"                       INT,
    "Gerät_Gerätetyp"                      VARCHAR(50),
    "Gerät_Hersteller"                     VARCHAR(50),
    "Standort_StandortID"                  INT,
    "Standort_Standortbezeichnung"         VARCHAR(100),
    "Standort_Region"                      VARCHAR(50),
    "Standort_Land"                        VARCHAR(50),
    "Ticket_TicketNr"                      INT,
    "Ticket_Erstellungsdatum"              TIMESTAMP,
    "Ticket_Priorität"                     VARCHAR(20),
    "Ticket_SLA_Zielzeit_Minuten"          INT,
    "Bearbeitung_BearbeitungsNr"           INT,
    "Bearbeitung_Bearbeitungszeit_Minuten" INT,
    core_loaded_at                         TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Fragestellung 2: Topic-Tabelle für Wartungskosten & Ticketaufkommen
DROP TABLE IF EXISTS core.topic_wartungskosten CASCADE;
CREATE TABLE core.topic_wartungskosten (
    "Gerät_GeräteNr"                       INT,
    "Gerät_Gerätetyp"                      VARCHAR(50),
    "Wartungsvertrag_VertragsNr"           INT,
    "Wartungsvertrag_Kosten_pro_Jahr"      NUMERIC(10, 2),
    "Wartung_WartungsNr"                   INT,
    "Wartung_Kosten"                       NUMERIC(10, 2),
    "Standort_StandortID"                  INT,
    "Standort_Standortbezeichnung"         VARCHAR(100),
    "Standort_Region"                      VARCHAR(50),
    "Standort_Land"                        VARCHAR(50),
    "Ticket_TicketNr"                      INT,
    "Ticket_Erstellungsdatum"              TIMESTAMP,
    "Ticket_Priorität"                     VARCHAR(20),
    core_loaded_at                         TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- ============================================================
-- 2. TRANSFORMATION & LADEN (Staging -> Core)
-- ============================================================

-- Vor jedem Ladelauf Core-Tabellen leeren
TRUNCATE TABLE core.topic_sla_bearbeitung;
TRUNCATE TABLE core.topic_wartungskosten;

-- ------------------------------------------------------------
-- Befüllung Topic 1: Bearbeitungs- und SLA-Zeiten
-- Kette: TS_Bearbeitung -> TS_Ticket -> IS_Gerät -> IS_Standort
-- ------------------------------------------------------------
INSERT INTO core.topic_sla_bearbeitung (
    "Gerät_GeräteNr",
    "Gerät_Gerätetyp",
    "Gerät_Hersteller",
    "Standort_StandortID",
    "Standort_Standortbezeichnung",
    "Standort_Region",
    "Standort_Land",
    "Ticket_TicketNr",
    "Ticket_Erstellungsdatum",
    "Ticket_Priorität",
    "Ticket_SLA_Zielzeit_Minuten",
    "Bearbeitung_BearbeitungsNr",
    "Bearbeitung_Bearbeitungszeit_Minuten"
)
SELECT 
    g.GeräteNr                     AS "Gerät_GeräteNr",
    g.Gerätetyp                    AS "Gerät_Gerätetyp",
    g.Hersteller                   AS "Gerät_Hersteller",
    s.StandortID                   AS "Standort_StandortID",
    s.Standortbezeichnung          AS "Standort_Standortbezeichnung",
    s.Region                       AS "Standort_Region",
    s.Land                         AS "Standort_Land",
    t.TicketNr                     AS "Ticket_TicketNr",
    t.Erstellungsdatum             AS "Ticket_Erstellungsdatum",
    t.Priorität                    AS "Ticket_Priorität",
    t.SLA_Zielzeit_Minuten         AS "Ticket_SLA_Zielzeit_Minuten",
    b.BearbeitungsNr               AS "Bearbeitung_BearbeitungsNr",
    b.Bearbeitungszeit_Minuten     AS "Bearbeitung_Bearbeitungszeit_Minuten"
FROM staging.stg_ts_bearbeitung b
INNER JOIN staging.stg_ts_ticket t 
    ON b.TicketNr = t.TicketNr
INNER JOIN staging.stg_inv_gerät g 
    ON t.GeräteNr = g.GeräteNr
INNER JOIN staging.stg_inv_standort s 
    ON g.StandortID = s.StandortID;


-- ------------------------------------------------------------
-- Befüllung Topic 2: Wartungskosten & Ticketaufkommen
-- Kette: IS_Gerät -> IS_Standort, IS_Wartungsvertrag, IS_Wartung, TS_Ticket
-- ------------------------------------------------------------
INSERT INTO core.topic_wartungskosten (
    "Gerät_GeräteNr",
    "Gerät_Gerätetyp",
    "Wartungsvertrag_VertragsNr",
    "Wartungsvertrag_Kosten_pro_Jahr",
    "Wartung_WartungsNr",
    "Wartung_Kosten",
    "Standort_StandortID",
    "Standort_Standortbezeichnung",
    "Standort_Region",
    "Standort_Land",
    "Ticket_TicketNr",
    "Ticket_Erstellungsdatum",
    "Ticket_Priorität"
)
SELECT 
    g.GeräteNr                     AS "Gerät_GeräteNr",
    g.Gerätetyp                    AS "Gerät_Gerätetyp",
    wv.VertragsNr                  AS "Wartungsvertrag_VertragsNr",
    wv.Kosten_pro_Jahr             AS "Wartungsvertrag_Kosten_pro_Jahr",
    w.WartungsNr                   AS "Wartung_WartungsNr",
    w.Kosten                       AS "Wartung_Kosten",
    s.StandortID                   AS "Standort_StandortID",
    s.Standortbezeichnung          AS "Standort_Standortbezeichnung",
    s.Region                       AS "Standort_Region",
    s.Land                         AS "Standort_Land",
    t.TicketNr                     AS "Ticket_TicketNr",
    t.Erstellungsdatum             AS "Ticket_Erstellungsdatum",
    t.Priorität                    AS "Ticket_Priorität"
FROM staging.stg_inv_gerät g
INNER JOIN staging.stg_inv_standort s 
    ON g.StandortID = s.StandortID
LEFT JOIN staging.stg_inv_wartungsvertrag wv 
    ON g.GeräteNr = wv.GeräteNr
LEFT JOIN staging.stg_inv_wartung w 
    ON g.GeräteNr = w.GeräteNr
LEFT JOIN staging.stg_ts_ticket t 
    ON g.GeräteNr = t.GeräteNr;