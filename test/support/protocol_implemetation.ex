defimpl Xcribe.Information, for: Xcribe.Request do
  def resource_description(%{controller: Elixir.Xcribe.ProtocolsController}),
    do: "Application protocols is a awesome feature of our app"

  def resource_description(_), do: nil

  def action_description(%{controller: Elixir.Xcribe.ProtocolsController, action: "index"}),
    do: "You can get all protocols with index action"

  def action_description(_), do: nil
end
