source 'https://rubygems.org'

gem 'rails'

gem 'activeadmin',                      github: 'activeadmin'
gem 'pg'
gem 'schema_plus'
########
gem 'devise', git: 'https://github.com/plataformatec/devise' #, ref: '88e9a85'
gem 'omniauth-github'
gem 'pundit'
gem 'rbtrace'
gem 'sentry-raven'

gem 'paperclip'
gem 'sinatra', :require => nil
gem 'sidekiq'
gem 'kiqit', :git => 'https://github.com/DuratarskeyK/kiqit.git'
gem 'sidekiq-scheduler', '~> 2.0'
gem 'sidekiq-failures'
gem 'russian'
gem 'state_machines-activerecord'
gem 'redis-rails'

gem 'jbuilder'
gem 'sprockets'
gem 'will_paginate'
gem 'meta-tags', require: 'meta_tags'
gem 'haml-rails'
gem 'ruby-haml-js'
gem 'slim'
gem 'simple_form', '3.1.0.rc2'
gem 'friendly_id'

gem 'rack-throttle', '~> 0.3.0'
gem 'rest-client'
gem 'ohm', '~> 1.3.2' # Ohm 2 breaks the compatibility with previous versions.
gem 'ohm-expire', '~> 0.1.3'

gem 'pygments.rb'

gem 'attr_encrypted'

# AngularJS related stuff
gem 'angular-rails-templates'
gem 'ng-rails-csrf'
gem 'angular-i18n'
gem 'js-routes'
gem 'soundmanager-rails'
gem 'ngannotate-rails'

gem 'time_diff'

gem 'sass-rails'
gem 'coffee-rails'

gem 'compass-rails'
gem 'uglifier'

gem 'rails-assets-notifyjs', '0.4.2', path: 'vendor/gems/rails-assets-notifyjs-0.4.2'

gem 'rack-utf8_sanitizer'
gem 'redis-semaphore'

#github api
gem "octokit", "~> 4.19"
gem 'faraday-http-cache'

group :production do
  gem 'puma'
end

group :development do
  gem 'mailcatcher' # 'letter_opener'
  gem 'rails3-generators'
  gem 'hirb'
  gem 'shotgun'
  gem 'state_machines-graphviz'
  # Better Errors & RailsPanel
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'meta_request'
  gem 'localeapp'
  #gem 'ruby-dbus' if RUBY_PLATFORM =~ /linux/i # Error at deploy
  gem 'rack-mini-profiler', require: false
end

group :development, :test do
  gem 'rspec-rails'
end

group :test do
  gem 'factory_girl_rails'
  gem 'rr'
  gem 'shoulda'
  gem 'shoulda-matchers'
  gem 'mock_redis'
  gem 'webmock'
  gem 'rake'
  gem 'test_after_commit'
  gem 'timecop'
end
