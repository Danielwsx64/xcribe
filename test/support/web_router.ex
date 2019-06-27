defmodule Xcribe.WebRouter do
  use Phoenix.Router

  import Phoenix.Controller

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", Xcribe do
    pipe_through(:api)

    resources("/users", UsersController) do
      resources("/posts", PostsController)
    end
  end
end
