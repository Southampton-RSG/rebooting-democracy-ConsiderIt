FROM ruby:2.7

RUN apt-get update && apt-get -y upgrade && \
    apt-get -y install advancecomp autoconf automake bison build-essential \
       curl exuberant-ctags gifsicle git-core imagemagick \
       jpegoptim libcurl4-openssl-dev libjpeg-progs libmagickcore-dev \
       libmagickwand-dev libreadline6-dev libmariadb-dev \
       libreadline-dev libssl-dev libncurses5-dev libtool libxml2-dev \
       libxslt1-dev memcached  openssl optipng nodejs npm \
       pngcrush python-apt-common python3-pip python3-mysqldb unattended-upgrades \
       unzip zlib1g zlib1g-dev libsqlite3-dev

RUN gem update --system && gem install bundler --no-document

COPY . app
WORKDIR /app
RUN cp config/docker_database.yml config/database.yml && \
    cp config/dev_local_environment.yml config/local_environment.yml && \
    rm Gemfile.lock && \
    gem install rails && \
    bundle install && \
    npm install

CMD bash /app/docker_start.sh