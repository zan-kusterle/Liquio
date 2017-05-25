defmodule Liquio.TrustMetric do
	use Liquio.Web, :model

	alias Liquio.Repo
	alias Liquio.TrustMetric

	schema "trust_metrics" do
		field :url, :string
		field :last_update, Timex.Ecto.DateTime
		field :usernames, {:array, :string}
	end

	def default_trust_metric_url() do
		Application.get_env(:liquio, :default_trust_metric_url)
	end

	def get!(url) do
		case get(url) do
			{:ok, usernames} -> usernames
			_ -> MapSet.new
		end
	end

	def get(url) do
		trust_metric = Repo.get_by(TrustMetric, url: url)
		if trust_metric do
			Task.async(fn ->
				if_before_datetime = Timex.shift(Timex.now, seconds: -Application.get_env(:liquio, :trust_metric_cache_time_seconds))
				if Timex.before?(trust_metric.last_update, if_before_datetime) do
					response = HTTPotion.get(url, headers: ["If-Modified-Since": Timex.format!(trust_metric.last_update, "{ISO:Extended:Z}")])
					if HTTPotion.Response.success?(response) do
						usernames = usernames_from_html response.body
						trust_metric = Ecto.Changeset.change trust_metric, usernames: usernames, last_update: Timex.now
						Repo.update!(trust_metric)
					end
				end
			end)
			{:ok, trust_metric.usernames |> MapSet.new}
		else
			response = HTTPotion.get url
			if HTTPotion.Response.success?(response) do
				usernames = usernames_from_html response.body
				Task.async(fn ->
					Repo.insert!(%TrustMetric{
						url: url,
						last_update: Timex.now,
						usernames: usernames
					})
				end)
				{:ok, usernames |> MapSet.new}
			else
				{:error, "Can't fetch usernames from the given URL"}
			end
		end
	end

	defp usernames_from_html(html) do
		html
		|> Floki.find(".identity")
		|> Floki.attribute("username")
	end
end
