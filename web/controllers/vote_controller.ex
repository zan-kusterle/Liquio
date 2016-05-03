defmodule Democracy.VoteController do
    use Democracy.Web, :controller

    def index(conn, params) do
        render(conn, "cast_vote.html",
            app: "Fact.io",
            poll: %{
                "name" => "Global warming is real and caused by humans.",
                "choices" => ["true", "false"]
            },
            total_voting_power: 16.08,
            total_weight: 6.75
        )
    end
end
