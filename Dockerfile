FROM ruby:2.2.1-wheezy

RUN apt-get install aspell libaspell-dev

RUN gem install ffi-aspell

ADD docker_parser.rb /docker_parser.rb

CMD ["ruby", "/docker_parser.rb"]