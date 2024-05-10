defmodule MiniRedis.Command do
  @type t ::
          {:set, key :: binary, value :: binary}
          | {:get, key :: binary}
          | {:delete, keys :: [binary]}
          | :ping

  @spec parse(String.t(), [binary]) :: :ok | {:ok, t} | :error
  def parse([cmd_name | args]) do
    cmd_name = String.upcase(cmd_name)
    parse(cmd_name, args)
  end

  def parse([]), do: :ok

  def parse("SET", [key, value]) do
    {:ok, {:set, key, value}}
  end

  def parse("GET", [key]) do
    {:ok, {:get, key}}
  end

  def parse("DEL", [_ | _] = keys) do
    {:ok, {:delete, keys}}
  end

  def parse("EVAL", [code]) do
    case Code.string_to_quoted(code) do
      {:ok, ast} -> {:ok, {:eval, ast}}
      {:error, _} -> :error
    end
  end

  def parse("PING", []), do: {:ok, :ping}

  def parse(_, _), do: :error
end
