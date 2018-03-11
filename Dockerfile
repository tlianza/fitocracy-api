FROM debian:stretch-slim

RUN apt-get update
RUN apt-get install -y bundler zlib1g-dev sqlite3 libsqlite3-dev procps curl
RUN curl -sSL https://rvm.io/mpapis.asc | gpg --import -
RUN curl -sSL https://get.rvm.io | bash -s stable --ruby

WORKDIR /fitocracy-api
RUN adduser --disabled-password --gecos "" fitocracy-api
RUN mkdir /fitocracy-db
RUN chown fitocracy-api:fitocracy-api /fitocracy-db
RUN bundle config --global silence_root_warning 1

ADD Gemfile /fitocracy-api
ADD Gemfile.lock /fitocracy-api
RUN bundle install

USER fitocracy-api
ADD . /fitocracy-api

ENTRYPOINT ["unicorn"]