defmodule Liquio.Average do
  def mean(contributions) do
    total_power = Enum.sum(Enum.map(contributions, & &1.voting_power))

    total_power =
      if total_power > 0 do
        total_power
      else
        Enum.count(contributions)
      end

    total_score =
      Enum.sum(
        Enum.map(contributions, fn contribution ->
          contribution.choice * contribution.voting_power
        end)
      )

    if total_power == 0 do
      nil
    else
      1.0 * total_score / total_power
    end
  end

  def median(contributions) do
    contributions = contributions |> Enum.sort(&(&1.choice > &2.choice))
    total_power = Enum.sum(Enum.map(contributions, & &1.voting_power))

    total_power =
      if total_power > 0 do
        total_power
      else
        Enum.count(contributions)
      end

    if total_power == 0 do
      nil
    else
      Enum.reduce_while(contributions, 0.0, fn contribution, current_power ->
        if current_power + contribution.voting_power > total_power / 2 do
          {:halt, 1.0 * contribution.choice}
        else
          {:cont, current_power + contribution.voting_power}
        end
      end)
    end
  end

  def mode(list) do
    gb = Enum.group_by(list, & &1)
    max_count = gb |> Enum.map(fn {_, val} -> length(val) end) |> Enum.max()
    max_items = for {key, val} <- gb, length(val) == max_count, do: key
    Enum.at(max_items, 0)
  end
end
