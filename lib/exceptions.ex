defmodule Xcribe.ContentDecoder.UnknownType do
  @moduledoc false
  defexception [:message]

  def exception(type) do
    %__MODULE__{message: "Couldn't decode value. Type #{type} is unknown."}
  end
end

defmodule Xcribe.UnknownFormat do
  @moduledoc false

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

defmodule Xcribe.MissingInformationSource do
  @moduledoc false

  @help_information ~S"""
  You must create a module to implement `Xcribe.Information` and configure it:

      config: :xcribe, :configuration, information_source: YourInformationModule

  """

  defexception [:message]

  def exception(_) do
    %__MODULE__{message: "Information Source module not configured. \n#{@help_information}"}
  end
end
