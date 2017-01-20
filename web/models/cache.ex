defmodule Liquio.ResultsCache do
	def get({{name, id, datetime}, preferences_key}) do
		cache = Cachex.get!(:results_cache, {name, id, datetime_key(datetime)})
		cache = nil
		if Mix.env == :prod and cache != nil do
			Map.get(cache, preferences_key)
		else
			nil
		end
	end

	def set({{name, id, datetime}, preferences_key}, value) do
		Cachex.get_and_update(:results_cache, {name, id, datetime_key(datetime)}, fn
			(nil) -> Map.new |> Map.put(preferences_key, value)
			(cache) -> Map.put(cache, preferences_key, value)
		end, ttl: :timer.seconds(Application.get_env(:liquio, :results_cache_seconds)))
		value
	end

	def unset({name, id}) do
		unset({name, id, Timex.now})
	end

	def unset({name, id, datetime}) do
		Cachex.set(:results_cache, {name, id, datetime_key(datetime)}, nil)
	end

	defp datetime_key(datetime) do
		Float.floor(Timex.to_unix(datetime) / Application.get_env(:liquio, :results_cache_seconds))
	end
end