defmodule Xcribe.Request do
  @moduledoc false

  defstruct [
    :__meta__,
    :action,
    :controller,
    :description,
    :endpoint,
    :path,
    :request_body,
    :resource,
    :resp_body,
    :status_code,
    :verb,
    header_params: [],
    resp_headers: [],
    path_params: %{},
    query_params: %{},
    params: %{},
    groups_tags: []
  ]

  def remove_ignored_prefixes(%__MODULE__{} = request, %{ignore_namespaces: prefixes})
      when is_list(prefixes) do
    Enum.reduce(prefixes, request, &remove_prefix/2)
  end

  defp remove_prefix(prefix, %{path: path, resource: resource, groups_tags: tags} = request) do
    formatted_prefix = format(prefix)

    %{
      request
      | path: String.replace_prefix(path, prefix, ""),
        resource: String.replace_prefix(resource, formatted_prefix, ""),
        groups_tags: replace_for_tags(tags, formatted_prefix)
    }
  end

  defp replace_for_tags([tag], prefix), do: [String.replace_prefix(tag, prefix, "")]
  defp replace_for_tags(tags, _prefix), do: tags

  defp format(prefix) do
    prefix
    |> String.split(~r"[/_]")
    |> Enum.map(&String.capitalize(&1))
    |> Enum.join("\s")
    |> String.trim()
    |> (fn p -> "#{p} " end).()
  end
end
