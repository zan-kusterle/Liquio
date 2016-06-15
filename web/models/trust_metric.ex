defmodule Democracy.TrustMetric do
	use Democracy.Web, :model

	alias Democracy.Repo
	alias Democracy.TrustMetric

	schema "trust_metrics" do
		field :url, :string
		field :last_update, Ecto.DateTime
		field :usernames, {:array, :string}
	end

	def default_trust_metric_url() do
		Application.get_env(:democracy, :default_trust_metric_url)
	end

	def get(url) do
		trust_metric = Repo.get_by(TrustMetric, url: url)
		if trust_metric do
			Task.async(fn ->
				if_before_datetime = Ecto.DateTime.utc
					|> Ecto.DateTime.to_erl
					|> :calendar.datetime_to_gregorian_seconds
					|> Kernel.-(60 * 5)
					|> :calendar.gregorian_seconds_to_datetime
					|> Ecto.DateTime.from_erl
				if trust_metric.last_update < if_before_datetime do
					response = HTTPotion.get(url, headers: ["If-Modified-Since": trust_metric.last_update |> Ecto.DateTime.to_iso8601])
					if response.status_code == 200 do
						usernames = response.body |> String.strip(?\n) |> String.split("\n")
						trust_metric = Ecto.Changeset.change trust_metric, usernames: usernames, last_update: Ecto.DateTime.utc()
						Repo.update!(trust_metric)
					end
				end
			end)
			{:ok, trust_metric.usernames |> MapSet.new}
		else
			response = HTTPotion.get url
			if HTTPotion.Response.success?(response) do
				usernames = response.body |> String.strip(?\n) |> String.split("\n")
				Task.async(fn ->
					Repo.insert!(%TrustMetric{
						url: url,
						last_update: Ecto.DateTime.utc(),
						usernames: usernames
					})
				end)
				{:ok, usernames |> MapSet.new}
			else
				{:error, "Cannot fetch usernames from the given URL"}
			end
		end
	end
end
