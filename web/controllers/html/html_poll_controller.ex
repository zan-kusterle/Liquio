defmodule Democracy.HtmlPollController do
	use Democracy.Web, :controller

	alias Democracy.Repo
	alias Democracy.Poll
	alias Democracy.Reference
	alias Democracy.TrustMetric
	alias Democracy.Result

	plug Democracy.Plugs.QueryId, {:poll, Poll, "html_poll_id"} when action in [:details, :embed]
	plug Democracy.Plugs.Datetime, {:datetime, "datetime"}
	plug Democracy.Plugs.TrustMetricUrl, {:trust_metric_url, "trust_metric_url"}
	plug Democracy.Plugs.VoteWeightHalvingDays, {:vote_weight_halving_days, "vote_weight_halving_days"}

	plug :put_layout, "minimal.html" when action in [:embed]
	
	def new(conn, _params) do
		conn
		|> render "new.html"
	end

	def show(conn, %{"id" => "random"}) do
		conn
		|> redirect to: html_poll_path(conn, :show, Poll.get_random().id)
	end

	def show(conn, %{"id" => id}) do
		poll = Repo.get(Poll, id)
		if poll do
			case TrustMetric.get(conn.assigns.trust_metric_url) do
				{:ok, trust_identity_ids} ->
					is_logged_in = Guardian.Plug.current_resource(conn) != nil
					references = Reference.for_poll(poll, conn.assigns.datetime, conn.assigns.vote_weight_halving_days, trust_identity_ids)
					results = Result.calculate(poll, conn.assigns.datetime, trust_identity_ids, conn.assigns.vote_weight_halving_days, 1)
					poll = poll |> Map.put(:results, results)
					conn
					|> render "show.html", is_logged_in: is_logged_in, poll: poll, references: references
				{:error, message} ->
					conn
					|> put_status(:not_found)
					|> render(Democracy.ErrorView, "error.json", message: message)
			end
		else
			conn
			|> put_status(:not_found)
			|> render("404.html")
		end
	end

	def details(conn, params) do
		case TrustMetric.get(conn.assigns.trust_metric_url) do
			{:ok, trust_identity_ids} ->
				contributions = Result.calculate_contributions(conn.assigns.poll, conn.assigns.datetime, trust_identity_ids)
				results = Result.calculate(conn.assigns.poll, conn.assigns.datetime, trust_identity_ids, conn.assigns.vote_weight_halving_days, 1)

				num_units = 30
				results_with_datetime = Enum.map(0..num_units, fn(shift_units) ->
					datetime = Timex.shift(conn.assigns.datetime, days: -shift_units)
					{
						num_units - shift_units,
						datetime,
						Result.calculate(conn.assigns.poll, datetime, trust_identity_ids, conn.assigns.vote_weight_halving_days, 1)
					}
				end)

				poll = conn.assigns.poll |> Map.put(:results, results)
				conn
				|> render "details.html", datetime_text: Map.get(params, "datetime", ""), poll: poll, contributions: contributions, results_with_datetime: results_with_datetime
			{:error, message} ->
				conn
				|> put_status(:not_found)
				|> render(Democracy.ErrorView, "error.json", message: message)
		end
	end

	def embed(conn, _params) do
		case TrustMetric.get(Democracy.TrustMetric.default_trust_metric_url) do
			{:ok, trust_identity_ids} ->
				datetime = Timex.DateTime.now
				references = Reference.for_poll(conn.assigns.poll, datetime, nil, trust_identity_ids)
				results = Result.calculate(conn.assigns.poll, datetime, trust_identity_ids, nil, 1)
				poll = conn.assigns.poll |> Map.put(:results, results)
				conn
				|> render "embed.html", poll: poll, references: references
			{:error, message} ->
				conn
				|> put_status(:not_found)
				|> render(Democracy.ErrorView, "error.json", message: message)
		end
	end
end