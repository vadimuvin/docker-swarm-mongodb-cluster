FROM mongo:3.6-jessie

ADD ./mongo.keyfile /etc/mongo.keyfile
ADD ./ssl/mongo0.pem /etc/mongo0.pem
ADD ./ssl/mongo1.pem /etc/mongo1.pem
ADD ./ssl/mongo2.pem /etc/mongo2.pem
ADD ./ssl/ca.crt /etc/mongo-ca.crt

RUN chown mongodb /etc/mongo.keyfile && \
    chmod 400 /etc/mongo.keyfile && \
    chown mongodb /etc/mongo*.pem && \
    chmod 400 /etc/mongo*.pem && \
    chown mongodb /etc/mongo-ca.crt && \
    chmod 400 /etc/mongo-ca.crt
