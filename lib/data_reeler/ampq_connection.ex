defmodule DataReeler.AmpqConnection do
  @moduledoc """
  GenServer responsible for creating AMPQ messages
  """

  use GenServer

  require Logger

  # Client API

  def send_message(queue, message) when is_binary(message) do
    GenServer.call(__MODULE__, {:publish_message, queue, message})
  end

  def send_message(queue, message) do
    send_message(queue, Jason.encode!(message))
  end

  # Server API

  def start_link(_args) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl GenServer
  def init(_) do
    {:ok, connection} = AMQP.Connection.open("amqp://guest:guest@localhost")
    {:ok, channel} = AMQP.Channel.open(connection)

    Logger.debug("Started AMPQ connection")

    {:ok, %{connection: connection, channel: channel}}
  end

  @impl GenServer
  def terminate(_, %{connection: connection, channel: channel}) do
    AMQP.Channel.close(channel)
    AMQP.Connection.close(connection)

    Logger.debug("Stopping AMPQ connection")

    :ok
  end

  @impl GenServer
  def handle_call({:publish_message, queue, message}, _from, state) do
    %{channel: channel} = state

    AMQP.Basic.publish(channel, "", queue, message)

    Logger.debug("Sent AMPQ message to queue #{queue}")

    {:reply, :ok, state}
  end
end
