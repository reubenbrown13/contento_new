defmodule Mix.Tasks.Contento.New do
  use Mix.Task

  require Logger

  import Mix.Contento

  def run(args) do
    if length(args) == 0 do
      raise_wrong_usage()
    end

    {dest, _opts} = process_args(args)

    Logger.info "Starting installing Contento in #{dest}..."

    with :ok <- clone_contento(dest) do
      File.cd!(dest, fn ->
        with :ok <- create_config_files(dest),
             :ok <- fetch_and_compile_deps(),
             :ok <- install_and_build_assets(),
             :ok <- create_db_and_migrate(),
             :ok <- install_default_theme(),
             :ok <- setup() do
          Logger.info """
          Yeaah! Your Contento website is ready!

          Only thing left is to run your new awesome website! Run the following commands to do so:

            $ cd #{dest}/ # enter project directory
            $ mix phx.server # start Contento

          Default user credentials are:

            Username: contento@example.org
            Password: contento

          After starting the server, you may login to back-office through:

            http://localhost:4000/login
          """
        end
      end)
    end
  end

  defp process_args(args), do: {Enum.at(args, 0), OptionParser.parse(args)}

  defp raise_wrong_usage do
    Mix.raise """
    Please, specify a destination directory to install your Contento website.

      mix contento.new [destination]
    """
  end
end
