#!/usr/bin/env bash
if [ -z "$SITE" ]; then
  echo 'Specify a Pantheon $SITE to get configuration for.'
  echo 'e.g. export SITE=mysitename'
  echo 'Sites dev instance must be in sftp mode'
  exit 1
fi
UUID=$(terminus site:lookup "${SITE}")
HOST=dev.${UUID}@appserver.dev.${UUID}.drush.in
sftp -o Port=2222 "${HOST}":code/ <<< $'rm getconfig.php'
(
  cd "$( dirname "${BASH_SOURCE[0]}" )"
  sftp -o Port=2222 "${HOST}":code/ <<< $'put getconfig.php'
)
terminus remote:drush "${SITE}.dev" php-script getconfig.php -- pantheon > currentconfig
sftp -o Port=2222 "${HOST}":code/ <<< $'rm getconfig.php'