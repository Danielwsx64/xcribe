defmodule Xcribe.WebRouter do
  use Phoenix.Router

  import Phoenix.Controller

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", Xcribe do
    pipe_through(:api)

    resources("/users", UsersController) do
      post("/cancel", UsersController, :cancel, as: :cancel)

      resources("/posts", PostsController) do
        resources("/comments", PostCommentsController)
      end
    end
  end
end
