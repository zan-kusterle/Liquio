defmodule Liquio.Results.CacheServer do
	def start_link() do
		Agent.start_link(fn -> Map.new end, name: __MODULE__)
	end

	def stop() do
		Agent.stop(__MODULE__)
	end

    def has_results?(poll_id) do
        Agent.get(__MODULE__, fn(map) ->
			Map.has_key?(map, poll_id)
		end)
    end

	def get_results(poll_id) do
		IO.inspect poll_id
		Agent.get(__MODULE__, fn(map) ->
			{results, created_at} = Map.get(map, poll_id)
            results
		end)
	end

	def put_results(poll_id, results) do
		Agent.update(__MODULE__, fn(map) ->
			Map.put(map, poll_id, {results, Timex.now})
		end)
	end

	def inspect() do
		Agent.get(__MODULE__, fn(map) ->
            map
		end)
	end
end