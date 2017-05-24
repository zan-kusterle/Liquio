defmodule Liquio.Signature do
	use Liquio.Web, :model
	alias Liquio.{Repo, Signature}

	schema "signatures" do
		field :public_key, :string
		field :data, :string
		field :data_hash, :string
		field :signature, :string
	end

	def add!(public_key, data, signature) do
		case add(public_key, data, signature) do
			{:ok, s} -> s
			{:error, e} -> raise e
		end
	end

	def add(public_key, data, signature) do
		data_hash = :crypto.hash(:sha512, data)

		IO.inspect signature
		IO.inspect data
		IO.inspect data_hash
		IO.inspect public_key

		if Ed25519.valid_signature?(signature, data_hash, public_key) do
			result = Repo.insert!(%Signature{
				:public_key => Base.encode64(public_key),
				:data => data,
				:data_hash => data_hash,
				:signature => signature
			})

			{:ok, result}
		else
			{:error, "Invalid signature"}
		end
	end
end
