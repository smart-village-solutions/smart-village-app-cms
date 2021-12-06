FROM registry.gitlab.tpwd.de/cmmc-systems/ruby-nginx/ruby-2.7.1

RUN apk update && apk upgrade

RUN apk add sqlite
RUN apk add sqlite-dev
RUN apk add nodejs
RUN apk add npm
RUN apk add yarn

RUN mkdir -p /unicorn
RUN mkdir -p /app
WORKDIR /app

COPY . .

# COPY docker/database.yml /app/config/database.yml
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY docker/unicorn.rb /app/config/unicorn.rb

RUN chmod +x /app/docker/entrypoint.sh

COPY Gemfile Gemfile.lock /app/

RUN gem install bundler
RUN bundle config set --local without 'development test'
RUN bundle install

RUN yarn
RUN rake assets:precompile

ENTRYPOINT ["/app/docker/entrypoint.sh"]

# Start the main process.
CMD ["sh", "-c", "nginx-debug ; bundle exec unicorn -c config/unicorn.rb"]
