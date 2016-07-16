defmodule Democracy.HtmlVoteController do
	use Democracy.Web, :controller

	with_params(%{
		:user => {Plugs.CurrentUser, [require: false]},
		:poll => {Plugs.ItemParam, [schema: Poll, name: "html_poll_id"]},
		:datetime => {Plugs.DatetimeParam, [name: "datetime"]},
		:vote_weight_halving_days => {Plugs.IntegerParam, [name: "vote_weight_halving_days"]},
		:trust_metric_ids => {Plugs.TrustMetricIdsParam, [name: "trust_metric_url"]}
	},
	def index(conn, %{:poll => poll, :user => user, :datetime => datetime, :vote_weight_halving_days => vote_weight_halving_days, :trust_metric_ids => trust_metric_ids}) do
		conn
		|> put_resp_header("Cache-Control", "no-cache, no-store, must-revalidate, max-age=0")
		|> render "index.html",
			title: poll.title || "Liquio",
			poll: poll
				|> Poll.preload
				|> Map.put(:results, Result.calculate(poll, datetime, trust_metric_ids, vote_weight_halving_days, 1)),
			references:  Reference.for_poll(poll, datetime, vote_weight_halving_days, trust_metric_ids),
			own_vote: Vote.current_by(poll, user)
	end)

	with_params(%{
		:user => {Plugs.CurrentUser, [require: false]},
		:poll => {Plugs.ItemParam, [schema: Poll, name: "html_poll_id"]},
		:score => {Plugs.NumberParam, [name: "score", maybe: true]}
	},
	def create(conn, %{:user => user, :poll => poll, :score => score}) do
		message =
			# TODO: Use changeset to verify this constraint
			if score != nil do
				if poll.choice_type == "probability" and (score < 0 or score > 1) do
					"Choice must be between 0 and 1."
				else
					Vote.set(poll, user, score)
					"Your vote is now live."
				end
			else
				Vote.delete(poll, user)
				"You no longer have a vote in this poll."
			end

		conn
		|> put_flash(:info, message)
		|> redirect to: default_redirect(conn)
	end)
end