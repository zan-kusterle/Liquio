defmodule Democracy.VoteControllerTest do
	use Democracy.ConnCase
	
	setup %{conn: conn} do
		{:ok, conn: put_req_header(conn, "accept", "application/json")}
	end

	test "lists all entries on index", %{conn: conn} do
		poll = create_poll(%{title: "Test", choice_type: "probability"})
		conn = get conn, poll_vote_path(conn, :index, poll["id"])
		assert json_response(conn, 200)["data"] == []
	end

	test "shows chosen resource", %{conn: conn} do
		vote = create_vote()
		conn = get conn, poll_vote_path(conn, :show, vote["poll"]["id"], vote["identity"]["id"])
		assert json_response(conn, 200)["data"] == vote
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

	def create_poll(params) do
		conn = build_conn
		conn = post(conn, poll_path(conn, :create), poll: params)
		json_response(conn, 201)["data"]
	end

	def create_vote() do
		poll = create_poll(%{title: "Test", choice_type: "quantity"})
		a = create_identity(%{username: "aaa", name: "AAA"})
		t = login(a["username"], a["password"])

		conn = build_conn
		conn = Plug.Conn.put_req_header(conn, "authorization", t)
		conn = post(conn, poll_vote_path(conn, :create, poll["id"]), vote: %{score: 1})
		json_response(conn, 201)["data"]
	end
end
