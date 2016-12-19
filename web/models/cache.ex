defmodule Liquio.ResultsCache do
	def get({key, preferences_key}) do
		cache = Cachex.get!(:results_cache, key)
		if cache do
			Map.get(cache, preferences_key)
		else
			nil
		end
	end

	def set({key, preferences_key}, value) do
		Cachex.get_and_update(:results_cache, key, fn
			(nil) -> Map.new |> Map.put(preferences_key, value)
			(cache) -> Map.put(cache, preferences_key, value)
		end, ttl: :timer.seconds(10 * Application.get_env(:liquio, :results_cache_seconds)))
		value
	end
end