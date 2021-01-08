FROM elixir:1.11.3-alpine AS build_stage

RUN mix local.hex --force
RUN mix local.rebar --force

COPY mix.* ./
RUN mix do deps.get, deps.compile

COPY lib lib
ENV MIX_ENV=prod
RUN mix release

FROM elixir:1.11.3-alpine AS run_stage

RUN mkdir /app
WORKDIR /app

COPY --from=build_stage $HOME/_build .
COPY build frontend

EXPOSE 80

CMD ["prod/rel/yagg_server/bin/yagg_server", "start"]
