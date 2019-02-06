defmodule ApiBluefy.WebRouter do
  use Phoenix.Router

  import Plug.Conn
  import Phoenix.Controller

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", ApiBluefy do
    pipe_through(:api)

    resources("/users", UsersController)
  end
end
