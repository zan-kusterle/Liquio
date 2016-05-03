defmodule Democracy.DelegationControllerTest do
  use Democracy.ConnCase

  alias Democracy.Delegation
  @valid_attrs %{from_user_id: "some content", to_user_id: "some content", weight: "120.5"}
  @invalid_attrs %{}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, user_delegation_path(conn, :index, %{:user_id=>1})
    assert json_response(conn, 200)["data"] == []
  end

  test "shows chosen resource", %{conn: conn} do
    delegation = Repo.insert! %Delegation{}
    conn = get conn, user_delegation_path(conn, :show, delegation)
    assert json_response(conn, 200)["data"] == %{"id" => delegation.id,
      "from_user_id" => delegation.from_user_id,
      "to_user_id" => delegation.to_user_id,
      "weight" => delegation.weight}
  end

  test "does not show resource and instead throw error when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, user_delegation_path(conn, :show, -1)
    end
  end

  test "creates and renders resource when data is valid", %{conn: conn} do
    conn = post conn, user_delegation_path(conn, :create, %{:user_id=>1}), delegation: @valid_attrs
    assert json_response(conn, 201)["data"]["id"]
    assert Repo.get_by(Delegation, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, user_delegation_path(conn, :create, %{:user_id=>1}), delegation: @invalid_attrs
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "updates and renders chosen resource when data is valid", %{conn: conn} do
    delegation = Repo.insert! %Delegation{}
    conn = put conn, user_delegation_path(conn, :update, delegation), delegation: @valid_attrs
    assert json_response(conn, 200)["data"]["id"]
    assert Repo.get_by(Delegation, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    delegation = Repo.insert! %Delegation{}
    conn = put conn, user_delegation_path(conn, :update, delegation), delegation: @invalid_attrs
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "deletes chosen resource", %{conn: conn} do
    delegation = Repo.insert! %Delegation{}
    conn = delete conn, user_delegation_path(conn, :delete, delegation)
    assert response(conn, 204)
    refute Repo.get(Delegation, delegation.id)
  end
end
