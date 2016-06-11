defmodule Democracy.PollControllerTest do
	use Democracy.ConnCase

	alias Democracy.Poll
	@valid_attrs %{title: "Test title", choices: ["a", "b"], topics: ["politics"]}
	@invalid_attrs %{title: nil, choices: ["a", nil]}

	setup %{conn: conn} do
		{:ok, conn: put_req_header(conn, "accept", "application/json")}
	end

	test "shows chosen resource", %{conn: conn} do
		conn = post(conn, poll_path(conn, :create), poll: @valid_attrs)
		[location | _] = get_resp_header(conn, "location")
		conn = get conn, location
		assert json_response(conn, 200)["data"] == %{
			"title" => @valid_attrs.title,
			"choices" => @valid_attrs.choices,
			"topics" => @valid_attrs.topics,
			"kind" => "custom",
			"is_direct" => false
		}
	end

	test "does not show resource and instead throw error when id is nonexistent", %{conn: conn} do
		conn = get conn, poll_path(conn, :show, -1)
    	assert conn.status == 404
	end

	test "creates and renders resource when data is valid", %{conn: conn} do
		conn = post(conn, poll_path(conn, :create), poll: @valid_attrs)
		assert json_response(conn, 201)["data"]["title"]
		assert Repo.get_by(Poll, @valid_attrs)
	end

	test "does not create resource and renders errors when data is invalid", %{conn: conn} do
		conn = post conn, poll_path(conn, :create), poll: @invalid_attrs
		assert json_response(conn, 422)["errors"] != %{}
	end
end
