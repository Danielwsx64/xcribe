defmodule Xcribe.Recorder do
  @moduledoc false

  use GenServer

  alias Xcribe.{Request, Request.Error}

  def start_link(_opts \\ []), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  def init(state), do: {:ok, state}

  def save(%Request{} = request), do: GenServer.cast(__MODULE__, {:save, request})
  def save(%Error{} = error), do: GenServer.cast(__MODULE__, {:save, error})

  def get_all, do: GenServer.call(__MODULE__, :get_all)

  def clear, do: GenServer.call(__MODULE__, :clear)

  def handle_cast({:save, request}, records), do: {:noreply, [request | records]}

  def handle_call(:get_all, _from, records), do: {:reply, records, records}
  def handle_call(:clear, _from, records), do: {:reply, records, []}
end
