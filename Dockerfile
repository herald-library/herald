FROM elixir:1.8-alpine

ARG MIX_ENV=dev
ENV MIX_ENV=${MIX_ENV}

WORKDIR /srv/app

COPY . .

RUN apk add -Uuv make build-base

RUN mix local.hex --force
RUN mix local.rebar --force

RUN mix deps.get
RUN mix compile
