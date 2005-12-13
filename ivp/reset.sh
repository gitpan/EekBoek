#!/bin/sh

if [ -z "$EB_DB_NAME" ]
then
    echo "Error: EB_DB_NAME not set" 1>&2
    exit 1
fi

if ! test -s reset.sql
then
    echo "Error: reset.sql is missing" 1>&2
    exit 1
fi

psql ${EB_DB_NAME} < reset.sql > /dev/null 2>&1
