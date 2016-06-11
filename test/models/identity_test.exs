defmodule Democracy.IdentityTest do
	use Democracy.ModelCase

	alias Democracy.Identity

	@valid_attrs %{username: "john", name: "John Doe"}
	@invalid_attrs %{}

	test "changeset with valid attributes" do
		changeset = Identity.changeset(%Identity{}, @valid_attrs)
		assert changeset.valid?
	end

	test "changeset with invalid attributes" do
		changeset = Identity.changeset(%Identity{}, @invalid_attrs)
		refute changeset.valid?
	end
end
