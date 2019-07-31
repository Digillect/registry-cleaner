FROM ruby:2.6

RUN gem install bundler

WORKDIR /app

COPY gems.* /app/
RUN bundle install

COPY *.rb /app/
COPY src/*.rb /app/src/

CMD ["ruby", "main.rb"]
