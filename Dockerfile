FROM elixir:1.16.2-otp-26-alpine AS base

FROM base AS release
ARG MIX_ENV=prod
WORKDIR /app
RUN apk add build-base
COPY mix.exs mix.lock .
RUN mix deps.get && mix deps.compile
COPY config ./config
COPY lib ./lib
COPY rel ./rel
RUN mix release

FROM base
WORKDIR /app
COPY --from=release /app/_build/prod/rel/mini_redis .
ENTRYPOINT ["./bin/mini_redis"]
CMD ["start"]
