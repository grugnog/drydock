#!/usr/bin/env bash
set -e

echo "Building containers"
docker-compose --file docker-compose-7.1.yml build
echo "Downloading Drupal core"
docker run --volume "$(pwd)":/app --user $(id -u ${USER}):$(id -g ${USER}) drush/drush dl drupal -y --drupal-project-rename=docroot

echo "Starting containers"
docker-compose --file docker-compose-7.1.yml up -d
sleep 10

# TODO: Actually install Drupal here and also test dumping and autoloading a database.

HTTPD=$(docker-compose --file docker-compose-7.1.yml ps --quiet httpd)
IP=$(docker inspect --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "${HTTPD}")
echo "Fetching page from ${IP} to check status"
STATUS=$(curl --location --silent --output /dev/null --write-out "%{http_code}" "${IP}")
echo "Status: ${STATUS}"
if [ "${STATUS}" -ne "200" ]; then
  echo "httpd container not responding with 200 HTTP response code"
  exit 1
fi

echo "Cleaning up"
docker-compose --file docker-compose-7.1.yml rm -f
rm -rf docroot