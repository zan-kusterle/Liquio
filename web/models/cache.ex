defmodule Liquio.ResultsCache do
	def get({{name, id, datetime}, preferences_key}) do
		key = {name, id, Float.floor(Timex.to_unix(datetime) / Application.get_env(:liquio, :results_cache_seconds))}
		cache = Cachex.get!(:results_cache, key)
		if cache do
			Map.get(cache, preferences_key)
		else
			nil
		end
	end

	def set({{name, id, datetime}, preferences_key}, value) do
		key = {name, id, Float.floor(Timex.to_unix(datetime) / Application.get_env(:liquio, :results_cache_seconds))}
		Cachex.get_and_update(:results_cache, key, fn
			(nil) -> Map.new |> Map.put(preferences_key, value)
			(cache) -> Map.put(cache, preferences_key, value)
		end, ttl: :timer.seconds(10 * Application.get_env(:liquio, :results_cache_seconds)))
		value
	end

	def unset({name, id}) do
		key = {name, id, Float.floor(Timex.to_unix(Timex.now) / Application.get_env(:liquio, :results_cache_seconds))}
		Cachex.set(:results_cache, key, nil)
	end
end