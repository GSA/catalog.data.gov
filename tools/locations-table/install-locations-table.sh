#!/bin/bash

echo "*** USAGE: $(basename "$0") HOST DB_NAME DB_USER PASS"

# TODO check path on run
SQL_FILE=30_locations.sql.gz
HOST=$1
DB_NAME=$2
DB_USER=$3
PASS=$4

if ! [ -f $SQL_FILE ]; then
	echo "Error: locations.sql file not found, exiting.."
	exit 1
fi

echo "Creating locations table"
gunzip -c ${SQL_FILE} | PGPASSWORD=${PASS} psql -h "$HOST" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1
