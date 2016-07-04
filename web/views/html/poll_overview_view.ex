defmodule Democracy.PollOverviewView do
	use Democracy.Web, :view

	def score_color(score) do
		cond do
			score < 0.5 -> "rgb(255, 164, 164)"
			score < 0.75 -> "rgb(249, 226, 110)"
			true -> "rgb(140, 232, 140)"
		end
	end
end
