defmodule Xcribe.Support.Information do
  use Xcribe.Information

  xcribe_info Elixir.Xcribe.ProtocolsController do
    description("Application protocols is a awesome feature of our app")
    actions(index: "You can get all protocols with index action")
  end
end
