defmodule Xcribe.ContentDecoder.UnknownType do
  @moduledoc false
  defexception [:message]

  def exception(type) do
    %__MODULE__{message: "Couldn't decode value. Type #{type} is unknown."}
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
