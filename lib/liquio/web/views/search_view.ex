defmodule Liquio.Web.SearchView do
	use Liquio.Web, :view

	def render("index.json", %{nodes: nodes}) do
		%{data: render_many(nodes, Liquio.Web.SearchView, "node.json")}
	end

	def render("node.json", %{search: node}) do
		%{
			:title => node.title
		}
	end
end