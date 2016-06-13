defmodule Democracy.ResultTest do
	use Democracy.ModelCase

	alias Democracy.Result

	test "results with random delegations and votes" do
		Result.calculate_random(1000, 100, 10)
	end
end
