#!/bin/bash
set -e

POSTGRESQL_USER=${POSTGRESQL_USER:-"vega"}
POSTGRESQL_PASS=${POSTGRESQL_PASS:-"vega"}
POSTGRESQL_DB=${POSTGRESQL_DB:-"vega_db"}
POSTGRESQL_TEMPLATE=${POSTGRESQL_TEMPLATE:-"DEFAULT"}

POSTGRESQL_BIN=/usr/lib/postgresql/9.5/bin/postgres
POSTGRESQL_CONFIG_FILE=/etc/postgresql/9.5/main/postgresql.conf
POSTGRESQL_DATA=/var/lib/postgresql/9.5/main

POSTGRESQL_SINGLE="sudo -u postgres $POSTGRESQL_BIN --single --config-file=$POSTGRESQL_CONFIG_FILE"

if [ ! -d $POSTGRESQL_DATA ]; then
    mkdir -p $POSTGRESQL_DATA
    chown -R postgres:postgres $POSTGRESQL_DATA
    sudo -u postgres /usr/lib/postgresql/9.5/bin/initdb -D $POSTGRESQL_DATA -E 'UTF-8'
    ln -s /etc/ssl/certs/ssl-cert-snakeoil.pem $POSTGRESQL_DATA/server.crt
    ln -s /etc/ssl/private/ssl-cert-snakeoil.key $POSTGRESQL_DATA/server.key
fi

$POSTGRESQL_SINGLE <<< "CREATE USER $POSTGRESQL_USER WITH SUPERUSER;" > /dev/null
$POSTGRESQL_SINGLE <<< "CREATE USER root WITH SUPERUSER;" > /dev/null
$POSTGRESQL_SINGLE <<< "CREATE USER sos WITH SUPERUSER;" > /dev/null
$POSTGRESQL_SINGLE <<< "ALTER USER $POSTGRESQL_USER WITH PASSWORD '$POSTGRESQL_PASS';" > /dev/null
$POSTGRESQL_SINGLE <<< "UPDATE pg_database SET datistemplate=FALSE WHERE datname='template1';
                        DROP DATABASE template1;
                        CREATE DATABASE template1 WITH owner=postgres template=template0 encoding='UTF8';
                        UPDATE pg_database SET datistemplate=TRUE WHERE datname='template1';
                        UPDATE pg_database SET datistemplate=TRUE WHERE datname='template0';
                        UPDATE pg_database set encoding = 6, datcollate = 'en_US.UTF8', datctype = 'en_US.UTF8' where datname = 'template0';
                        UPDATE pg_database set encoding = 6, datcollate = 'en_US.UTF8', datctype = 'en_US.UTF8' where datname = 'template1'"; > /dev/null
$POSTGRESQL_SINGLE <<< "CREATE DATABASE $POSTGRESQL_DB OWNER $POSTGRESQL_USER TEMPLATE $POSTGRESQL_TEMPLATE;" > /dev/null

exec sudo -u postgres $POSTGRESQL_BIN --config-file=$POSTGRESQL_CONFIG_FILE