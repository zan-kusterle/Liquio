defmodule Liquio.Web.ErrorView do
	use Liquio.Web, :view

	def render("404.html", _assigns) do
		"Nothing is here"
	end

	def render("500.html", _assigns) do
		"Ooops, something went wrong"
	end

	def render("error.json", %{message: message}) do
		%{errors: [message]}
	end
	
	def template_not_found(_template, assigns) do
		render "500.html", assigns
	end
end
