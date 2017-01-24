defmodule Liquio.HtmlReferenceVoteController do
	use Liquio.Web, :controller

	with_params(%{
		:user => {Plugs.CurrentUser, [require: true]},
		:nodes => {Plugs.NodesParam, [name: "html_node_id"]},
		:reference_nodes => {Plugs.NodesParam, [name: "html_reference_id"]},
		:choice => {Plugs.ChoiceParam, [name: "choice", maybe: true]},
		:choice_name => {Plugs.StringParam, [name: "choice_name"]}
	},
	def create(conn, params = %{:user => user, :nodes => nodes, :reference_nodes => reference_nodes, :choice => choice, :choice_name => choice_name}) do
		node_unique_choice_types = nodes |> Enum.map(& &1.choice_type) |> Enum.uniq
		reference_node_unique_choice_types = reference_nodes |> Enum.map(& &1.choice_type) |> Enum.uniq
		if Enum.count(node_unique_choice_types) > 1 or Enum.count(reference_node_unique_choice_types) > 1 do
			conn
			|> put_flash(:info, "All nodes must be of same type.")
			|> redirect(to: html_node_html_reference_path(conn, :show, params["html_node_id"], params["id"]))
		else
			calculation_opts = get_calculation_opts_from_conn(conn)
			for_choice_nodes = nodes |> Enum.flat_map(fn(node) ->
				reference_nodes |> Enum.map(fn(reference_node) ->
					Node.for_reference_key(node, reference_node.key)
					|> Node.preload(calculation_opts, user)
				end)
			end)
			first_node = Enum.at(for_choice_nodes, 0) |> Node.preload(calculation_opts, user)
			
			{level, message} = if choice != nil do
				current_choice = if vote = Vote.current_by(first_node, user) do vote.data.choice else %{} end
				new_choice = if choice_name == "for_choice" do
					current_choice = current_choice
					|> Map.put("for_choice", choice["main"])
					if not Map.has_key?(current_choice, "relevance") do
						current_choice = current_choice
						|> Map.put("relevance", 1.0)
					else
						current_choice
					end
				else
					current_choice = current_choice
					|> Map.put("relevance", choice["main"])
				end
				Enum.map(for_choice_nodes, & Vote.set(&1, user, new_choice))

				if MapSet.member?(calculation_opts.trust_metric_ids, to_string(user.id)) do
					{:info, "Your vote is now live."}
				else
					{:error, "Your vote is now live, but because you're not in trust metric it will not be counted. Get others to trust your identity by sharing it's URL to get into trust metric or change it in preferences."}
				end
			else
				Enum.map(for_choice_nodes, & Vote.delete(&1, user))
				{:info, "You no longer have a vote in this poll."}
			end

			conn
			|> put_flash(level, message)
			|> redirect(to: Liquio.Controllers.Helpers.default_redirect(conn))
		end
	end)
end