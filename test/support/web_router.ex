defmodule Xcribe.WebRouter do
  use Phoenix.Router

  import Phoenix.Controller

  pipeline :api do
    plug(:accepts, ["json"])
  end

  pipeline :authenticated do
    plug(:api)
    plug(Xcribe.Plugs.Authentication)
  end

  scope "/namespace_ignored", Xcribe do
    pipe_through(:api)

    resources("/notes", NotesController, only: [:index])
  end

  scope "/authenticated", Xcribe, as: :authenticated do
    pipe_through(:authenticated)

    resources("/users", UsersController)
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
