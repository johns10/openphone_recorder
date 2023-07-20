# Discussit

To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Commands

FLY_DEV=1 fly pg connect --app openphone-recorder-db
./discussit eval 'Discussit.Release.rollback(Discussit.Repo, '')'
./discussit eval 'Discussit.Release.migrate()'
./bin/discussit eval 'Mix.Tasks.SetAccountId.run(["2a711272-a6db-43d1-ae4d-5ba29f447396"])'
./bin/discussit eval 'Discussit.Events.Consumer.set_count(10)'
fly ssh console --select -C "/app/bin/discussit remote"
```
bin/discussit eval 'Discussit.Release.migrate()'
```

./bin/discussit eval 'Discussit.Events.list_unprocessed_events()'