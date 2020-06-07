defmodule Xcribe.ApiBlueprint do
  @moduledoc false

  alias Xcribe.ApiBlueprint.{APIB, Formatter}
  alias Xcribe.{Config, DocException}

  def generate_doc(requests) do
    requests
    |> apib_struct()
    |> APIB.encode()
  end

  def apib_struct(requests) do
    Map.put(
      xcribe_info(),
      :groups,
      reduce_groups(requests)
    )
  end

  defp reduce_groups(requests), do: Enum.reduce(requests, %{}, &format_and_merge/2)

  defp format_and_merge(request, acc) do
    item = Formatter.full_request_object(request)

    Formatter.merge_request(acc, item)
  rescue
    exception -> raise DocException, {request, exception, __STACKTRACE__}
  end

  defp xcribe_info, do: apply(Config.xcribe_information_source!(), :api_info, [])
end
