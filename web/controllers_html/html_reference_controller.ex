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
		:user => {Plugs.CurrentUser, [require: false]},
		:node => {Plugs.NodeParam, [name: "html_poll_id"]},
		:reference_node => {Plugs.NodeParam, [name: "id"]}
	},
	def show(conn, %{:user => user, :node => node, :reference_node => reference_node}) do
		calculation_opts = get_calculation_opts_from_conn(conn)
		for_choice_node = Node.for_reference_key(node, reference_node.key)

		IO.inspect for_choice_node.key
		IO.inspect for_choice_node.reference_key

		conn
		|> put_resp_header("Cache-Control", "no-cache, no-store, must-revalidate, max-age=0")
		|> render("show.html",
			title: "References | #{node.title}",
			calculation_opts: calculation_opts,
			poll: Node.preload(node, calculation_opts, user),
			reference_poll: Node.preload(reference_node, calculation_opts, user),
			for_choice_node: Node.preload(for_choice_node, calculation_opts, user))
	end)
end
