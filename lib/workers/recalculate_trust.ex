defmodule Democracy.RecalculateTrust do
    use GenServer

    alias Democracy.Repo
    alias Democracy.User
    alias Democracy.Delegation

    import Ecto.Query, only: [from: 2]

    @interval 30

    def start_link do
        GenServer.start_link(__MODULE__, %{})
    end

    def init(state) do
        handle_info(:work, state)
        {:ok, state}
    end

    def handle_info(:work, state) do
        recalculate_trust()

        # Start the timer again
        Process.send_after(self(), :work, @interval * 1000)

        {:noreply, state}
    end

    def recalculate_trust() do
        IO.puts "Recalculating trust"

        users = Repo.all(User) |> Repo.preload([:delegations_from])

        trusts_by_users = Enum.reduce(users, %{}, fn(user, trusts_by_users) ->
            Map.put(trusts_by_users, user.id, Enum.map(user.delegations_from, fn(delegation) ->
                delegation.to_user_id
            end))
        end)

        trusts = calculate_trusts(trusts_by_users)

        Enum.each(users, fn(user) ->
            if not user.is_trusted and trusts[user.id] >= 1 do
                case Repo.update(Ecto.Changeset.change(user, %{:is_trusted => true, :voting_power => 1})) do
                    {:error, changeset} ->
                        raise "Error when granting trust to user #{user.id}"
                    {:ok, user} ->
                        false
                end
            end
        end)

        users = Repo.all(
            from u in User,
            where: u.is_trusted == true,
            select: u
        ) |> Repo.preload([:delegations_from])
        users_with_delegations_by_ids = Enum.reduce(users, %{}, fn(user, delegations_by_users) ->
            Map.put(delegations_by_users, user.id, user)
        end)

        new_voting_power_by_ids = calculate_voting_power(users_with_delegations_by_ids)

        Enum.each(users, fn(user) ->
            new_voting_power = new_voting_power_by_ids[user.id]
            if abs(user.voting_power - new_voting_power) >= 0.01 do
                case Repo.update(Ecto.Changeset.change(user, %{:voting_power => 1})) do
                    {:error, changeset} ->
                        raise "Error when updating voting power for user #{user.id}"
                    {:ok, user} ->
                        false
                end
            end
        end)

        IO.puts "Done recalculating trust"
    end

    def calculate_trusts(trusts_by_users) do
        d = 0.85

        num_users = Enum.count(trusts_by_users)

        inverse_trusts_by_users = Enum.reduce(Map.keys(trusts_by_users), %{}, fn(user_id, inverse_trusts_by_users) ->
            inverse_trusts_by_users |> Map.put(user_id, [])
        end)
        inverse_trusts_by_users = Enum.reduce(Map.keys(trusts_by_users), inverse_trusts_by_users, fn(user_id, inverse_trusts_by_users) ->
            Enum.reduce(trusts_by_users[user_id], inverse_trusts_by_users, fn(trust_user_id, inverse_trusts_by_users) ->
                new_value = [user_id | inverse_trusts_by_users[trust_user_id]]
                inverse_trusts_by_users |> Map.put(trust_user_id, new_value)
            end)
        end)

        trusts = Enum.reduce(Map.keys(trusts_by_users), %{}, fn(user_id, acc) ->
            Map.put(acc, user_id, 1 / num_users)
        end)

        trusts = Enum.reduce(0..10, trusts, fn(_, trusts) ->
            Enum.reduce(Map.keys(trusts_by_users), trusts, fn(user_id, trusts) ->
                trust_sum = Enum.reduce(inverse_trusts_by_users[user_id], 0, fn(trusting_user_id, trust_sum) ->
                    num_trusts_for_trusting_user = Enum.count(trusts_by_users[trusting_user_id])
                    trust_sum + trusts[trusting_user_id] / num_trusts_for_trusting_user
                end)
                trusts |> Map.put(user_id, (1 - d) / num_users + d * trust_sum)
            end)
        end)

        total_trust = Enum.sum(Map.values(trusts))
        trusts = Enum.reduce(Map.keys(trusts), trusts, fn(user_id, trusts) ->
            trusts |> Map.put(user_id, trusts[user_id] / total_trust * num_users)
        end)

        trusts
    end

    def calculate_voting_power(users_with_delegations_by_ids) do
        initial_voting_power = Enum.reduce(Map.values(users_with_delegations_by_ids), %{}, fn(user, acc) ->
            acc |> Map.put(user.id, user.voting_power)
        end)

        Enum.reduce(0..10, initial_voting_power, fn(_, new_voting_power) ->
            calculate_voting_power_iteration(users_with_delegations_by_ids, new_voting_power)
        end)
    end

    def calculate_voting_power_iteration(users_with_delegations_by_ids, current_voting_power_by_ids) do
        Enum.each(Map.values(users_with_delegations_by_ids), fn(user) ->
            total_voting_power = current_voting_power_by_ids[user.id]
            total_weight = 1 + Enum.reduce(user.delegations_from, 0, fn(delegation, acc) ->
                acc + delegation.weight
            end)

            user_ratio = 1 / total_weight
            current_voting_power_by_ids = current_voting_power_by_ids |> Map.update(user.id, 0, fn v ->
                v + total_voting_power * user_ratio
            end)

            Enum.each(user.delegations_from, fn(delegation) ->
                delegation_ratio = delegation.weight / total_weight
                current_voting_power_by_ids = current_voting_power_by_ids |> Map.update(delegation.to_user_id, 0, fn v ->
                    v + total_voting_power * delegation_ratio
                end)
            end)
        end)
        current_voting_power_by_ids
    end
end
