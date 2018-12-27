#!/usr/bin/env bash
set -e

export COMPOSE_FILE=docker-compose-7.1.yml
export COMPOSE_PROJECT_NAME=drupal_acquia_${BRANCH_NAME}

echo "Cleaning up any failed builds"
docker-compose rm -f
rm -rf docroot

echo "Building containers"
docker-compose build
echo "Downloading Drupal core"
docker run --volume "$(pwd)":/app --user $(id -u ${USER}):$(id -g ${USER}) drush/drush dl drupal -y --drupal-project-rename=docroot

echo "Starting containers"
docker-compose up --detach
sleep 10

# TODO: Actually install Drupal here and also test dumping and autoloading a database.

echo "Fetching page to check status"
STATUS=$(docker-compose run --rm php-fpm curl --location --silent --output /dev/null --write-out "%{http_code}" "http://httpd/")
echo "Status: ${STATUS}"
if [ "${STATUS}" != "200" ]; then
  echo "httpd container not responding with 200 HTTP response code"
  exit 1
fi

echo "Cleaning up"
docker-compose rm -f
rm -rf docroot