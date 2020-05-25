defmodule Xcribe.ApiBlueprint.Templates do
  @moduledoc false

  defmacro __using__(_opts \\ []) do
    quote do
      @metadata_template """
      FORMAT: 1A
      HOST: --host--

      # --name--
      --description--

      """
      @group_template "## Group --identifier--\n"
      @resource_template "## --identifier-- [--uri_template--]\n"
      @parameters_template "+ Parameters\n\n--parameters_list--\n"
      @item_template "--prefix----param--: `--value--` (--type--) - --description--\n"
      @action_template "### --identifier_resource-- --identifier_action-- [--request_method-- --uri_template--]\n"
      @attributes_template "    + Attributes\n\n--attributes_list--\n"
      @headers_template "    + Headers\n\n--headers--\n"
      @header_item_template "            --header--: --value--\n"
      @request_template "+ Request --identifier-- (--media_type--)\n"
      @response_template "+ Response --code-- (--media_type--)\n"
      @body_template "    + Body\n\n--body--\n"
    end
  end
end
