defmodule Liquio.ReferenceControllerTest do
	use Liquio.ConnCase
	
	setup %{conn: conn} do
		{:ok, conn: put_req_header(conn, "accept", "application/json")}
	end

	test "shows chosen resource", %{conn: conn} do
		poll = create_poll(%{title: "A", choice_type: "probability"})
		reference_poll = create_poll(%{title: "B", choice_type: "probability"})
		reference = create_reference(poll, reference_poll, 1)

		get conn, poll_reference_path(conn, :show, reference["poll"]["id"], reference["id"])
		assert reference["for_choice"] == 1
	end

	def create_poll(params) do
		conn = build_conn
		conn = post(conn, poll_path(conn, :create), poll: params)
		json_response(conn, 201)["data"]
	end

	def create_reference(poll, reference_poll, for_choice) do
		conn = build_conn
		conn = get(conn, poll_reference_path(conn, :show, poll["id"], reference_poll["id"], for_choice: for_choice))
		json_response(conn, 200)["data"]
	end
end
