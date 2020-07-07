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
  config: :xcribe, :format, :swagger

  """

  defexception [:message]

  def exception(format) do
    %__MODULE__{message: "Configured format #{format} is unknown. \n#{@help_information}"}
  end
end

defmodule Xcribe.DocException do
  @moduledoc false
  defexception [:message, :request_error, :exception, :stacktrace]

  alias Xcribe.Request.Error

  def exception({request, exception, stacktrace}) do
    message = "An exception was raised. #{exception.__struct__}"

    %__MODULE__{
      message: message,
      exception: exception,
      stacktrace: Exception.format(:error, exception, stacktrace),
      request_error: %Error{
        __meta__: request.__meta__,
        type: :exception,
        message: message
      }
    }
  end
end

defmodule Xcribe.MissingInformationSource do
  @moduledoc false

  @help_information ~S"""
  You must create a module to implement `Xcribe.Information` and configure it:

  config: :xcribe, :information_source, YourInformationModule

  """

  defexception [:message]

  def exception(_) do
    %__MODULE__{message: "Information Source module not configured. \n#{@help_information}"}
  end
end
