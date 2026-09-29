-- =========================================================
-- Init-Skript FDW: Anbindung der Quelldatenbanken
-- Ausführen in der Datenbank: datawarehouse
-- Voraussetzung: 01_init_datawarehouse.sql wurde ausgeführt,
--   die Datenbanken ticketsystem und inventarsystem existieren
--   (Namen bei Bedarf unten anpassen).
-- =========================================================

CREATE EXTENSION IF NOT EXISTS postgres_fdw;

-- Bei erneuter Ausführung alte Verbindungen entfernen
DROP SCHEMA IF EXISTS fdw_ticketsystem CASCADE;
DROP SCHEMA IF EXISTS fdw_inventarsystem CASCADE;
DROP SERVER IF EXISTS srv_ticketsystem CASCADE;
DROP SERVER IF EXISTS srv_inventarsystem CASCADE;

-- Server (gleicher Postgres-Container, daher localhost)
CREATE SERVER srv_ticketsystem
    FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (host 'localhost', port '5432', dbname 'ticketsystem');

CREATE SERVER srv_inventarsystem
    FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (host 'localhost', port '5432', dbname 'inventarsystem');

-- Benutzerzuordnung
CREATE USER MAPPING FOR CURRENT_USER
    SERVER srv_ticketsystem
    OPTIONS (user 'postgres', password 'YOUR_PASSWORD');

CREATE USER MAPPING FOR CURRENT_USER
    SERVER srv_inventarsystem
    OPTIONS (user 'postgres', password 'YOUR_PASSWORD');

-- Fremdtabellen einbinden
CREATE SCHEMA fdw_ticketsystem;
CREATE SCHEMA fdw_inventarsystem;

IMPORT FOREIGN SCHEMA src_ticketsystem
    FROM SERVER srv_ticketsystem
    INTO fdw_ticketsystem;

IMPORT FOREIGN SCHEMA src_inventarsystem
    FROM SERVER srv_inventarsystem
    INTO fdw_inventarsystem;

-- Schema für die Ladeprozeduren
CREATE SCHEMA IF NOT EXISTS etl;

