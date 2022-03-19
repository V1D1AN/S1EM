#!/bin/bash
set -e

psql -v --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
CREATE DATABASE mwdb;
CREATE USER mwdb WITH PASSWORD 'mwdb_postgres';
GRANT ALL PRIVILEGES ON DATABASE mwdb TO mwdb;
EOSQL
