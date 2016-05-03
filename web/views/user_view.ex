defmodule Democracy.UserView do
    use Democracy.Web, :view

    def render("index.json", %{users: users}) do
        %{data: render_many(users, Democracy.UserView, "user.json")}
    end

    def render("show.json", %{user: user}) do
        %{data: render_one(user, Democracy.UserView, "user.json")}
    end

    def render("user.json", %{user: user}) do
        v = %{
            username: user.username,
            name: user.name,
            voting_power: user.voting_power,
        }
        if Map.has_key?(user, :insecure_token) do
            v = Map.put(v, :token, user.insecure_token)
        end
        if Map.has_key?(user, :access_token) do
            v = Map.put(v, :access_token, user.access_token)
        end
        v
    end
end
