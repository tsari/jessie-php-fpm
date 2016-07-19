#!/bin/bash
# general good practice (stop on error, missing variables):
set -eu

# Creating user: $USER ($UID:$GID)
#groupadd --system --gid=$GID $USER && useradd --system --create-home --gid=$GID --uid=$UID $USER && \

exec php-fpm7.0