defmodule Liquio.ResultsCache do
	def get({{name, id, datetime}, preferences_key}) do
		cache = Cachex.get!(:results_cache, {name, id, datetime_key(datetime)})
		if cache != nil do
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

	def unset({name, path, datetime}) do
		1..Enum.count(path)
		|> Enum.map(& Enum.slice(path, 0, &1))
		|> Enum.each(fn(subpath) ->
			Cachex.set(:results_cache, {name, subpath, datetime_key(datetime)}, nil)
		end)
	end

	defp datetime_key(datetime) do
		Float.floor(Timex.to_unix(datetime) / Application.get_env(:liquio, :results_cache_seconds))
	end
end