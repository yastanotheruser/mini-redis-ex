defmodule MiniRedis.Command do
  @type t ::
          {:set, key :: binary, value :: binary}
          | {:get, key :: binary}
          | {:delete, keys :: [binary]}
          | {:eval, Macro.t()}
          | :ping

  @spec parse([binary, ...]) :: :ok | {:ok, t} | :error
  def parse([cmd_name | args]) do
    cmd_name = String.upcase(cmd_name)
    parse(cmd_name, args)
  end

  def parse([]), do: :ok

  defp parse("SET", [key, value]) do
    {:ok, {:set, key, value}}
  end

  defp parse("GET", [key]) do
    {:ok, {:get, key}}
  end

  defp parse("DEL", [_ | _] = keys) do
    {:ok, {:delete, keys}}
  end

  defp parse("EVAL", [code]) do
    case Code.string_to_quoted(code) do
      {:ok, ast} -> {:ok, {:eval, ast}}
      {:error, _} -> :error
    end
  end

  defp parse("PING", []), do: {:ok, :ping}

  defp parse(_, _), do: :error
end
