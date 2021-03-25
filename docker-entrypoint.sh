#!/bin/sh
set -e

(cd ingress && python3 ingress.py) &
echo $! > /ingress/ingress.pid

exec nginx -g "daemon off;"