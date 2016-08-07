defmodule Liquio.ResultTest do
	use Liquio.ModelCase

	alias Liquio.Result

	test "results with random delegations and votes" do
		Result.create_random("1K.data", 1000, 100, 10)
		Result.calculate_random("1K.data")
	end
end
