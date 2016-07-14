defmodule Democracy.HtmlVoteController do
	use Democracy.Web, :controller
	alias Democracy.Poll
	alias Democracy.Reference
	alias Democracy.Result
	alias Democracy.Vote

	plug Democracy.Plugs.Params, [
		{&Democracy.Plugs.CurrentUser.handle/2, :user, [require: false]},
		{&Democracy.Plugs.ItemParam.handle/2, :poll, [schema: Poll, name: "html_poll_id"]},
		{&Democracy.Plugs.DatetimeParam.handle/2, :datetime, [name: "datetime"]},
		{&Democracy.Plugs.VoteWeightHalvingDaysParam.handle/2, :vote_weight_halving_days, [name: "vote_weight_halving_days"]},
		{&Democracy.Plugs.TrustMetricIdsParam.handle/2, :trust_metric_ids, [name: "trust_metric_url"]}
	] when action in [:index]
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
	end

	plug Democracy.Plugs.Params, [
		{&Democracy.Plugs.CurrentUser.handle/2, :user, [require: false]},
		{&Democracy.Plugs.ItemParam.handle/2, :poll, [schema: Poll, name: "html_poll_id"]},
		{&Democracy.Plugs.NumberParam.handle/2, :score, [name: "score"]}
	] when action in [:index]
	def create(conn, %{:user => user, :poll => poll, :score => score}) do
		message =
			if score != nil do
				if poll.choice_type == "probability" and (score < 0 or score > 1) do
					"Choice must be between 0 and 1."
				else
					# TODO: Use changeset to verify above constraint
					Vote.set(poll, user, score)
					"Your vote is now live."
				end
			else
				Vote.delete(poll, user)
				"You no longer have a vote in this poll."
			end

		conn
		|> put_flash(:info, message)
		|> redirect to: html_poll_html_vote_path(conn, :index, poll.id)
	end
end