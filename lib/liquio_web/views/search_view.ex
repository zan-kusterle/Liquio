defmodule LiquioWeb.SearchView do
  use LiquioWeb, :view

  def render("index.json", %{nodes: nodes}) do
    %{data: render_many(nodes, LiquioWeb.SearchView, "node.json")}
  end

  def render("node.json", %{search: node}) do
    %{
      :title => node.title
    }
  end
end
