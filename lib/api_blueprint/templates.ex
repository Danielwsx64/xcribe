defmodule Xcribe.ApiBlueprint.Templates do
  defmacro __using__(_opts \\ []) do
    quote do
      @metadata_template """
      FORMAT: 1A
      HOST: --host--

      # --name--
      --description--

      """
      @group_template "## Group --group_name--\n"
      @resource_template "## --resource_name-- --resource_path--\n"
      @parameters_template "+ Parameters\n\n--parameters_list--\n"
      @item_template "--prefix----param--: `--value--` (--type--) - --description--\n"
      @action_template "### --resource_name-- --action_name-- --resource_path--\n"
      @attributes_template "    + Attributes\n\n--attributes_list--\n"
      @headers_template "    + Headers\n\n--headers--\n"
      @header_item_template "            --header--: --value--\n"
      @request_template "+ Request --description-- (--content_type--)\n"
      @response_template "+ Response --code-- (--content_type--)\n"
      @body_template "    + Body\n\n--body--\n"
    end
  end
end
