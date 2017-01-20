defmodule Liquio.HtmlReferenceController do
	use Liquio.Web, :controller

	def index(conn, %{"html_poll_id" => poll_id, "reference_poll_id" => reference_poll_url}) do
		url = URI.parse(reference_poll_url)
		reference_poll_id =
			if url.path != nil and url.path |> String.starts_with?("/polls/") do
				String.replace(url.path, "/polls/", "")
			else
				reference_poll_url
			end
		reference_poll = Repo.get(Poll, reference_poll_id)

		if reference_poll != nil and reference_poll.kind == "custom" do
			conn
			|> redirect(to: html_poll_html_reference_path(conn, :show, poll_id, reference_poll_id))
		else
			conn
			|> put_flash(:info, "The poll you want to reference does not exist.")
			|> redirect(to: html_poll_path(conn, :show, poll_id))
		end
	end

	with_params(%{
		:user => {Plugs.CurrentUser, [require: false]},
		:nodes => {Plugs.NodesParam, [name: "html_poll_id"]},
		:reference_nodes => {Plugs.NodesParam, [name: "id"]},
		:datetime => {Plugs.DatetimeParam, [name: "datetime"]}
	},
	def show(conn, params = %{:user => user, :nodes => nodes, :reference_nodes => reference_nodes}) do
		node_unique_choice_types = nodes |> Enum.map(& &1.choice_type) |> Enum.uniq
		reference_node_unique_choice_types = reference_nodes |> Enum.map(& &1.choice_type) |> Enum.uniq
		if Enum.count(node_unique_choice_types) > 1 or Enum.count(reference_node_unique_choice_types) > 1 do
			conn
			|> put_flash(:info, "All nodes must be of same type.")
			|> redirect(to: html_poll_html_reference_path(conn, :show, params["html_poll_id"], params["id"]))
		else
			calculation_opts = get_calculation_opts_from_conn(conn)
			for_choice_nodes = nodes |> Enum.flat_map(fn(node) ->
				reference_nodes |> Enum.map(fn(reference_node) ->
					Node.for_reference_key(node, reference_node.key)
					|> Node.preload(calculation_opts, user)
				end)
			end)

			first_node = Enum.at(for_choice_nodes, 0)
			for_choice_node = if first_node.choice_type == nil do nil else first_node |> Map.put(:title, "Choice For Which Reference Poll Provides Evidence") |> Node.update_key() end
			relevance_node =  first_node |> Map.put(:title, "Relevance Score For This Reference") |> Map.put(:choice_type, "probability") |> Node.update_key()
			
			conn
			|> put_resp_header("Cache-Control", "no-cache, no-store, must-revalidate, max-age=0")
			|> render("show.html",
				title: "Decide references",
				conn: conn,
				calculation_opts: calculation_opts,
				nodes: Enum.map(nodes, & Node.preload(&1, calculation_opts, user)),
				reference_nodes: Enum.map(reference_nodes, & Node.preload(&1, calculation_opts, user)),
				for_choice_node: for_choice_node,
				relevance_node: relevance_node)
		end
	end)
end
