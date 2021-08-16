defmodule OnMars.Rovers.Execute do
  alias Ecto.Changeset

  alias OnMars.{Commands, Error}

  def call(params) do
    case Commands.changeset(params) do
      %Changeset{changes: %{commands: commands}, valid?: true} -> do_execute(commands)
      %Changeset{valid?: false} = changeset -> {:error, Error.build(:bad_request, changeset)}
    end
  end

  defp do_execute(commands) do
    send(OnMars.Rovers.Process, {:execute, self(), commands})

    receive do
      {:ok, _} = result = result -> result
      {:error, _reason} = error -> error
    after
      1_000 -> {:error, "Ocorreu um erro no processamento da requisição"}
    end
  end
end
