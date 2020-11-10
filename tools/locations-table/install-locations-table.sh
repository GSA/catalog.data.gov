echo "*** USAGE: $(basename "$0") HOST DB_NAME DB_USER PASS"

DEST_FOLDER=/tmp
HOST=$1
DB_NAME=$2
DB_USER=$3
PASS=$4

echo "Downloading locations table"
wget https://github.com/GSA/datagov-deploy/raw/71936f004be1882a506362670b82c710c64ef796/ansible/roles/software/ec2/ansible/files/locations.sql.gz -O $DEST_FOLDER/locations.sql.gz

echo "Creating locations table"
gunzip -c ${DEST_FOLDER}/locations.sql.gz | PGPASSWORD=${PASS} psql -h $HOST -U $DB_USER -d $DB_NAME -v ON_ERROR_STOP=1

echo "Cleaning"
rm -f $DEST_FOLDER/locations.sql.gz