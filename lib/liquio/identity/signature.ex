defmodule Liquio.Signature do
	use Ecto.Schema
	use Bitwise
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
		bytes = data |> String.to_charlist |> Enum.flat_map(fn(code) ->
			if code <= 255 do
				[code]
			else
				[code >>> 8, code &&& 255]
			end
		end)
		data_hash = :crypto.hash(:sha512, bytes)

		if Ed25519.valid_signature?(signature, data_hash, public_key) do
			conn = %IpfsConnection{host: "127.0.0.1", base: "api/v0", port: 5001}
			ipfs_content = Poison.encode!(%{
				"public_key" => Base.encode64(public_key),
				"data" => data,
				"signature" => Base.encode64(signature)
			})

			ipfs_result = if Application.get_env(:liquio, :enable_ipfs) do
				IpfsApi.add(conn, ipfs_content)
			else
				{:ok, %{"Hash" => "Development"}}
			end
			
			case ipfs_result do
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
