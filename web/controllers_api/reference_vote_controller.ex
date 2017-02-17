defmodule Liquio.ReferenceVoteController do
	use Liquio.Web, :controller
	
	plug :scrub_params, "choice" when action in [:create]
	with_params(%{
		:node => {Plugs.NodeParam, [name: "node_id"]},
		:reference_node => {Plugs.NodeParam, [name: "reference_id"]},
		:user => {Plugs.CurrentUser, [require: true]}
	},
	def create(conn, %{:node => node, :reference_node => reference_node, :user => user, "choice" => choice}) do
		calculation_opts = get_calculation_opts_from_conn(conn)
		reference = Node.for_reference_key(node, reference_node.key)

		#new_choice = if choice_name == "for_choice" do
		#	current_choice = current_choice
		#	|> Map.put("for_choice", choice["main"])
		#	if not Map.has_key?(current_choice, "relevance") do
		#		current_choice = current_choice
		#		|> Map.put("relevance", 1.0)
		#	else
		#		current_choice
		#	end
		#else
		#	current_choice = current_choice
		#	|> Map.put("relevance", choice["main"])
		#end

		{status, message} =
			if choice != nil do
				Vote.set(reference, user, choice)
				if MapSet.member?(calculation_opts.trust_metric_ids, to_string(user.id)) do
					{:info, "Your vote is now live."}
				else
					{:error, "Your vote is now live, but because you're not in trust metric it will not be counted. Get others to trust your identity by sharing it's URL to get into trust metric or change it in preferences."}
				end
			else
				Vote.delete(reference, user)
				{:info, "You no longer have a vote in this poll."}
			end

		calculation_opts = Map.put(calculation_opts, :datetime, Timex.now)
		conn
		|> put_status(:created)
		|> render(Liquio.NodeView, "show.json", node: Node.preload(reference, calculation_opts, user))
	end)

	with_params(%{
		:node => {Plugs.NodeParam, [name: "node_id"]},
		:reference_node => {Plugs.NodeParam, [name: "reference_id"]},
		:user => {Plugs.CurrentUser, [require: true]}
	},
	def delete(conn, %{:node => node, :reference_node => reference_node, :user => user}) do
		calculation_opts = get_calculation_opts_from_conn(conn)
		reference = Node.for_reference_key(node, reference_node.key)
		Vote.delete(reference, user)

		conn
		|> put_status(:created)
		|> render(Liquio.NodeView, "show.json", node: Node.preload(reference, calculation_opts, user))
	end)
end
