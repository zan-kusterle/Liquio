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
		{:ok, trust_metric_ids} = get(url)
		trust_metric_ids
	end

	def get(url) do
		trust_metric = Repo.get_by(TrustMetric, url: url)
		if trust_metric do
			cache_time = Application.get_env(:liquio, :trust_metric_cache_time_seconds)
			Task.async(fn ->
				if_before_datetime = Timex.DateTime.now
					|> Timex.to_erlang_datetime
					|> :calendar.datetime_to_gregorian_seconds
					|> Kernel.-(cache_time)
					|> :calendar.gregorian_seconds_to_datetime
					|> Timex.DateTime.from_erl
				if Timex.DateTime.compare(trust_metric.last_update, if_before_datetime) < 0 do
					response = HTTPotion.get(url, headers: ["If-Modified-Since": Timex.format!(trust_metric.last_update, "{ISO}")])
					if HTTPotion.Response.success?(response) do
						usernames = usernames_from_html response.body
						trust_metric = Ecto.Changeset.change trust_metric, usernames: usernames, last_update: Timex.DateTime.now()
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
						last_update: Timex.DateTime.now(),
						usernames: usernames
					})
				end)
				{:ok, usernames |> MapSet.new}
			else
				{:error, "Cannot fetch usernames from the given URL"}
			end
		end
	end

	defp usernames_from_html(html) do
		html
		|> Floki.find("a")
		|> Floki.attribute("href")
		|> Enum.map(fn(url) ->
			url |> String.replace("https://liqu.io/identities/", "")
		end)
		|> Enum.filter(& String.length(&1) < 255)
	end
end
