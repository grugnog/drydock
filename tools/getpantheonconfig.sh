#!/usr/bin/env bash
set -euo pipefail
SUPPORTED_PHP=( 7.1 7.2 )
if [ -z "$SITE" ]; then
  echo 'Specify a Pantheon $SITE to get configuration for.'
  echo 'e.g. export SITE=mysitename'
  echo "Must have a multidev instance for each supported PHP version (${SUPPORTED_PHP[*]})"
  echo '- PHP versions in each multidev must be configured with pantheon.yml.'
  echo '- Multidevs should be named `PHPx-y` where x and y are the PHP major and minor version.'
  echo '- Each multidev must be in sftp mode (not git mode).'
  exit 1
fi
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
  terminus remote:drush "${SITE}.${MULTIDEV}" php-script getconfig.php -- pantheon > "${PHP}"-config
  sftp -o Port=2222 "${HOST}":code/ <<< $'rm getconfig.php'
done