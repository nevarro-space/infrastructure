PostgreSQL migration:

```
pg_dumpall | ssh -C root@5.161.216.225 'su postgres -c "psql postgres"' 
```
