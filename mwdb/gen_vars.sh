#!/bin/sh

ADMIN_PASSWORD=$(od -vN 18 -An -tx1 /dev/urandom | tr -d " \n")
POSTGRES_PASSWORD=$(od -vN 18 -An -tx1 /dev/urandom | tr -d " \n")
SECRET_KEY=$(od -vN 18 -An -tx1 /dev/urandom | tr -d " \n")

echo "MWDB_REDIS_URI=redis://redis/" > mwdb-vars.env
echo "MWDB_POSTGRES_URI=postgresql://mwdb:$POSTGRES_PASSWORD@postgres/mwdb" >> mwdb-vars.env
echo "MWDB_SECRET_KEY=$SECRET_KEY" >> mwdb-vars.env
echo "MWDB_ADMIN_LOGIN=admin" >> mwdb-vars.env
echo "MWDB_ADMIN_EMAIL=admin@localhost" >> mwdb-vars.env
echo "MWDB_ADMIN_PASSWORD=$ADMIN_PASSWORD" >> mwdb-vars.env
echo "MWDB_BASE_URL=http://127.0.0.1" >> mwdb-vars.env

if [ "$1" != "raw" ]
then
    echo "Credentials for initial mwdb account:"
    echo ""
    echo "-----------------------------------------"
    echo "Admin login: admin"
    echo "Admin password: $ADMIN_PASSWORD"
    echo "-----------------------------------------"
    echo ""
    echo "Please be aware that initial account will be only set up on the first run. If you already have a database with at least one user, then this setting will be ignored for security reasons. You can always create an admin account manually by executing a command. See \"flask create_admin --help\" for reference."
else
    echo -n "$ADMIN_PASSWORD"
fi

if [ "$1" = "test" ]
then
    echo "MWDB_ENABLE_HOOKS=0" >> mwdb-vars.env
    echo "MWDB_ENABLE_RATE_LIMIT=0" >> mwdb-vars.env
else
    echo "MWDB_ENABLE_RATE_LIMIT=1" >> mwdb-vars.env
    echo "MWDB_ENABLE_REGISTRATION=0" >> mwdb-vars.env
fi
echo "UWSGI_PROCESSES=4" >> mwdb-vars.env

echo "POSTGRES_USER=mwdb" > postgres-vars.env
echo "POSTGRES_DB=mwdb" >> postgres-vars.env
echo "POSTGRES_PASSWORD=$POSTGRES_PASSWORD" >> postgres-vars.env
