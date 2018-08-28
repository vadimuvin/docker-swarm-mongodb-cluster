FROM mongo:3.6-jessie

WORKDIR /setup

ADD ./configure.sh /setup/configure.sh
ADD ./configure.js /setup/configure.js
ADD ./rs.js /setup/rs.js

CMD ["/setup/configure.sh"]
