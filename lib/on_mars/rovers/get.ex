defmodule OnMars.Rovers.Get do
  alias OnMars.Coordinates

  def coordinates do
    send(OnMars.Rovers.Process, {:get_coordinates, self()})

    receive do
      {:ok, %Coordinates{}} = result -> result
    after
      1_000 -> {:error, "Ocorreu um erro no processamento da requisição"}
    end
  end
end
