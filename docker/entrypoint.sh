#!/bin/sh

set -e

# Remove a potentially pre-existing server.pid for Rails.
rm -f /myapp/tmp/pids/server.pid
rm -f /unicorn.pid

npm set audit false

exec "$@"
