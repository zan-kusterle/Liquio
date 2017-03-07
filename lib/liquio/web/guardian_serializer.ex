defmodule Liquio.GuardianSerializer do
	@behaviour Guardian.Serializer

	alias Liquio.Repo
	alias Liquio.Identity

	def for_token(identity = %Identity{}), do: {:ok, "Identity:#{identity.username}"}
	def for_token(_), do: {:error, "Unknown resource type"}

	def from_token("Identity:" <> id), do: {:ok, Repo.get_by(Identity, username: id)}
	def from_token(_), do: {:error, "Unknown resource type"}
end
