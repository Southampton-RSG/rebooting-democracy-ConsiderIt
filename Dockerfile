FROM ubuntu:22.04
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get -y upgrade && \
    apt-get -y install advancecomp autoconf automake bison build-essential \
       curl exuberant-ctags gifsicle git-core imagemagick \
       jpegoptim libcurl4-openssl-dev libjpeg-progs libmagickcore-dev \
       libmagickwand-dev libmysqlclient-dev libreadline6-dev \
       libreadline-dev libssl-dev libncurses5-dev libtool libxml2-dev \
       libxslt1-dev memcached mysql-server openssl optipng nodejs npm \
       pngcrush python-apt-common python3-pip python3-mysqldb unattended-upgrades \
       unzip zlib1g zlib1g-dev libsqlite3-dev

RUN git clone https://github.com/sstephenson/rbenv.git ~/.rbenv && \
    git clone https://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build

ENV PATH $PATH:/root/.rbenv/bin:/root/.rbenv/plugins/ruby-build/bin:/root/.rbenv/shims
ENV RBENV_SHELL bash

RUN rbenv init - && rbenv install -v 2.7.0 && rbenv global 2.7.0 && \
    gem update --system && gem install bundler --no-document

RUN service mysql restart && mysqladmin -u root password root && \
    echo "create database considerit_dev;" | mysql -u root -proot

COPY . app
WORKDIR /app
RUN cp config/dev_database.yml config/database.yml && \
    cp config/dev_local_environment.yml config/local_environment.yml && \
    rm Gemfile.lock && \
    gem install rails && \
    bundle install && \
    npm install

RUN service mysql restart && \
    rake db:schema:load && \
    rake db:migrate && \
    bin/delayed_job restart

CMD bash /app/docker_start.sh