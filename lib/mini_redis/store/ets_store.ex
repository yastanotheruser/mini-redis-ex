defmodule MiniRedis.Store.EtsStore do
  @behaviour MiniRedis.Store

  use GenServer

  @ets_defaults [write_concurrency: :auto, read_concurrency: true]

  def start_link(table_opts) do
    GenServer.start_link(__MODULE__, table_opts, name: __MODULE__)
  end

  @impl MiniRedis.Store
  def set(key, value) do
    :ok = GenServer.cast(__MODULE__, {:set, key, value})
  end

  @impl MiniRedis.Store
  def get(key) do
    {:ok, GenServer.call(__MODULE__, {:get, key})}
  end

  @impl MiniRedis.Store
  def delete(keys) do
    {:ok, GenServer.call(__MODULE__, {:delete, keys})}
  end

  @impl MiniRedis.Store
  def child_spec(table_opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [table_opts]}
    }
  end

  @impl GenServer
  def init(table_opts) do
    table_opts = @ets_defaults ++ table_opts
    table = :ets.new(__MODULE__, table_opts)
    {:ok, table}
  end

  @impl GenServer
  def handle_call({:get, key}, _from, table) do
    value =
      case :ets.lookup(table, key) do
        [{^key, value}] -> value
        [] -> nil
      end

    {:reply, value, table}
  end

  def handle_call({:delete, keys}, _from, table) do
    objs = Enum.flat_map(keys, &:ets.take(table, &1))
    {:reply, length(objs), table}
  end

  @impl GenServer
  def handle_cast({:set, key, value}, table) do
    :ets.insert(table, {key, value})
    {:noreply, table}
  end
end
