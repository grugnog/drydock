#!/usr/bin/env bash
set -euo pipefail
SUPPORTED_PHP=( 7.1 7.2 )
if [ -z "$SITE" ]; then
    echo "Specify a Pantheon \$SITE to get configuration for."
    echo "e.g. export SITE=mysitename"
    echo "Must have a multidev instance for each supported PHP version (${SUPPORTED_PHP[*]})"
    echo "- PHP versions in each multidev must be configured with pantheon.yml."
    echo "- Multidevs should be named 'PHPx-y' where x and y are the PHP major and minor version."
    echo "- Each multidev must be in sftp mode (not git mode)."
    exit 1
fi
if [[ ! -f php/Dockerfile || ! -f mysql/Dockerfile || ! -f nginx/Dockerfile ]]; then
    echo "This script expects to be run in a directory with php, mysql and nginx subdirectories"
    echo "containing the Dockerfiles where the configuration will be updated."
    exit 1
fi

echo "Updating PHP configuration"
for PHP in "${SUPPORTED_PHP[@]}"; do
    MULTIDEV=php${PHP//[.]/-}
    echo "Getting config for $SITE -> $MULTIDEV"
    UUID=$(terminus site:lookup "${SITE}")
    HOST=${MULTIDEV}.${UUID}@appserver.${MULTIDEV}.${UUID}.drush.in
    sftp -o Port=2222 "${HOST}":code/ <<< $'rm getconfig.php'
    (
        cd "$( dirname "${BASH_SOURCE[0]}" )"
        sftp -o Port=2222 "${HOST}":code/ <<< $'put getconfig.php'
    )
    terminus remote:drush "${SITE}.${MULTIDEV}" php-script getconfig.php -- pantheon > php/"${PHP}"-config
    sftp -o Port=2222 "${HOST}":code/ <<< $'rm getconfig.php'
done

echo "Updating MariaDB version"
# Connect to the database and output the version string
RAWVERSION=$(terminus remote:drush "${SITE}.${MULTIDEV}" sqlq 'SHOW VARIABLES LIKE "version"')
# Extract the primary version number from the version string
MYSQLVERSION=$(echo "$RAWVERSION" | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+')
# Update the version number in the Dockerfile with the extracted number
sed -i'' -e "s/FROM mariadb:[0-9.]*$/FROM mariadb:$MYSQLVERSION/" mysql/Dockerfile

echo "Updating Nginx version and config"
# Get Nginx version number
NGINXVERSION=$(terminus remote:drush "${SITE}.${MULTIDEV}" ev "shell_exec('/usr/sbin/nginx -v')" | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+')
# Update the version number in the Dockerfile with the extracted number
sed -i'' -e "s/FROM nginx:[0-9.]*$/FROM nginx:$NGINXVERSION/" nginx/Dockerfile
(
    # Fetch a sample nginx.conf
    cd nginx
    sftp -o Port=2222 "${HOST}":code/ <<< $'get ../nginx.conf'
    # Update the config to work in Docker and remove access keys etc
    sed -i'' \
        -e 's@listen \[::\]@#listen [::]@g' \
        -e 's@listen [0-9]* ssl;@listen 80;@g' \
        -e 's@/srv/bindings/[^/]*/code/@/var/www/docroot/@g' \
        -e 's@/srv/bindings/[^/]*/logs/nginx-\(access\|error\).log@/var/log/nginx/\1.log@g' \
        -e 's@/srv/bindings/[^/]*/mime.types@/etc/nginx/mime.types@g' \
        -e 's@/srv/bindings/[^/]*/@/var/@g' \
        -e 's@.*X-Pantheon-.*@@g' \
        -e "s@_access_key != '[^']*'@_access_key != 'docker'@g" \
        -e 's@/srv/includes/fastcgi_params@/etc/nginx/fastcgi_params@g' \
        -e 's@^[ ]*ssl_@# ssl_@g' \
        -e 's@fastcgi_pass [^;]*;@fastcgi_pass php:9000;@g' \
        nginx.conf
)