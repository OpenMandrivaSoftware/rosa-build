#!/bin/sh
set -ex

cd /app/rosa-build

if [ -f /MIGRATE ]
then
        bundle exec rake db:migrate
        rm /MIGRATE
fi

rm -rf public/assets/*
bundle exec rake assets:precompile
cd public/assets
rm -f new_application.css new_application.js
ln -sv new_application*.css new_application.css
ln -sv new_application*.js new_application.js
cd ../..
RUBYOPT="-W0" bundle exec puma -C config/puma/production.rb
