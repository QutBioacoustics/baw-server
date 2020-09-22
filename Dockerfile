# Debian releases:
#
FROM ruby:2.6-slim-buster
ARG app_name=baw-server
ARG app_user=baw_web
ARG version=

# install audio tools and other binaries
COPY ./provision/install_audio_tools.sh ./provision/install_postgresql_client.sh  /tmp/

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
  # - git: we'd like to remove git dependency but we have multiple git based dependencies
  # in our gem files
  # - curl is needed for passenger
  # - nano not needed for prod
  # - iproute2 install ip and basic network debugging tools
  # - gnupg is for validating apt public keys
  ca-certificates git curl gnupg nano iproute2 \
  # sqlite
  sqlite3 libsqlite3-dev libgmp-dev \
  # the following are for nokogiri and the like
  build-essential patch ruby-dev zlib1g-dev liblzma-dev \
  && chmod u+x /tmp/*.sh  \
  # for the pg gem we need postgresql-client (also used by rails rake db commands)
  && /tmp/install_postgresql_client.sh \
  # install audio tools and other binaries
  && /tmp/install_audio_tools.sh \
  && rm -rf /tmp/*.sh \
  && rm -rf /var/lib/apt/lists/*
RUN \
  # create a user for the app
  # -D is for defaults, which includes NO PASSWORD
  # adduser myappuser
  # we use useradd instead of adduser, since it can be done without any interactivity
  # might need to do some other stuff achieve the full effect of adduser.
  groupadd -g 1000 ${app_user} \
  && useradd -u 1000 -g ${app_user} ${app_user} \
  && mkdir -p /home/${app_user}/${app_name} \
  && chown -R ${app_user}:${app_user} /home/${app_user} \
  # allow bundle install to work as app_user
  # modified from here: https://github.com/docker-library/ruby/blob/6a7df7a72b4a3d1b3e06ead303841b3fdaca560e/2.6/buster/slim/Dockerfile#L114
  && mkdir -p "$GEM_HOME/bin" \
  && chmod 777 "$GEM_HOME/bin"


ENV RAILS_ENV=production \
  APP_USER=${app_user} \
  APP_NAME=${app_name} \
  BAW_SERVER_VERSION=${version} \
  # enable binstubs to take priority
  PATH=./bin:$PATH \
  BUNDLE_PATH__SYSTEM="true"


USER ${app_user}

RUN \
  # temporarily upgrade bundler until we can jump to ruby 2.7
  gem update --system \
  && gem install bundler

# change the working directory to the user's home directory
WORKDIR /home/${app_user}/${app_name}

ENTRYPOINT [ "./provision/entrypoint.sh" ]
CMD [ "passenger", "start" ]
# used for prod
EXPOSE 8888
# used for dev
EXPOSE 3000
VOLUME [ "/data" ]

# add base dependency files for bundle install (so we don't invalidate docker cache)
COPY --chown=${app_user} Gemfile Gemfile.lock  /home/${app_user}/${app_name}/

# install deps
# skip installing gem documentation
RUN \
  # We're trialing a simpler container setup
  #echo 'gem: --no-rdoc --no-ri' >> "$HOME/.gemrc" \
  bundle config set without development test \
  # install baw-server
  && bundle install

# Add the Rails app
COPY --chown=${app_user} ./ /home/${app_user}/${app_name}

# copy the passenger production config
# use a mount/volume to override this file for other environments
#
# For development we bind mount over the root of the app with development version
# Thus there is no conflict here
COPY ./provision/Passengerfile.production.json /home/${app_user}/${app_name}/Passengerfile.json

# asign permissions to special things
RUN  chmod a+x ./provision/*.sh \
  && chmod a+x ./bin/*

# precompile passenger standalone
RUN bundle exec passenger start --runtime-check-only
