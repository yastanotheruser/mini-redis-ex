defmodule MiniRedis.MixProject do
  use Mix.Project

  def project do
    [
      app: :mini_redis,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :telemetry],
      mod: {MiniRedis.Application, []}
    ]
  end

  defp deps do
    [
      {:delta_crdt, "~> 0.6"},
      {:libcluster, "~> 3.3"}
    ]
  end
end
