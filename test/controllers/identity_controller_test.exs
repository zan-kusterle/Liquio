defmodule Democracy.IdentityControllerTest do
	use Democracy.ConnCase

	alias Democracy.Identity
	@valid_attrs %{username: "john", name: "John Doe"}
	@invalid_attrs %{username: "a", name: true}

	setup %{conn: conn} do
		{:ok, conn: put_req_header(conn, "accept", "application/json")}
	end

	test "lists all entries on index", %{conn: conn} do
		conn = get conn, identity_path(conn, :index)
		assert json_response(conn, 200)["data"] == []
	end

	test "shows chosen resource", %{conn: conn} do
		conn = post(conn, identity_path(conn, :create), identity: @valid_attrs)
		[location | _] = get_resp_header(conn, "location")
		conn = get conn, location
		assert Map.take(json_response(conn, 200)["data"], ["username", "name"]) == %{
			"username" => @valid_attrs.username,
			"name" => @valid_attrs.name
		}
	end

	test "does not show resource and instead throw error when id is nonexistent", %{conn: conn} do
		conn = get conn, identity_path(conn, :show, -1)
    	assert conn.status == 404
	end

	test "creates and renders resource when data is valid", %{conn: conn} do
		conn = post(conn, identity_path(conn, :create), identity: @valid_attrs)
		assert json_response(conn, 201)["data"]["username"]
		assert Repo.get_by(Identity, @valid_attrs)
	end

	test "does not create resource and renders errors when data is invalid", %{conn: conn} do
		conn = post conn, identity_path(conn, :create), identity: @invalid_attrs
		assert json_response(conn, 422)["errors"] != %{}
	end
end
