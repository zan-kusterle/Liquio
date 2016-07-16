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
			use Timex.Ecto.Timestamps, usec: true

			import Ecto
			import Ecto.Changeset
			import Ecto.Query, only: [from: 1, from: 2]
		end
	end

	def controller do
		quote do
			use Phoenix.Controller

			import Ecto
			import Ecto.Query, only: [from: 1, from: 2]

			import Democracy.Router.Helpers
			import Democracy.Gettext
			import Democracy.Plugs.Params, only: [with_params: 2]

			alias Democracy.Repo
			alias Democracy.Plugs
			alias Democracy.Identity
			alias Democracy.Delegation
			alias Democracy.Vote
			alias Democracy.Poll
			alias Democracy.Reference
			alias Democracy.Result

			import Democracy.Controllers.Helpers
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

			import Ecto
			import Ecto.Query, only: [from: 1, from: 2]
			import Democracy.Gettext

			alias Democracy.Repo
		end
	end

	@doc """
	When used, dispatch to the appropriate controller/view/etc.
	"""
	defmacro __using__(which) when is_atom(which) do
		apply(__MODULE__, which, [])
	end
end
