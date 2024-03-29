FROM ruby:2.7.1
RUN apt-get update -qq && \
    apt-get install -y build-essential libpq-dev default-mysql-client && \
    ln -sf /usr/share/zoneinfo/America/Los_Angeles /etc/localtime && \
    rm -rf /var/lib/apt/lists/*
# Necessary for bundler to properly install some gems
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
RUN mkdir /data
WORKDIR /data
ADD Gemfile /data/Gemfile
ADD Gemfile.lock /data/Gemfile.lock
RUN gem install bundler && bundle update --bundler && bundle install
ADD . /data
RUN cd /data && rm -f Dockerfile build.sh docker-compose* log/*
#RUN bundle exec rake assets:precompile
EXPOSE 3000
