defmodule Liquio.HtmlReferenceController do
	use Liquio.Web, :controller

	def index(conn, %{"html_poll_id" => poll_id, "for_choice" => for_choice, "reference_poll_id" => reference_poll_url}) do
		url = URI.parse(reference_poll_url)
		reference_poll_id =
			if url.path |> String.starts_with?("/polls/") do
				String.replace(url.path, "/polls/", "")
			else
				reference_poll_url
			end
		conn
		|> redirect to: html_poll_html_reference_path(conn, :show, poll_id, reference_poll_id, for_choice: for_choice)
	end

	with_params(%{
		:user => {Plugs.CurrentUser, [require: true]},
    	:poll => {Plugs.ItemParam, [schema: Poll, name: "html_poll_id", validator: &Poll.is_custom/1]},
    	:reference_poll => {Plugs.ItemParam, [schema: Poll, name: "id"]},
		:for_choice => {Plugs.NumberParam, [name: "for_choice", error: "For choice must be a number"]},
	},
	def show(conn, %{:user => user, :poll => poll, :reference_poll => reference_poll, :for_choice => for_choice}) do
		calculation_opts = get_calculation_opts_from_conn(conn)
		reference = Reference.get(poll, reference_poll, for_choice)
		|> Repo.preload([:approval_poll, :reference_poll, :poll])
		results = Result.calculate(reference.approval_poll, calculation_opts)
		reference = Map.put(reference, :approval_poll, Map.put(reference.approval_poll, :results, results))
		conn
		|> put_resp_header("Cache-Control", "no-cache, no-store, must-revalidate, max-age=0")
		|> render "show.html",
			title: poll.title || "Liquio",
			reference: reference,
			for_choice: for_choice,
			own_vote: Vote.current_by(reference.approval_poll, user)
	end)
end
