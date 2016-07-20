FROM ruby:2.2.1
MAINTAINER Chris Cox <chris.cox37@t-mobile.com>

RUN apt-get update && \
    apt-get install -y net-tools

ADD Gemfile* ./
RUN bundle install

RUN mkdir -p lib
RUN mkdir -p bin
RUN mkdir -p config/certs/mas
RUN mkdir -p assets/scripts
RUN mkdir -p assets/payload_templates
RUN mkdir -p /var/log/feronia/

# These credentials won't change too often
ADD config/certs/mas/client.pem config/certs/mas/
ADD config/certs/mas/client_cert.pem config/certs/mas/
ADD config/certs/mas/client_key.pem config/certs/mas/
ADD config/certs/mas/staging_client_cert.pem config/certs/mas/
ADD config/certs/mas/staging_client_key.pem config/certs/mas/

# The payload templates won't change often, but new ones will get added
ADD assets/payload_templates/*.json assets/payload_templates/

# Add application code/configs
ADD config/services.json config/
ADD lib/service.rb lib/
ADD bin/feronia_web.rb bin/

# Start the server
EXPOSE 4567
CMD ["ruby", "bin/feronia_web.rb"]
