defmodule Liquio.Token do
	use Liquio.Web, :model
	use Mailgun.Client,
		domain: Application.get_env(:liquio, :mailgun_domain),
		key: Application.get_env(:liquio, :mailgun_key)
	alias Liquio.{Token, Repo, Router, Endpoint}

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
		token = SecureRandom.hex(30)
		#Repo.update! Ecto.Changeset.change token_item, is_valid: false
		token_item = Repo.insert!(%Token{
			email: email,
			token: token,
			is_valid: true
		})

		url = Router.Helpers.html_token_url(Endpoint, :show, token)
		send_email(
			to: email,
			from: "login@liqu.io",
			subject: "Instantly login to Liquio",
			text: "Open to login: #{url}"
		)
	end

	def use(token) do
		token_item = Repo.get_by(Token, token: token, is_valid: true)
		Repo.update! Ecto.Changeset.change token_item, is_valid: false
	end
end