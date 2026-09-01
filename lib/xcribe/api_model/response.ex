defmodule Xcribe.APIModel.Response do
  @moduledoc false

  alias Xcribe.APIModel.{Body, Merge, Parameter}

  defstruct [:status, headers: [], content: []]

  def new(status, headers, content) do
    %__MODULE__{
      status: status,
      headers: Merge.by_key([], headers, &Parameter.sort_key/1, &Parameter.merge/2),
      content: Merge.by_key([], content, &Body.sort_key/1, &Body.merge/2)
    }
  end

  def merge(%__MODULE__{} = base, %__MODULE__{} = new) do
    %{
      base
      | headers:
          Merge.by_key(base.headers, new.headers, &Parameter.sort_key/1, &Parameter.merge/2),
        content: Merge.by_key(base.content, new.content, &Body.sort_key/1, &Body.merge/2)
    }
  end

  def sort_key(%__MODULE__{status: status}), do: status
end
