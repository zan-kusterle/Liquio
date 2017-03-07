defimpl Poison.Encoder, for: DateTime do
	use Timex

	def encode(d, _options) do
		"\"#{Timex.format!(d, "{ISO:Extended}")}\""
	end
end