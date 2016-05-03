defmodule Democracy.GuardianSerializer do
  @behaviour Guardian.Serializer

  alias Democracy.Repo
  alias Democracy.User

  def for_token(user = %User{}), do: { :ok, "User:#{user.username}" }
  def for_token(_), do: { :error, "Unknown resource type" }

  def from_token("User:" <> id), do: { :ok, Repo.get_by(User, username: id) }
  def from_token(_), do: { :error, "Unknown resource type" }
end
