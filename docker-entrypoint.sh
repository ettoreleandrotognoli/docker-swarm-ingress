#!/bin/sh
set -e

nginx
exec python3 /ingress/ingress.py