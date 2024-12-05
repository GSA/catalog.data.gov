# Locations table

The locations table [was defined in 2016](https://github.com/GSA/data.gov/search?q=location+table&type=commits).  
This table was deleted from the repo but is still available from old commits: [locations.sql.gz](https://github.com/GSA/data.gov/raw/71936f004be1882a506362670b82c710c64ef796/ansible/roles/software/ec2/ansible/files/locations.sql.gz).  

This table could be dd to database with

```bash
./install-locations-table.sh HOST DB_NAME DB_USER PASS
```
