defmodule Liquio.Helpers.PollHelper do
	alias Liquio.{Repo, Identity}

	def prepare(poll, calculation_opts, current_user, opts \\ []) do
		
		own_vote = if current_user do Vote.current_by(poll, current_user) else nil end
		poll = Map.put(poll, :own_vote, own_vote)

		poll = if opts[:put_references] do
			Map.put(poll, :references, Reference.for_poll(poll, calculation_opts))
		else
			poll
		end

		poll = if opts[:put_inverse_references] do
			Map.put(poll, :inverse_references, Reference.inverse_for_poll(poll, calculation_opts))
		else
			poll
		end

		embed_html = Phoenix.View.render_to_iodata(Liquio.HtmlPollView, "embed.html", poll: poll)
		|> :erlang.iolist_to_binary
		|> HtmlHelper.minify
		poll = Map.put(poll, :embed, embed_html)

		poll
	end
end