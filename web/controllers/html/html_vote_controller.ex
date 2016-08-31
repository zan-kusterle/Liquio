defmodule Liquio.HtmlVoteController do
	use Liquio.Web, :controller

	with_params(%{
		:user => {Plugs.CurrentUser, [require: true]},
		:poll => {Plugs.ItemParam, [schema: Poll, name: "html_poll_id"]},
	},
	def index(conn, %{:poll => poll, :user => user}) do
		calculation_opts = get_calculation_opts_from_conn(conn)
		own_vote = if poll.choice_type == "time_quantity" do
			[%{time: 2000, choice: 1}, %{time: 2001, choice: 2}]
		else
			Vote.current_by(poll, user)
		end
		conn
		|> put_resp_header("Cache-Control", "no-cache, no-store, must-revalidate, max-age=0")
		|> render("index.html",
			title: poll.title || "Liquio",
			poll: poll
				|> Map.put(:results, Result.calculate(poll, calculation_opts)),
			references:  Reference.for_poll(poll, calculation_opts),
			own_vote: own_vote,
			minimum_voting_power: calculation_opts.minimum_voting_power)
	end)

	with_params(%{
		:user => {Plugs.CurrentUser, [require: true]},
		:poll => {Plugs.ItemParam, [schema: Poll, name: "html_poll_id"]},
		:score => {Plugs.NumberParam, [name: "score", maybe: true]}
	},
	def create(conn, %{:user => user, :poll => poll, :score => score}) do
		calculation_opts = get_calculation_opts_from_conn(conn)

		{level, message} =
			if score != nil do
				if poll.choice_type == "probability" and (score < 0 or score > 1) do
					{:error, "Choice must be between 0 (0%) and 1 (100%)."}
				else
					Vote.set(poll, user, score)
					if MapSet.member?(calculation_opts.trust_metric_ids, to_string(user.id)) do
						{:info, "Your vote is now live. Share the poll with other people."}
					else
						{:error, "Your vote is now live. But because you're not in trust metric it will not be counted. Tell others to trust your identity by sharing it's URL to get in trust metric."}
					end
					
				end
			else
				Vote.delete(poll, user)
				{:info, "You no longer have a vote in this poll."}
			end

		conn
		|> put_flash(level, message)
		|> redirect(to: default_redirect(conn))
	end)
end