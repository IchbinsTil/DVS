```
docker exec postgres psql -U postgres -d datawarehouse -v ON_ERROR_STOP=1 -c "CALL etl.load_dwh();"
```
