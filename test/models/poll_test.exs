defmodule Democracy.PollTest do
  use Democracy.ModelCase

  alias Democracy.Poll

  @valid_attrs %{app_id: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Poll.changeset(%Poll{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Poll.changeset(%Poll{}, @invalid_attrs)
    refute changeset.valid?
  end
end
