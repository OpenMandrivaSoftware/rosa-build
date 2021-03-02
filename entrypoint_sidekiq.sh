#!/bin/sh
set -ex

cd /app/rosa-build

bundle exec sidekiq -q iso_worker_observer -q low -q middle -q notification -q publish_observer -q rpm_worker_observer -c 5 -e production
