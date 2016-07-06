defmodule Democracy.ReferenceControllerTest do
	use Democracy.ConnCase
	
	setup %{conn: conn} do
		{:ok, conn: put_req_header(conn, "accept", "application/json")}
	end

	test "shows chosen resource", %{conn: conn} do
		poll = create_poll(%{title: "A"})
		reference_poll = create_poll(%{title: "B"})
		reference = create_reference(poll, reference_poll, "positive")

		get conn, poll_reference_path(conn, :show, reference["poll"]["id"], reference["id"])
		assert reference["pole"] == "positive"
	end

	def create_poll(params) do
		conn = build_conn
		conn = post(conn, poll_path(conn, :create), poll: params)
		json_response(conn, 201)["data"]
	end

	def create_reference(poll, reference_poll, pole) do
		conn = build_conn
		conn = get(conn, poll_reference_path(conn, :show, poll["id"], reference_poll["id"], pole: pole))
		json_response(conn, 200)["data"]
	end
end
