# DVS
Dieses Repository enthält Dokumentationen und Teilarbeitsschritte der zu erstellenden Tutorials für das Modul DVS (Datenverwaltungssysteme)


docker exec postgres psql -U postgres -d datawarehouse -v ON_ERROR_STOP=1 -c "CALL etl.load_dwh();"
