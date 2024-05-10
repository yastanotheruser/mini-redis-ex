defmodule MiniRedis.Store.DistributedStore do
  @behaviour MiniRedis.Store

  crdt = __MODULE__.Crdt

  defmodule NeighbourMonitor do
    @crdt crdt

    def start(_arg) do
      pid =
        spawn(fn ->
          :net_kernel.monitor_nodes(true)
          loop()
        end)

      {:ok, pid}
    end

    def start_link(arg) do
      case start(arg) do
        {:ok, pid} ->
          Process.link(pid)
          {:ok, pid}

        result ->
          result
      end
    end

    def child_spec(arg) do
      %{
        id: __MODULE__,
        start: {__MODULE__, :start_link, [arg]}
      }
    end

    defp loop do
      neighbours = Node.list() |> Enum.map(&{@crdt, &1})
      DeltaCrdt.set_neighbours(@crdt, neighbours)

      receive do
        {:nodeup, _node} -> loop()
        {:nodedown, _node} -> loop()
      end
    end
  end

  defmodule CrdtSupervisor do
    use Supervisor

    def start_link(opts) do
      Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
    end

    @impl true
    def init(opts) do
      opts =
        opts
        |> Keyword.put_new(:crdt, DeltaCrdt.AWLWWMap)
        |> Keyword.put(:name, unquote(crdt))

      children = [
        {DeltaCrdt, opts},
        NeighbourMonitor
      ]

      Supervisor.init(children, strategy: :one_for_one)
    end
  end

  @crdt crdt

  @impl true
  def set(key, value) do
    DeltaCrdt.put(@crdt, key, value)
    :ok
  end

  @impl true
  def get(key) do
    {:ok, DeltaCrdt.get(@crdt, key)}
  end

  @impl true
  def delete(keys) do
    entries = DeltaCrdt.take(@crdt, Enum.uniq(keys))
    Enum.each(entries, fn {k, _v} -> DeltaCrdt.delete(@crdt, k) end)
    {:ok, Enum.count(entries)}
  end

  @impl true
  def child_spec(opts) do
    %{
      id: __MODULE__.CrdtSupervisor,
      start: {__MODULE__.CrdtSupervisor, :start_link, [opts]}
    }
  end
end
