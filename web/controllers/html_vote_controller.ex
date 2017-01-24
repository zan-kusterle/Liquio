defmodule Liquio.HtmlVoteController do
	use Liquio.Web, :controller

	with_params(%{
		:user => {Plugs.CurrentUser, [require: true]},
		:node => {Plugs.NodeParam, [name: "html_node_id"]},
		:choice => {Plugs.ChoiceParam, [name: "choice", maybe: true]}
	},
	def create(conn, %{:user => user, :node => node, :choice => choice}) do
		calculation_opts = get_calculation_opts_from_conn(conn)

		{level, message} =
			if choice != nil do
				Vote.set(node, user, choice)
				if MapSet.member?(calculation_opts.trust_metric_ids, to_string(user.id)) do
					{:info, "Your vote is now live."}
				else
					{:error, "Your vote is now live, but because you're not in trust metric it will not be counted. Get others to trust your identity by sharing it's URL to get into trust metric or change it in preferences."}
				end
			else
				Vote.delete(node, user)
				{:info, "You no longer have a vote in this poll."}
			end

		conn
		|> put_flash(level, message)
		|> redirect(to: Liquio.Controllers.Helpers.default_redirect(conn))
	end)
end