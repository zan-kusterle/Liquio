defmodule Liquio.Signature do
	use Ecto.Schema
	import Ecto.Query, only: [from: 2]
	alias Liquio.{Repo, Signature}

	schema "signatures" do
		field :public_key, :string
		field :data, :string
		field :data_hash, :string
		field :signature, :string
		field :ipfs_hash, :string
	end

	def add!(public_key, data, signature) do
		case add(public_key, data, signature) do
			{:ok, s} -> s
			{:error, e} -> raise e
		end
	end

	def add(public_key, data, signature) do
		data_hash = :crypto.hash(:sha512, data)

		if Ed25519.valid_signature?(signature, data_hash, public_key) do
			conn = %IpfsConnection{host: "127.0.0.1", base: "api/v0", port: 5001}
			ipfs_content = [data, Base.encode64(public_key), Base.encode64(signature)]
			case IpfsApi.add(conn, Enum.join(ipfs_content, "//")) do
				{:ok, ipfs_result} ->
					result = Repo.insert!(%Signature{
						:public_key => Base.encode64(public_key),
						:data => data,
						:data_hash => Base.encode64(data_hash),
						:signature => Base.encode64(signature),
						:ipfs_hash => ipfs_result["Hash"]
					})
					{:ok, result}
				{:error, e} ->
					{:error, "IPFS unavailable: #{e}"}
			end
		else
			{:error, "Invalid signature"}
		end
	end
end
