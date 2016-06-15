defmodule Democracy.TrustMetric do
	use Democracy.Web, :model

	alias Democracy.Repo
	alias Democracy.TrustMetric

	schema "trust_metrics" do
		field :url, :string
		field :last_update, Ecto.DateTime
		field :usernames, {:array, :string}
	end

	def get() do
		get(Application.get_env(:democracy, :default_trust_metric_url))
	end

	def get(url) do
		trust_metric = Repo.get_by(TrustMetric, url: url)
		if trust_metric do
			Task.async(fn ->
				if trust_metric.last_update < Ecto.DateTime.utc() do
					response = HTTPotion.get(url, headers: ["If-Modified-Since": trust_metric.last_update |> Ecto.DateTime.to_iso8601])
					if response.status_code == 200 do
						usernames = response.body |> String.split("\n")
						trust_metric = Ecto.Changeset.change trust_metric, usernames: usernames, last_update: Ecto.DateTime.utc()
						Repo.update!(trust_metric)
					end
				end
			end)
			{:ok, trust_metric.usernames |> MapSet.new}
		else
			response = HTTPotion.get url
			if HTTPotion.Response.success?(response) do
				usernames = response.body |> String.split("\n")
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
