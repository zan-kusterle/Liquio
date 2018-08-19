defmodule LiquioWeb.NodeView do
  use LiquioWeb, :view

  def render("index.json", %{nodes: nodes}) do
    %{data: render_many(nodes, LiquioWeb.NodeView, "node.json")}
  end

  def render("show.json", %{node: node}) do
    %{data: render_one(node, LiquioWeb.NodeView, "node.json")}
  end

  def render("node.json", %{node: node}) do
    node
  end
end
