# Dockerfile development version
FROM ruby:3.0.0

#ENV PORT=$PORT
ENV PORT=3000

RUN apt-get update -qq && apt-get install -y default-libmysqlclient-dev && rm -rf /var/cache/apk/*
#RUN gem install nokogiri --platform=ruby

# Install gems
WORKDIR /app
COPY . /app/

ENV BUNDLE_PATH /gems
RUN bundle lock --add-platform x86_64-linux
RUN bundle install


ENTRYPOINT [ "bin/rails" ]
CMD ["server", "-b", "0.0.0.0"]
EXPOSE $PORT