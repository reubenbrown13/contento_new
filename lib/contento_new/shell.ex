defmodule Contento.New.Shell do
  def cmd(command, args \\ []) do
    Task.async(fn ->
      {output, exit_status} = System.cmd(command, args)

      output = String.replace(output, "\n", "")

      if exit_status != 0 do
        {:error, output}
      else
        {:ok, output}
      end
    end)
    |> Task.await(:infinity)
  end
end
