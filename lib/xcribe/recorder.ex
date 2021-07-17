defmodule Xcribe.Recorder do
  @moduledoc false

  @empty_state %{errors: []}

  use GenServer

  alias Xcribe.{Request, Request.Error}

  def start_link(_opts \\ []), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def init(_state), do: {:ok, @empty_state}

  def add(%Request{} = request), do: GenServer.cast(__MODULE__, {:add_request, request})
  def add(%Error{} = error), do: GenServer.cast(__MODULE__, {:add_error, error})

  def pop_all, do: GenServer.call(__MODULE__, :pop_all)

  def handle_cast({:add_request, request}, records) do
    {:noreply, Map.update(records, request.endpoint, [request], &[request | &1])}
  end

  def handle_cast({:add_error, error}, records) do
    {:noreply, Map.update(records, :errors, [error], &[error | &1])}
  end

  def handle_call(:pop_all, _from, records), do: {:reply, records, @empty_state}
end
