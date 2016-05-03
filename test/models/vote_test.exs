defmodule Democracy.VoteTest do
  use Democracy.ModelCase

  alias Democracy.Vote

  @valid_attrs %{choice: "some content", max_power: "120.5", weight: "120.5"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Vote.changeset(%Vote{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Vote.changeset(%Vote{}, @invalid_attrs)
    refute changeset.valid?
  end
end
