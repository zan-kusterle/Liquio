defmodule Liquio.PollControllerTest do
	use Liquio.ConnCase

	alias Liquio.Poll
	@valid_attrs %{title: "Test title", topics: ["politics"], choice_type: "probability"}
	@invalid_attrs %{title: nil}

	setup %{conn: conn} do
		{:ok, conn: put_req_header(conn, "accept", "application/json")}
	end

	test "shows chosen resource", %{conn: conn} do
		conn = post(conn, poll_path(conn, :create), poll: @valid_attrs)
		[location | _] = get_resp_header(conn, "location")
		conn = get conn, location
		assert json_response(conn, 200)["data"] |> Map.drop(["id"]) == %{
			"title" => @valid_attrs.title,
			"topics" => @valid_attrs.topics,
			"choice_type" => @valid_attrs.choice_type,
			"kind" => "custom",
			"results" => %{"count" => 0, "mean" => 0.0, "total" => 0}
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
