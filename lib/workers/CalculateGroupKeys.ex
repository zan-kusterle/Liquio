defmodule Democracy.CalculateGroupKeys do
    use GenServer

    alias Democracy.Poll

    @interval 30

    def start_link do
        GenServer.start_link(__MODULE__, %{})
    end

    def init(state) do
        handle_info(:work, state)
        {:ok, state}
    end

    def handle_info(:work, state) do
        calculate()
        Process.send_after(self(), :work, @interval * 1000)
        {:noreply, state}
    end

    def calculate() do
        """
        polls = Repo.all(Poll)
        |> Repo.preload([:group_key_polls])
        |> Enum.map(fn(poll) ->
            results = Enum.map(poll.group_key_polls, fn(group_key_poll) ->
                result = Result.calculate(group_key_poll, Ecto.DateTime.now, default_trust_ids, nil)
                Map.put(result, :group_key, group_key_poll.group_key)
            end)

            chosen_result = results |> Enum.filter(fn(result) ->
                result.total > 1000 and result.count > 10
            end)
            |> Enum.sort_by(fn(result) ->
                -result.mean
            end)
            |> Enum.at(0)

            poll.group_key = chosen_result.group_key
        end)
        Repo.update_all(polls)
        """
    end
end
