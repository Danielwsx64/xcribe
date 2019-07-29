defmodule Xcribe.Support.Information do
  use Xcribe.Information

  xcribe_info Elixir.Xcribe.ProtocolsController do
    description("Application protocols is a awesome feature of our app")
    parameters(server_id: "The id number of the server")

    attributes(
      name: "The protocol full name",
      priority: "the priority of the protocol. It could be 0 or 1"
    )

    actions(
      show: [
        description: "You can show a protocol with show action",
        parameters: [id: "the number id of the protocol"]
      ]
    )
  end
end
