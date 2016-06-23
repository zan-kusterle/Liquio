defmodule Democracy.ReferenceControllerTest do
	use Democracy.ConnCase
	
	setup %{conn: conn} do
		{:ok, conn: put_req_header(conn, "accept", "application/json")}
	end

	test "shows chosen resource", %{conn: conn} do
		reference = create_reference()
		conn = get conn, poll_reference_path(conn, :show, reference["poll"]["id"], reference["id"])
		assert json_response(conn, 200)["data"] == reference
	end

	def create_poll(params) do
		conn = post(conn, poll_path(conn, :create), poll: params)
		json_response(conn, 201)["data"]
	end

	def create_reference() do
		poll = create_poll(%{title: "A"})
		reference_poll = create_poll(%{title: "B"})
		conn = post(conn, poll_reference_path(conn, :create, poll["id"]), reference: %{
			reference_poll_id: reference_poll["id"],
			pole: "positive"
		})
		json_response(conn, 201)["data"]
	end
end
