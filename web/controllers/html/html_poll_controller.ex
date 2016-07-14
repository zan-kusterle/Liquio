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

	def create(conn, %{"choice_type" => choice_type, "title" => title, "topics" => topics}) do
		title = title |> String.trim
		topics = topics |> String.split(",") |> Enum.map(&String.trim/1) |> Enum.filter(& String.length(&1) > 0)
		if choice_type == "from_topics" do
			choice_type =
				if Enum.member?(topics, "quantity") do
					topics = Enum.filter(topics, & &1 != "quantity")
					"quantity"
				else
					"probability"
				end
		end
		poll = Poll.create(choice_type, title, topics)
		
		conn
		|> put_flash(:info, "Done, share the url so others can vote")
		|> redirect to: html_poll_path(conn, :show, poll.id)
	end

	def show(conn, %{"id" => "random"}) do
		conn
		|> redirect to: html_poll_path(conn, :show, Poll.get_random().id)
	end

	def show(conn, %{"id" => id}) do
		poll = Repo.get(Poll, id)
		if poll do
			case TrustMetric.get(conn.params.trust_metric_url) do
				{:ok, trust_identity_ids} ->
					is_logged_in = Guardian.Plug.current_resource(conn) != nil
					references = Reference.for_poll(poll, conn.params.datetime, conn.params.vote_weight_halving_days, trust_identity_ids)
					results = Result.calculate(poll, conn.params.datetime, trust_identity_ids, conn.params.vote_weight_halving_days, 1)

					poll = poll
					|> Map.put(:results, results)
					|> Map.put(:title, Poll.title(poll))

					conn
					|> put_resp_header("Cache-Control", "no-cache, no-store, must-revalidate, max-age=0")
					|> render "show.html", title: poll.title, is_logged_in: is_logged_in, poll: poll, references: references
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
		case TrustMetric.get(conn.params.trust_metric_url) do
			{:ok, trust_identity_ids} ->
				contributions = Result.calculate_contributions(conn.params.poll, conn.params.datetime, trust_identity_ids)
				results = Result.calculate(conn.params.poll, conn.params.datetime, trust_identity_ids, conn.params.vote_weight_halving_days, 1)

				num_units = 30
				results_with_datetime = Enum.map(0..num_units, fn(shift_units) ->
					datetime = Timex.shift(conn.params.datetime, days: -shift_units)
					{
						num_units - shift_units,
						datetime,
						Result.calculate(conn.params.poll, datetime, trust_identity_ids, conn.params.vote_weight_halving_days, 1)
					}
				end)

				poll = conn.params.poll
				|> Map.put(:results, results)
				|> Map.put(:title, Poll.title(conn.params.poll))

				conn
				|> put_resp_header("Cache-Control", "no-cache, no-store, must-revalidate, max-age=0")
				|> render "details.html", title: poll.title, datetime_text: Map.get(params, "datetime", ""), poll: poll, contributions: contributions, results_with_datetime: results_with_datetime
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
				references = Reference.for_poll(conn.params.poll, datetime, nil, trust_identity_ids)
				results = Result.calculate(conn.params.poll, datetime, trust_identity_ids, nil, 1)

				poll = conn.params.poll
				|> Map.put(:results, results)
				|> Map.put(:title, Poll.title(conn.params.poll))

				conn
				|> render "embed.html", poll: poll, references: references
			{:error, message} ->
				conn
				|> put_status(:not_found)
				|> render(Democracy.ErrorView, "error.json", message: message)
		end
	end
end