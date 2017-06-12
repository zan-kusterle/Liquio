defmodule Liquio.Web.IndexController do
	use Liquio.Web, :controller

	def app(conn, _) do
		conn
		|> put_resp_header("Cache-Control", "public, max-age=864000")
		|> render(Liquio.Web.LayoutView)
	end

	def page(conn, %{"url" => url}) do
		url_data = URI.parse(url)
		root_url = "#{url_data.scheme}://#{url_data.host}"
		script_url = Application.get_env(:liquio, :infuse_link)
		proxy_host = Application.get_env(:liquio, :proxy_host)

		response = HTTPotion.get(url, follow_redirects: true)
		if HTTPotion.Response.success?(response) do
			html = response.body

			html = html
			|> Floki.find("link")
			|> Floki.attribute("href")
			|> Enum.filter(& String.starts_with?(&1, "/") and not String.starts_with?(&1, "//"))
			|> Enum.reduce(html, fn(href, html) ->
				String.replace(html, "href=\"#{href}\"", "href=\"#{root_url}#{href}\"")
			end)

			html = html
			|> Floki.find("a")
			|> Floki.attribute("href")
			|> Enum.filter(& String.starts_with?(&1, "/") and not String.starts_with?(&1, "//"))
			|> Enum.reduce(html, fn(href, html) ->
				String.replace(html, "href=\"#{href}\"", "href=\"#{root_url}#{href}\"")
			end)

			player_html = html
			|> Floki.find("#player-api")
			|> Floki.raw_html

			embed_html = "<iframe id=\"main-video-frame\" width=\"100%\" height=\"100%\" src=\"https://www.youtube.com/embed/kVnO3Ru2N7s?enablejsapi=1\" frameborder=\"0\" allowfullscreen></iframe>"

			html = Regex.replace(~r/#{player_html}/i, html, "")
			html = String.replace(html, "<div class=\"player-api player-width player-height\"></div>", "<div class=\"player-api player-width player-height\">#{embed_html}</div>")
			html = String.replace(html, "yt.player.Application.create(\"player-api\", ytplayer.config);", "")
			html = String.replace(html, "<head>", "<head><base href=\"#{proxy_host}\"></base>")
			html = String.replace(html, "</body>", "<script src=\"#{script_url}\"></script></body>")			

			conn
			|> put_session(:current_domain, root_url)
			|> put_resp_content_type(response.headers["content-type"])
			|> put_resp_header("Cache-Control", "no-store, must-revalidate")
			|> send_resp(200, html)
		else
			conn
			|> send_resp(404, "Webpage does not exist")
		end
	end

	def resource(conn, %{"path" => path}) do
		domain = get_session(conn, :current_domain) || "https://www.youtube.com"
		url = "#{domain}/#{Enum.join(path, "/")}"

		cache_response = Cachex.get!(:resource_proxy, url)
		response = if cache_response do
			cache_response
		else
			fresh_response = HTTPotion.get(url, follow_redirects: true)
			if HTTPotion.Response.success?(fresh_response) do
				Cachex.set(:resource_proxy, url, fresh_response, ttl: 60)
				fresh_response
			else
				nil
			end
		end
		
		if response do
			conn
			|> put_resp_content_type(response.headers["content-type"])
			|> put_resp_header("Cache-Control", "no-store, must-revalidate")
			|> send_resp(200, response.body)
		else
			conn
			|> send_resp(404, "Resource not found")
		end
	end
end