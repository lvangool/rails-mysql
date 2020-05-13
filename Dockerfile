# Dockerfile.production
FROM ruby:2.7
MAINTAINER maintainer@example.com

ENV NODE_ENV production
ENV RAILS_ENV production

RUN addgroup --gid 2917 user
RUN adduser --disabled-password --gecos '' --uid 2917 --gid 2917 user

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg -o /root/yarn-pubkey.gpg && apt-key add /root/yarn-pubkey.gpg
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list
RUN apt-get update && apt-get install -y --no-install-recommends nodejs yarn

ENV INSTALL_PATH /app
RUN mkdir -p $INSTALL_PATH
WORKDIR $INSTALL_PATH

# ensure bundler is present
RUN gem install bundler

# install gems
COPY Gemfile* $INSTALL_PATH/
RUN bundle install --without development test

# install yarn packages
COPY package.json yarn.lock $INSTALL_PATH/
RUN yarn install --check-files
RUN mv $INSTALL_PATH/node_modules /tmp/node_modules

# copy all code over
COPY . $INSTALL_PATH
RUN rm -rf $INSTALL_PATH/node_modules
RUN mv /tmp/node_modules $INSTALL_PATH/node_modules
RUN chown -R user:user $INSTALL_PATH

USER 2917
#RUN rails webpacker:install
RUN SECRET_KEY_BASE=`RAILS_ENV=development bin/rake secret` bin/rails assets:precompile
CMD bundle exec rails s -b 0.0.0.0
