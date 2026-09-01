defmodule Xcribe.APIModel.Route do
  @moduledoc false

  alias Xcribe.APIModel.{Merge, Operation}
  alias Xcribe.Request

  defstruct [:path, operations: []]

  def from_request(%Request{} = request, config),
    do: %__MODULE__{path: request.path, operations: [Operation.from_request(request, config)]}

  def merge(%__MODULE__{} = base, %__MODULE__{} = new) do
    %{
      base
      | operations:
          Merge.by_key(base.operations, new.operations, &Operation.sort_key/1, &Operation.merge/2)
    }
  end

  def sort_key(%__MODULE__{path: path}), do: path
end
