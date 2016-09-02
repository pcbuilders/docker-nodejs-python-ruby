FROM beevelop/nodejs-python

MAINTAINER Maik Hummel <m@ikhummel.com>

RUN apt-get update && apt-get install -y ruby-full && \
    pip install livestreamer && \
    npm install -g request minimist && \
    gem install rake:'~> 0.9.6' httparty activesupport:'4.1.4' eventmachine --no-rdoc --no-ri && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    apt-get autoremove -y && \
    apt-get clean
WORKDIR /app
COPY app/* ./
RUN npm link request minimist
