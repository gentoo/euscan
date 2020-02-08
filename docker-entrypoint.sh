#! /usr/bin/env bash
# Copyright 2020 Gentoo Authors
# Licensed under the GNU General Public License v2

set -e
set -u

PS4='# '
set -x

id
ip addr

if [[ $# -gt 0 ]]; then
    exec "$@"
fi

python2 manage.py migrate

exec python2 manage.py runserver 0.0.0.0:55080
