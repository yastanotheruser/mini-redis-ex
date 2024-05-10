defmodule MiniRedis.Application do
  use Application

  @defaults [port: 7963]

  @impl true
  def start(_type, _args) do
    {opts, _argv, _errors} =
      System.argv()
      |> OptionParser.parse(strict: [port: :integer])

    opts = Keyword.merge(@defaults, opts)
    topologies = Application.get_env(:libcluster, :topologies)

    children =
      [
        if Node.alive?() and topologies do
          {Cluster.Supervisor, [topologies, [name: MiniRedis.ClusterSupervisor]]}
        else
          []
        end,
        if MiniRedis.Store.has_child_spec?() do
          MiniRedis.Store.impl()
        else
          []
        end,
        {MiniRedis, opts}
      ]
      |> List.flatten()

    opts = [strategy: :one_for_one, name: MiniRedis.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
