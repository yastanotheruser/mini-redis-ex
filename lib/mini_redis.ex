defmodule MiniRedis do
  alias MiniRedis.{Command, Protocol, Store}

  @type option :: {:port, 1..65535}

  @spec start([option]) :: {:ok, pid}
  def start(opts) do
    {:ok, spawn(fn -> listen(opts) end)}
  end

  @spec start_link([option]) :: {:ok, pid}
  def start_link(opts) do
    case start(opts) do
      {:ok, pid} ->
        Process.link(pid)
        {:ok, pid}

      result ->
        result
    end
  end

  @spec child_spec([option]) :: Supervisor.child_spec()
  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  defp listen(opts) do
    port = Keyword.get(opts, :port, 7963)
    {:ok, socket} = :gen_tcp.listen(port, [:binary, packet: :line, reuseaddr: true])
    master_loop(socket)
  end

  defp master_loop(listen_socket) do
    listen_socket
    |> accept()
    |> master_loop()
  end

  defp accept(listen_socket) do
    {:ok, socket} = :gen_tcp.accept(listen_socket)

    pid =
      spawn(fn ->
        Protocol.initial_state()
        |> conn_loop(socket)
      end)

    :ok = :gen_tcp.controlling_process(socket, pid)
    listen_socket
  end

  defp conn_loop(:error = _state, socket) do
    send_error(:protocol, socket)
    :ok = :gen_tcp.close(socket)
  end

  defp conn_loop(state, socket) do
    receive do
      {:tcp, ^socket, packet} ->
        packet
        |> Protocol.read(state)
        |> case do
          {:command, [name | args]} ->
            name
            |> String.upcase()
            |> Command.parse(args)
            |> handle_parse_result(socket)

            Protocol.initial_state()

          state ->
            state
        end
        |> conn_loop(socket)

      {:tcp_closed, ^socket} ->
        :ok
    end
  end

  defp handle_parse_result(:ok, _socket), do: :ok

  defp handle_parse_result({:ok, cmd}, socket) do
    case execute(cmd) do
      :ok -> send_reply(socket)
      {:ok, reply} -> send_reply(reply, socket)
      {:error, error} -> send_error(error, socket)
    end
  end

  defp handle_parse_result(:error, socket) do
    send_error(:syntax, socket)
  end

  defp execute({:set, key, value}), do: Store.set(key, value)
  defp execute({:get, key}), do: Store.get(key)
  defp execute({:delete, keys}), do: Store.delete(keys)

  defp execute({:eval, ast}) do
    {result, _} = Code.eval_quoted(ast)
    {:ok, {:simple, inspect(result)}}
  end

  defp execute(:ping) do
    {:ok, {:simple, "PONG"}}
  end

  defp send_reply(socket) do
    send_reply({:simple, "OK"}, socket)
  end

  defp send_reply(reply, socket) do
    reply
    |> Protocol.write()
    |> send_packets(socket)
  end

  defp send_error(error, socket) do
    send_packets(["-ERR #{error_message(error)}"], socket)
  end

  defp send_packets([], _socket), do: :ok

  defp send_packets(packets, socket) when is_list(packets) do
    iodata = Enum.flat_map(packets, &Protocol.write_packet/1)
    :ok = :gen_tcp.send(socket, iodata)
  end

  defp send_packets(packet, socket), do: send_packets([packet], socket)

  defp error_message(:protocol), do: "protocol error"
  defp error_message(:syntax), do: "syntax error"
end
