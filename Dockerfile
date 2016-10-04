FROM ubuntu:14.04

RUN locale-gen uk_UA
RUN locale-gen uk_UA.UTF-8
RUN locale-gen en_US
RUN locale-gen en_US.UTF-8

RUN export LANGUAGE="en_US.UTF-8"
RUN export LANG="en_US.UTF-8"
RUN export LC_ALL="en_US.UTF-8"

RUN dpkg-reconfigure locales

RUN echo "Europe/Kiev" > /etc/timezone
RUN  dpkg-reconfigure -f noninteractive tzdata

RUN apt-get -qq update
RUN apt-get install -qq -y wget

RUN sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" >> /etc/apt/sources.list.d/pgdg.list'

RUN wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O - | sudo apt-key add -

RUN apt-get -qq update && DEBIAN_FRONTEND=noninteractive apt-get install -y -q postgresql-9.5 postgresql-contrib-9.5 postgresql-9.5-postgis-2.1 libpq-dev sudo

# /etc/ssl/private can't be accessed from within container for some reason
# (@andrewgodwin says it's something AUFS related)
RUN mkdir /etc/ssl/private-copy; mv /etc/ssl/private/* /etc/ssl/private-copy/; rm -r /etc/ssl/private; mv /etc/ssl/private-copy /etc/ssl/private; chmod -R 0700 /etc/ssl/private; chown -R postgres /etc/ssl/private

RUN apt-get install -qq -y vim
RUN apt-get install -qq -y postgresql-plpython-9.5

ADD conf/postgresql.conf /etc/postgresql/9.5/main/postgresql.conf
ADD conf/pg_hba.conf /etc/postgresql/9.5/main/pg_hba.conf
RUN chown postgres:postgres /etc/postgresql/9.5/main/*.conf
ADD run.sh /usr/local/bin/run.sh
RUN chmod +x /usr/local/bin/run.sh

VOLUME ["/var/lib/postgresql"]
EXPOSE 5432
CMD ["/usr/local/bin/run.sh"]
