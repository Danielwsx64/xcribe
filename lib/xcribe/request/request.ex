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
    :req_schema,
    :schema,
    header_params: [],
    resp_headers: [],
    path_params: %{},
    query_params: %{},
    params: %{},
    groups_tags: []
  ]

  def format_schema(%__MODULE__{schema: nil, status_code: status, resource: resource})
      when status >= 200 and status < 300 do
    String.replace(resource, " ", "")
  end

  def format_schema(%__MODULE__{schema: nil, status_code: status, resource: resource}) do
    String.replace("#{status}_#{resource}", " ", "")
  end

  def format_schema(%__MODULE__{schema: schema}), do: schema

  def format_req_schema(%__MODULE__{req_schema: nil, action: action, resource: resource}) do
    String.replace("#{action}#{resource}", " ", "")
  end

  def format_req_schema(%__MODULE__{req_schema: schema}), do: schema

  def remove_ignored_prefixes(%__MODULE__{} = request, %{
        ignore_namespaces: prefixes,
        ignore_resources_prefix: resources_prefixes
      })
      when is_list(prefixes) do
    with_out_namespaces = Enum.reduce(prefixes, request, &remove_prefix/2)

    Enum.reduce(resources_prefixes, with_out_namespaces, &remove_resource_prefix/2)
  end

  defp remove_prefix(prefix, %{path: path, resource: resource, groups_tags: tags} = request) do
    formatted_prefix = format(prefix)

    %{
      request
      | path: replace_and_trim(path, prefix),
        resource: replace_and_trim(resource, formatted_prefix),
        groups_tags: replace_for_tags(tags, formatted_prefix)
    }
  end

  defp remove_resource_prefix(prefix, %{resource: resource, groups_tags: tags} = request) do
    %{
      request
      | resource: replace_and_trim(resource, prefix),
        groups_tags: replace_for_tags(tags, prefix)
    }
  end

  defp replace_for_tags([tag], prefix), do: [replace_and_trim(tag, prefix)]
  defp replace_for_tags(tags, _prefix), do: tags

  defp replace_and_trim(string, pattern) do
    string
    |> String.replace_prefix(pattern, "")
    |> String.trim_leading()
  end

  defp format(prefix) do
    prefix
    |> String.split(~r"[/_]")
    |> Enum.map(&String.capitalize(&1))
    |> Enum.join("\s")
    |> String.trim()
  end
end
