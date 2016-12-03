defmodule Liquio.HtmlReferenceController do
	use Liquio.Web, :controller

	def index(conn, %{"html_poll_id" => poll_id, "reference_poll_id" => reference_poll_url}) do
		url = URI.parse(reference_poll_url)
		reference_poll_id =
			if url.path != nil and url.path |> String.starts_with?("/polls/") do
				String.replace(url.path, "/polls/", "")
			else
				reference_poll_url
			end
		conn
		|> redirect(to: html_poll_html_reference_path(conn, :show, poll_id, reference_poll_id))
	end

	with_params(%{
		:user => {Plugs.CurrentUser, [require: true]},
		:poll => {Plugs.ItemParam, [schema: Poll, name: "html_poll_id", validator: &Poll.is_custom/1]},
		:reference_poll => {Plugs.ItemParam, [schema: Poll, name: "id"]},
	},
	def show(conn, %{:user => user, :poll => poll, :reference_poll => reference_poll}) do
		calculation_opts = get_calculation_opts_from_conn(conn)
		reference = poll
		|> Reference.get(reference_poll)
		|> Repo.preload([:for_choice_poll, :reference_poll, :poll])
		results = Poll.calculate(reference.for_choice_poll, calculation_opts)
		reference = Map.put(reference, :for_choice_poll, Map.put(reference.for_choice_poll, :results, results))
		conn
		|> put_resp_header("Cache-Control", "no-cache, no-store, must-revalidate, max-age=0")
		|> render("show.html",
			title: poll.title || "Liquio",
			reference: reference,
			own_vote: Vote.current_by(reference.for_choice_poll, user),
			calculation_opts: calculation_opts)
	end)
end
