FROM elixir:1.3.4

ENV TROXY_USERNAME user
ENV TROXY_PASSWORD pass

COPY . /app
WORKDIR /app

RUN mix local.hex --force
RUN mix deps.get
CMD elixir --no-halt -S mix server
