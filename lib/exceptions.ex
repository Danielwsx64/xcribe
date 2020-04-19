defmodule Xcribe.ContentDecoder.UnknownType do
  @moduledoc """
  Raised at runtime when can't decode an unknown content type.
  """

  defexception [:message]

  def exception(type) do
    %__MODULE__{message: "Couldn't decode value. Type #{type} is unknown."}
  end
end

defmodule Xcribe.UnknownFormat do
  @moduledoc """
  Raised at runtime when configured format is unknown.
  """

  @help_information ~S"""
  Current supported formats are :api_blueprint and :swagger.

  You should configure it in your `test/config` as:
      config: :xcribe, :configuration, format: :swagger

  """

  defexception [:message]

  def exception(format) do
    %__MODULE__{message: "Configured format #{format} is unknown. \n#{@help_information}"}
  end
end
