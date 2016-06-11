ExUnit.start

Mix.Task.run "ecto.create", ~w(-r Democracy.Repo --quiet)
Mix.Task.run "ecto.migrate", ~w(-r Democracy.Repo --quiet)
Ecto.Adapters.SQL.begin_test_transaction(Democracy.Repo)
