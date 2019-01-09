#!/usr/bin/env bash
if [ -z "$HOST" ]; then
  echo 'Specify a $HOST to get configuration for.'
  exit 1
fi
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
scp "$DIR"/getconfig.php "${HOST}":/tmp/
ssh "$HOST" php /tmp/getconfig.php acquia > currentconfig
ssh "$HOST" rm /tmp/getconfig.php