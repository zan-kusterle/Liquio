defmodule Democracy.VoteControllerTest do
	use Democracy.ConnCase
	
	setup %{conn: conn} do
		{:ok, conn: put_req_header(conn, "accept", "application/json")}
	end

	def create_identity(params) do
		conn = post(conn, identity_path(conn, :create), identity: params)
		json_response(conn, 201)["data"]
	end

	def login(username, password) do
		conn = post(conn, login_path(conn, :create), identity: %{username: username, password: password})
		json_response(conn, 200)["data"]["access_token"]
	end

	def create_poll() do

	end

	def create_vote() do
		
	end
end
