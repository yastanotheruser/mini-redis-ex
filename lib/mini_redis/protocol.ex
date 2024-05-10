defmodule MiniRedis.Protocol do
  @typep element_state :: :length | {:bytes, non_neg_integer, iodata}
  @type state ::
          :count
          | {:elements, left :: pos_integer, items :: [binary], element_state}
          | {:command, [binary, ...]}
          | :error

  @spec initial_state() :: state
  def initial_state, do: :count

  @spec read(binary, state) :: state
  def read(<<?*, count::binary>>, :count) when byte_size(count) > 0 do
    count
    |> trim_line_ending()
    |> Integer.parse()
    |> case do
      {n, ""} when n > 0 -> {:elements, n, [], :length}
      {_, ""} -> :count
      _ -> :error
    end
  end

  def read(packet, :count) do
    case String.split(packet) do
      [] -> :count
      words -> {:command, words}
    end
  end

  def read(<<?$, length::binary>>, {:elements, n, list, :length})
      when byte_size(length) > 0 do
    length
    |> trim_line_ending()
    |> Integer.parse()
    |> case do
      {len, ""} when len >= 0 -> {:elements, n, list, {:bytes, len, []}}
      _ -> :error
    end
  end

  def read(packet, {:elements, n, list, {:bytes, left, iodata}}) do
    packet_bytes = byte_size(packet)
    line_ending_bytes = if String.ends_with?(packet, "\r\n"), do: 2, else: 1

    cond do
      left >= packet_bytes ->
        elem_state = {:bytes, left - packet_bytes, [iodata, packet]}
        {:elements, n, list, elem_state}

      left == packet_bytes - line_ending_bytes ->
        chunk = binary_part(packet, 0, packet_bytes - line_ending_bytes)
        binary = IO.iodata_to_binary([iodata, chunk])
        list = [binary | list]
        n = n - 1

        if n == 0 do
          {:command, Enum.reverse(list)}
        else
          {:elements, n, list, :length}
        end

      true ->
        :error
    end
  end

  def read(_packet, _state), do: :error

  defp trim_line_ending(binary) when is_binary(binary) do
    bytes = byte_size(binary)

    case binary do
      <<b::size(bytes - 2)-binary, ?\r, ?\n>> -> b
      <<b::size(bytes - 1)-binary, ?\n>> -> b
      b -> b
    end
  end

  @spec write(term) :: binary | [binary]
  def write(int) when int in -0x7FFFFFFFFFFFFFFF..0x7FFFFFFFFFFFFFFF do
    ":#{int}"
  end

  def write(bigint) when is_integer(bigint) do
    "(#{bigint}"
  end

  def write(binary) when is_binary(binary) do
    ["$#{byte_size(binary)}", binary]
  end

  def write({:simple, binary}) when is_binary(binary) do
    "+#{binary}"
  end

  def write(list) when is_list(list) do
    ["*#{length(list)}" | Enum.map(list, &write/1)]
  end

  def write(nil), do: "_"

  def write(boolean) when is_boolean(boolean) do
    "##{if boolean, do: "t", else: "f"}"
  end

  def write(float) when is_float(float) do
    ",#{float}"
  end

  def write(%{} = map) when not is_struct(map) do
    packets = Enum.flat_map(map, fn {k, v} -> [write(k), write(v)] end)
    ["%#{map_size(map)}" | packets]
  end

  def write(%MapSet{} = set) do
    ["~#{MapSet.size(set)}" | Enum.map(set, &write/1)]
  end

  @spec write_packet(iodata) :: iodata
  def write_packet(packet), do: [packet, ?\r, ?\n]
end
