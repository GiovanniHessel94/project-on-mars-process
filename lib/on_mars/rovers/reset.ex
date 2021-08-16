defmodule OnMars.Rovers.Reset do
  def coordinates do
    send(OnMars.Rovers.Process, {:reset_coordinates, self()})

    receive do
      :ok -> {:ok, "Sonda posicionada nas coordenadas iniciais!"}
    after
      1_000 -> {:error, "Ocorreu um erro no processamento da requisição"}
    end
  end
end
