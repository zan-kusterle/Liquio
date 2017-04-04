defmodule Liquio.Repo do
	use Ecto.Repo, otp_app: :liquio

	def first(queryable) do
		queryable |> Liquio.Repo.all |> List.first
	end

	def last(queryable) do
		queryable |> Liquio.Repo.all |> List.last
	end
end
