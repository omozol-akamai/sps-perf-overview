#!/bin/sh

# This script will create a user "nomdb" used by nom-data-loader to push data to influxdb and also a default database "n2"

PATH="/bin:/usr/bin"
INFLUX="influx"

DBNAME="n2"
DBUSER="nomdb"
DBPASS=$1

if [ "" = "$DBPASS" ] ; then
    echo "Usage: influxdb-setup.sh <password>"
    exit 1
fi

$INFLUX -execute "CREATE DATABASE $DBNAME"
$INFLUX -execute "CREATE USER $DBUSER WITH PASSWORD '$DBPASS' WITH ALL PRIVILEGES"
$INFLUX -database $DBNAME -execute "CREATE RETENTION POLICY raw ON n2 DURATION 60d REPLICATION 1 DEFAULT"