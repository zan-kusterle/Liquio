defmodule Democracy.HtmlDelegationController do
	use Democracy.Web, :controller
	alias Democracy.Identity
	alias Democracy.Delegation
	alias Democracy.Plugs

	import Democracy.Plugs.Params, only: [with_params: 2]

	with_params([
		{&Plugs.CurrentUser.handle/2, :user, [require: true]},
		{&Plugs.ItemParam.handle/2, :identity, [schema: Identity, name: "html_identity_id"]},
		{&Plugs.NumberParam.handle/2, :weight, [name: "weight", error: "Delegation weight must be a number"]},
		{&Plugs.TopicsParam.handle/2, :topics, [name: "topics"]}
	],
	def create(conn, p) do
	IO.inspect p
		%{:user => from_identity, :identity => to_identity, :weight => weight, :topics => topics} = p
		expr = quote do: Democracy.Plugs.Params.with_params([], def a do 1 end)
		res  = Macro.expand_once(expr, __ENV__)
		IO.puts Macro.to_string(res)

		if weight == 0 do
			Delegation.unset(from_identity, to_identity)
			conn
			|> redirect_back
		else
			Delegation.set(Delegation.changeset(%Delegation{}, %{
				from_identity_id: from_identity.id,
				to_identity_id: to_identity.id,
				weight: weight,
				topics: topics
			})) |> handle_errors(conn, fn(delegation) ->
				conn
				|> redirect_back
			end)
		end
	end)
end