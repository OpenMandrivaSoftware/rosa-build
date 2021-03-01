FROM ruby:2.6.6-alpine3.13 as rosa-build-gems

WORKDIR /rosa-build
RUN apk add --no-cache libpq tzdata ca-certificates git icu rpm nodejs python2 redis && \
    apk add --virtual .ruby-builddeps --no-cache postgresql-dev build-base cmake icu-dev
RUN gem install bundler:1.17.3
COPY vendor ./vendor
COPY Gemfile Gemfile.lock ./
RUN bundle install --without development test --jobs 16 --clean --deployment --no-cache --verbose && \
    apk add --no-cache file imagemagick curl gnupg openssh-keygen findutils && \
    apk del .ruby-builddeps && rm -rf /root/.bundle && rm -rf /proxy/vendor/bundle/ruby/2.6.0/cache && \
    git clone -b 2.2.0 https://github.com/pygments/pygments.git && cd pygments && python setup.py install && cd .. && rm -rf pygments && \
    cd /rosa-build/vendor/bundle/ruby && find -name *.o -exec rm {} \;

FROM scratch
COPY --from=rosa-build-gems / /

RUN touch /MIGRATE
ENV RAILS_ENV production

ENV GEM_HOME /usr/local/bundle
ENV BUNDLE_APP_CONFIG /usr/local/bundle
ENV DATABASE_URL postgresql://postgres@postgres/rosa-build?pool=100&prepared_statements=false

WORKDIR /rosa-build
COPY bin ./bin
COPY lib ./lib
COPY config ./config
COPY db ./db
COPY app/ ./app
COPY script ./script
COPY vendor ./vendor
COPY Rakefile config.ru entrypoint.sh entrypoint_sidekiq.sh ./
RUN git config --global user.email "abf@openmandriva.org"
RUN git config --global user.name "ABF"
ENTRYPOINT ["/rosa-build/entrypoint.sh"]
