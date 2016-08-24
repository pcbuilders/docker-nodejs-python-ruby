FROM beevelop/nodejs-python

MAINTAINER Maik Hummel <m@ikhummel.com>

WORKDIR /app
COPY app/* ./

RUN chmod +x /app/run.sh && \
    apt-get update && apt-get install -y ruby-full && \
    pip install livestreamer && \
    npm install -g googleapis log4js minimist && \
    gem install rake:'~> 0.9.6' httparty activesupport:'4.1.4' eventmachine --no-rdoc --no-ri && \
    npm link googleapis log4js minimist && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    apt-get autoremove -y && \
    apt-get clean
ENTRYPOINT ["./run.sh"]
