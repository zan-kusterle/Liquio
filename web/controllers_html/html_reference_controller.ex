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
		reference_poll = Repo.get(Poll, reference_poll_id)

		if reference_poll != nil and reference_poll.kind == "custom" do
			conn
			|> redirect(to: html_poll_html_reference_path(conn, :show, poll_id, reference_poll_id))
		else
			conn
			|> put_flash(:info, "The poll you want to reference does not exist.")
			|> redirect(to: html_poll_path(conn, :show, poll_id))
		end
	end

	with_params(%{
		:user => {Plugs.CurrentUser, [require: true]},
		:poll => {Plugs.ItemParam, [schema: Poll, name: "html_poll_id", validator: &Poll.is_custom/1]},
		:reference_poll => {Plugs.ItemParam, [schema: Poll, name: "id", validator: &Poll.is_custom/1]},
	},
	def show(conn, %{:user => user, :poll => poll, :reference_poll => reference_poll}) do
		calculation_opts = get_calculation_opts_from_conn(conn)
		reference = poll
		|> Reference.get(reference_poll)
		|> Repo.preload([:for_choice_poll, :reference_poll, :poll])
		contributions = reference.for_choice_poll |> Poll.calculate_contributions(calculation_opts) |> Enum.map(fn(contribution) ->
			Map.put(contribution, :identity, Repo.get(Identity, contribution.identity_id))
		end)
		results = Poll.calculate(reference.for_choice_poll, calculation_opts)
		reference = Map.put(reference, :for_choice_poll, reference.for_choice_poll |> Map.put(:results, results) |> Map.put(:contributions, contributions))
		own_vote = Vote.current_by(reference.for_choice_poll, user)
		conn
		|> put_resp_header("Cache-Control", "no-cache, no-store, must-revalidate, max-age=0")
		|> render("show.html",
			title: poll.title || "Liquio",
			reference: reference,
			poll: poll |> Map.put(:results, Poll.calculate(poll, calculation_opts)),
			reference_poll: reference_poll |> Map.put(:results, Poll.calculate(reference_poll, calculation_opts)),
			own_vote: own_vote,
			own_poll: reference.for_choice_poll |> Map.put(:results, if own_vote do Poll.results_for_vote(reference.for_choice_poll, own_vote) else nil end),
			calculation_opts: calculation_opts)
	end)
end
