import Config

config :mini_redis,
  store: MiniRedis.Store.EtsStore

config :libcluster,
  topologies: [
    local_epmd: [
      strategy: Cluster.Strategy.LocalEpmd
    ]
  ]
