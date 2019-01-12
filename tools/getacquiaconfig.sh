#!/usr/bin/env bash
set -euo pipefail
SUPPORTED_PHP=( 7.1 7.2 )
if [ -z "$HOST" ]; then
  echo 'Specify a $HOST to get configuration for.'
  exit 1
fi
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
scp "$DIR"/getconfig.php "${HOST}":/tmp/
for PHP in "${SUPPORTED_PHP[@]}"; do
  echo "Getting config for $HOST -> $PHP"
  ssh "$HOST" "/usr/local/php${PHP}/bin/php" /tmp/getconfig.php acquia > "${PHP}"-config
done
ssh "$HOST" rm /tmp/getconfig.php