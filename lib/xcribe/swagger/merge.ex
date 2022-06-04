defmodule Xcribe.Swagger.Merge do
  alias Xcribe.Schema

  def paths(base, new) do
    Enum.reduce(new, base, fn {name, verbs}, all ->
      Map.update(all, name, verbs, &merge_verbs(&1, verbs))
    end)
  end

  def parameters([], new), do: new
  def parameters(base, []), do: base

  def parameters(base, new) do
    new
    |> Map.new(&map_parameters/1)
    |> Enum.reduce(Map.new(base, &map_parameters/1), fn {name, param}, all ->
      Map.update(all, name, param, &merge_params(&1, param))
    end)
    |> Map.values()
  end

  def responses(base, new) do
    Enum.reduce(new, base, fn {status, response}, all ->
      Map.update(all, status, response, &merge_response(&1, response))
    end)
  end

  defp merge_verbs(base, new) do
    Enum.reduce(new, base, fn {name, verb}, all ->
      Map.update(all, name, verb, &merge_verb(&1, verb))
    end)
  end

  defp merge_verb(base, new) do
    merge_request_body(
      %{
        base
        | parameters: parameters(base.parameters, new.parameters),
          security: merge_security(base.security, new.security),
          tags: merge_tags(base.tags, new.tags),
          responses: responses(base.responses, new.responses)
      },
      new
    )
  end

  defp merge_response(base, new) do
    content = merge_content(Map.get(base, :content, %{}), Map.get(new, :content, %{}))

    updated = %{
      base
      | headers: Map.merge(Map.get(base, :headers, %{}), Map.get(new, :headers, %{}))
    }

    if content != %{} do
      Map.put(updated, :content, content)
    else
      updated
    end
  end

  defp merge_request_body(base, new) do
    merged =
      Map.update(base, :requestBody, Map.get(new, :requestBody, %{}), fn requestBody ->
        Map.put(
          requestBody,
          :content,
          merge_content(
            Map.get(requestBody, :content, %{}),
            get_in(new, [:requestBody, :content]) || %{}
          )
        )
      end)

    if merged.requestBody == %{} do
      base
    else
      merged
    end
  end

  defp merge_content(base, new) do
    Enum.reduce(new, base, fn {content_type, schema}, all ->
      Map.update(all, content_type, schema, &merge_content_schema(&1, schema))
    end)
  end

  defp merge_content_schema(%{schema: %{oneOf: schemas}}, %{schema: new}) do
    %{schema: %{oneOf: Enum.uniq_by([new | schemas], & &1["$ref"])}}
  end

  defp merge_content_schema(%{schema: s} = base, %{schema: s} = _new) do
    base
  end

  defp merge_content_schema(%{schema: base}, %{schema: new}) do
    %{schema: %{oneOf: [base, new]}}
  end

  defp merge_params(%{schema: %{type: "object"}} = base, %{schema: %{type: "object"}} = new) do
    %{
      base
      | example: Map.merge(Map.get(base, :example, %{}), new.example),
        schema: Schema.merge(Map.get(base, :schema, %{}), new.schema)
    }
  end

  defp merge_params(%{schema: %{type: type}} = base, %{schema: %{type: type}} = new) do
    Map.merge(base, new)
  end

  defp merge_params(_base, new_with_diff_type), do: new_with_diff_type

  defp merge_security(base, new) do
    base
    |> Enum.concat(new)
    |> Enum.uniq_by(&Map.keys(&1))
  end

  defp merge_tags(base, new) do
    base
    |> Enum.concat(new)
    |> Enum.uniq()
  end

  defp map_parameters(%{name: name, in: inn} = param), do: {{name, inn}, param}
end
