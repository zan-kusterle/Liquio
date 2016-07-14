defmodule Democracy.Web do
  @moduledoc """
  A module that keeps using definitions for controllers,
  views and so on.

  This can be used in your application as:

      use Democracy.Web, :controller
      use Democracy.Web, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below.
  """

  def model do
    quote do
      use Ecto.Schema

      import Ecto
      import Ecto.Changeset
      import Ecto.Query, only: [from: 1, from: 2]

      use Timex.Ecto.Timestamps, usec: true
    end
  end

  def controller do
    quote do
      use Phoenix.Controller

      alias Democracy.Repo
      import Ecto
      import Ecto.Query, only: [from: 1, from: 2]

      import Democracy.Router.Helpers
      import Democracy.Gettext

      import Democracy.Plugs.Params, only: [with_params: 2]

		alias Democracy.Plugs
		alias Democracy.Identity
		alias Democracy.Delegation
		alias Democracy.Vote
		alias Democracy.Poll
		alias Democracy.Reference
		alias Democracy.Result


        def redirect_back(conn) do
			case List.keyfind(conn.req_headers, "referer", 0) do
				{"referer", referer} ->
					url = URI.parse(referer)
					conn
					|> Phoenix.Controller.redirect to: url.path
				nil ->
					conn
					|> Phoenix.Controller.redirect to: "/"
			end
		end

		  def handle_errors({:error, changeset}, conn, _func) do
			conn
			|> Phoenix.Controller.put_flash(:error, "Couldn't create identity")
			|> Phoenix.Controller.redirect to: html_identity_path(conn, :new)
		  end

		  def handle_errors({:ok, item}, _conn, func) do
			func.(item)
		  end
    end

  end

  def view do
    quote do
      use Phoenix.View, root: "web/templates"

      # Import convenience functions from controllers
      import Phoenix.Controller, only: [get_csrf_token: 0, get_flash: 2, view_module: 1]

      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      import Democracy.Router.Helpers
      import Democracy.ErrorHelpers
      import Democracy.Gettext
      
      import Democracy.NumberFormat, only: [number_format: 1, number_format_simple: 1]
    end
  end

  def router do
    quote do
      use Phoenix.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel

      alias Democracy.Repo
      import Ecto
      import Ecto.Query, only: [from: 1, from: 2]
      import Democracy.Gettext
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
