defmodule Xcribe.Recorder do
  @moduledoc false
  use GenServer

  @empty_records %{errors: []}

  alias Xcribe.{Config, Request, Request.Error}

  def start_link(_opts \\ []), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def init(_state) do
    active = (Config.active?() && true) || false

    {:ok, %{active?: active, records: @empty_records}}
  end

  def add(%Request{} = request), do: GenServer.cast(__MODULE__, {:add_request, request})
  def add(%Error{} = error), do: GenServer.cast(__MODULE__, {:add_error, error})

  def pop_all, do: GenServer.call(__MODULE__, :pop_all)

  def active?, do: GenServer.call(__MODULE__, :active?)

  def set_active(value) when is_boolean(value),
    do: GenServer.call(__MODULE__, {:set_active, value})

  def handle_cast({:add_request, request}, %{records: records} = state) do
    {:noreply, %{state | records: add(records, request.endpoint, request)}}
  end

  def handle_cast({:add_error, error}, %{records: records} = state) do
    {:noreply, %{state | records: add(records, :errors, error)}}
  end

  def handle_call(:pop_all, _from, %{records: records} = state) do
    {:reply, records, %{state | records: @empty_records}}
  end

  def handle_call(:active?, _from, %{active?: active} = state) do
    {:reply, active, state}
  end

  def handle_call({:set_active, value}, _from, state) do
    {:reply, :ok, %{state | active?: value}}
  end

  defp add(records, key, value), do: Map.update(records, key, [value], &[value | &1])
end
