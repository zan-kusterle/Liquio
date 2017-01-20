defmodule Liquio.HtmlReferenceVoteController do
	use Liquio.Web, :controller

	with_params(%{
		:user => {Plugs.CurrentUser, [require: true]},
		:nodes => {Plugs.NodesParam, [name: "html_poll_id"]},
		:reference_nodes => {Plugs.NodesParam, [name: "html_reference_id"]},
		:choice => {Plugs.ChoiceParam, [name: "choice", maybe: true]},
		:choice_name => {Plugs.StringParam, [name: "name"]}
	},
	def create(conn, params = %{:user => user, :nodes => nodes, :reference_nodes => reference_nodes, :choice => choice, :choice_name => choice_name}) do
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
			
			{level, message} = if choice != nil do
				main_choice =
					if choice_name == "for_choice" do
						if choice["main"] != nil do
							%{:for_choice => choice["main"], :main => 1.0}
						else
							%{:main => 1.0}
						end
					else
						choice
					end
				Enum.map(for_choice_nodes, & Vote.set(&1, user, main_choice))
				if MapSet.member?(calculation_opts.trust_metric_ids, to_string(user.id)) do
					{:info, "Your vote is now live. Share the poll with other people."}
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