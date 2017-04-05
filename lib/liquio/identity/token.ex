defmodule Liquio.Token do
	use Liquio.Web, :model
	use Mailgun.Client,
		domain: Application.get_env(:liquio, :mailgun_domain),
		key: Application.get_env(:liquio, :mailgun_key)
	alias Liquio.{Token, Repo}

	schema "tokens" do
		field :email, :string
		field :token, :string
		field :is_valid, :boolean
		timestamps(inserted_at: :datetime, updated_at: false, usec: true)
	end

	def get_email(token) do
		token_item = Repo.get_by(Token, token: token, is_valid: true)
		before = Timex.shift(Timex.now, minutes: -Application.get_env(:liquio, :token_lifespan_minutes))
		if token_item != nil and Timex.before?(before, token_item.datetime) do
			token_item.email
		else
			nil
		end
	end

	def new(email) do
		token = SecureRandom.hex(30)
		from(t in Token, where: t.email == ^email)
		|> Repo.update_all(set: [is_valid: false])
		token_item = Repo.insert!(%Token{
			email: email,
			token: token,
			is_valid: true
		})
		token_item
	end

	def send_token(token) do
		url = "#{Liquio.Web.Endpoint.url()}/api/login/#{token.token}"
		send_email(
			to: token.email,
			from: "Liquio <login@liqu.io>",
			subject: "Instantly login to Liquio",
			html: "<a href=\"#{url}\" style=\"background-color: #2a9fec; color: white; display: block; padding: 20px 30px; text-align: center; max-width: 200px; margin: 0 auto; font-size: 22px; text-decoration: none; border-radius: 5px;\">Login to Liquio</a>"
		)
	end

	def use(token) do
		token_item = Repo.get_by(Token, token: token, is_valid: true)
		Repo.update! Ecto.Changeset.change token_item, is_valid: false
	end
end