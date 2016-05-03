defmodule Democracy.DelegationTest do
  use Democracy.ModelCase

  alias Democracy.Delegation

  @valid_attrs %{from_user_id: "some content", to_user_id: "some content", weight: "120.5"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Delegation.changeset(%Delegation{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Delegation.changeset(%Delegation{}, @invalid_attrs)
    refute changeset.valid?
  end
end
