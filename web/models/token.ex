defmodule Liquio.Token do
	use Liquio.Web, :model

	alias Liquio.Token
	alias Liquio.Repo

	schema "tokens" do
		field :email, :string
		field :token, :string
		field :is_valid, :boolean
		timestamps(inserted_at: :datetime, updated_at: false, usec: true)
	end

	def get_email(token) do
		token_item = Repo.get_by(Token, token: token, is_valid: true)
		if token_item != nil and token_item.datetime do
			token_item.email
		else
			nil
		end
	end

	def new(email) do
		token = random_string(40)
		token_item = Repo.insert!(%Token{
			email: email,
			token: token,
			is_valid: true
		})
		# invalidate previous, send email
	end

	defp random_string(length) do
		chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789" |> String.split("")
		Enum.join(Enum.reduce((1..length), [], fn (_, acc) ->
			[Enum.random(chars) | acc]
		end), "")
	end
end