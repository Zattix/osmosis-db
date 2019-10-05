#!/usr/bin/env bash

wait_for_it() {
  attempts=10

  until PGPASSWORD=docker psql -h localhost -p 5432 -U docker -d postgres -c '\q' > /dev/null 2>&1 || [[ attempts -eq 0 ]]; do
    echo "Waiting for Postgis server, $((attempts--)) remaining attempts..."
    sleep 5
  done

  if [[ attempts -eq 0 ]]; then
    echo "Couldn't connect to Postgis server"
    exit 1
  fi
}

mkdir pgdata 2> /dev/null
sudo docker run --name postgis -d -v pgdata:/var/lib/postgresql/11/main -p 5432:5432 kartoza/postgis

wait_for_it

if [[ ! -f "./switzerland-padded.osm.pbf" ]]; then
  wget "https://planet.osm.ch/switzerland-padded.osm.pbf"
fi

PGPASSWORD=docker dropdb -h localhost -p 5432 -U docker osm
PGPASSWORD=docker createdb -h localhost -p 5432 -U docker osm
PGPASSWORD=docker psql -h localhost -p 5432 -U docker -d osm -c 'CREATE EXTENSION postgis; CREATE EXTENSION hstore;'
PGPASSWORD=docker osm2pgsql --create --latlong --username docker --database osm --host localhost --port 5432 ./switzerland-padded.osm.pbf