defmodule Democracy.DelegationControllerTest do
	use Democracy.ConnCase
	
	setup %{conn: conn} do
		{:ok, conn: put_req_header(conn, "accept", "application/json")}
	end

	test "lists all entries on index", %{conn: conn} do
		a = create_identity(%{username: "aaa", name: "AAA"})
		conn = get conn, identity_delegation_path(conn, :index, a["id"])
		assert json_response(conn, 200)["data"] == []
	end

	test "shows chosen resource", %{conn: conn} do
		delegation = create_delegation()
		conn = get conn, identity_delegation_path(conn, :show, delegation["from_identity"]["id"], delegation["to_identity"]["id"])
		assert json_response(conn, 200)["data"] == delegation
	end

	def create_identity(params) do
		conn = build_conn
		conn = post(conn, identity_path(conn, :create), identity: params)
		json_response(conn, 201)["data"]
	end

	def login(username, password) do
		conn = build_conn
		conn = post(conn, login_path(conn, :create), identity: %{username: username, password: password})
		json_response(conn, 200)["data"]["access_token"]
	end

	def create_delegation() do
		conn = build_conn
		a = create_identity(%{username: "aaa", name: "AAA"})
		b = create_identity(%{username: "bbb", name: "BBB"})
		t = login(a["username"], a["password"])
		conn = Plug.Conn.put_req_header(conn, "authorization", t)
		conn = post(conn, identity_delegation_path(conn, :create, "me"), delegation: %{to_identity_id: b["id"], weight: 1, topics: ["X", "Y"]})
		json_response(conn, 201)["data"]
	end
end
