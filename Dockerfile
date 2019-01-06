FROM debian:jessie

LABEL maintainer "opsxcq@strm.sh"

RUN apt-get update && \
    apt-get upgrade -y && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install \
    git tmux build-essential zlib1g zlib1g-dev \
    libxml2 libxml2-dev libxslt-dev locate \
    libreadline6-dev libcurl4-openssl-dev git-core \
    libssl-dev libyaml-dev openssl autoconf libtool \
    ncurses-dev bison curl wget xsel postgresql \
    postgresql-contrib postgresql-client libpq-dev \
    libapr1 libaprutil1 libsvn1 \
    libpcap-dev libsqlite3-dev libgmp3-dev \
    tor torsocks nasm vim nmap ntpdate && \
    rm -rf /var/lib/apt/lists/*

# Just a trick to keep it always doing the whole process
COPY README.md /

COPY tmux.conf /root/.tmux.conf

# Get Metasploit
RUN cd /opt && \
    git clone https://github.com/rapid7/metasploit-framework.git msf && \
    cd msf && \
    # Setup rvm
    curl -sSL https://rvm.io/mpapis.asc | gpg --import - && \
    curl -sSL https://rvm.io/pkuczynski.asc | gpg --import - && \
    curl -L https://get.rvm.io | bash -s stable && \
    /bin/bash -l -c "rvm requirements" && \
    /bin/bash -l -c "rvm install 2.3.1" && \
    /bin/bash -l -c "rvm use 2.3.1 --default" && \
    /bin/bash -l -c "source /usr/local/rvm/scripts/rvm" && \
    /bin/bash -l -c "gem install bundler" && \
    /bin/bash -l -c "source /usr/local/rvm/scripts/rvm && which bundle" && \
    /bin/bash -l -c "which bundle" && \
    # Install metasploit deps
    /bin/bash -l -c "BUNDLEJOBS=$(expr $(cat /proc/cpuinfo | grep vendor_id | wc -l) - 1)" && \
    /bin/bash -l -c "bundle config --global jobs $BUNDLEJOBS" && \
    /bin/bash -l -c "bundle install" && \
    # Just add some easy links
    for i in `ls /opt/msf/tools/*/*`; do ln -s $i /usr/local/bin/; done && \
    ln -s /opt/msf/msf* /usr/local/bin

# PosgreSQL setup
COPY ./db.sql /tmp/
RUN /etc/init.d/postgresql start && su postgres -c "psql -f /tmp/db.sql"

USER root
COPY ./database.yml /opt/msf/config/

COPY main.sh /

# Metasploit conf folders and a temp folder if you want to drop something there
VOLUME /root/.msf4/
VOLUME /tmp/data/

# For backconnect shellcodes (or payloads as if you want to use fancy names)
EXPOSE 4444

# For browser exploits
EXPOSE 80
EXPOSE 8080
EXPOSE 443
EXPOSE 445
EXPOSE 8081

ENTRYPOINT ["/main.sh"]

