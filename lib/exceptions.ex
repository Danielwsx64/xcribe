defmodule Xcribe.ContentDecoder.UnknownType do
  @moduledoc """
  Raised at runtime when can't decode an unknown content type.
  """

  defexception [:message]

  def exception(type) do
    %__MODULE__{message: "Couldn't decode value. Type #{type} is unknown."}
  end
end
