use Mix.Config

config :logger,
  level: :debug

config :logger, :console,
  format: "$date $time [$level] $levelpad$message\n",
  colors: [info: :green]
