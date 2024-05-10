import Config

config :mini_redis,
  store: MiniRedis.Store.DistributedStore

config :libcluster,
  topologies: [
    kubernetes: [
      strategy: Cluster.Strategy.Kubernetes,
      config: [
        mode: :ip,
        kubernetes_node_basename: "mini_redis",
        kubernetes_selector: "app=mini-redis-ex",
        kubernetes_namespace: "default"
      ]
    ]
  ]
