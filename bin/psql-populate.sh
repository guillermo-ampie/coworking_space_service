#!/usr/bin/env bash

PASSWD_FILE="./postgresql.txt"

PGPASSWORD="$(cat ${PASSWD_FILE})" psql --host=127.0.0.1 --username=postgres --dbname=postgres --port=5432 <"$1"
