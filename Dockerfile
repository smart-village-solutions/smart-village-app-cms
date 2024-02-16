FROM ruby:2.7.5

RUN apt-get update && apt-get install -y curl apt-transport-https ca-certificates wget
RUN wget --no-check-certificate -qO - https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list
RUN curl -sL https://deb.nodesource.com/setup_12.x | bash
RUN apt-get install -y nodejs
RUN apt-get install -y yarn
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/* /usr/src/*

ENV DOCKERIZE_VERSION v0.6.1
RUN curl -L https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
  | tar -C /usr/local/bin -xz

WORKDIR /app

RUN gem install bundler -v 2.5.6
COPY Gemfile Gemfile.lock /app/
RUN gem install bundler
RUN bundle config set without "development test"
RUN bundle config set force_ruby_platform true
COPY . /app

RUN bundle install
RUN yarn install
RUN RAILS_ENV=development DATABASE_URL=nulldb://user:pass@127.0.0.1/dbname bundle exec rails assets:precompile

ENTRYPOINT ["/app/docker/entrypoint.sh"]

VOLUME /unicorn
VOLUME /assets

# Start the main process.
CMD ["bundle", "exec", "unicorn", "-c", "./config/unicorn.rb"]
