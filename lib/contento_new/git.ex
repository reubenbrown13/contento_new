defmodule Contento.New.Git do
  alias Contento.New.Shell

  def version do
    Shell.cmd("git", ["--version"])
    |> String.replace("git version ", "")
    |> Version.parse!()
  end

  def clone_repo(url, dest) do
    task = Task.async(fn ->
      Shell.cmd("git", ["clone", url, dest])
    end)

    Task.await(task)
  end
end
