defmodule OnMars.Rovers.Process do
  alias OnMars.Coordinates
  alias OnMars.Rovers.Commands.{Move, Turn}

  @turn_commands Application.compile_env(:on_mars, [:constants, :turn_commands])
  @move_commands Application.compile_env(:on_mars, [:constants, :move_commands])

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  def start_link(name \\ __MODULE__, _opts) do
    initial_coordinates = initial_coordinates()

    pid = spawn(fn -> loop(initial_coordinates) end)

    Process.register(pid, name)

    {:ok, pid}
  end

  defp initial_coordinates do
    {:ok, coordinates} = Coordinates.build(0, 0, 0)

    coordinates
  end

  defp loop(%Coordinates{} = coordinates) do
    receive do
      {:reset_coordinates, caller} -> reset_coordinates(caller)
      {:get_coordinates, caller} -> get_coordinates(caller, coordinates)
      {:execute, caller, commands} -> execute(caller, commands, coordinates)
      _ -> loop(coordinates)
    end
  end

  defp reset_coordinates(caller) do
    send(caller, :ok)

    new_coordinates = initial_coordinates()

    loop(new_coordinates)
  end

  defp get_coordinates(caller, %Coordinates{} = coordinates) do
    send(caller, {:ok, coordinates})

    loop(coordinates)
  end

  defp execute(caller, commands, %Coordinates{} = coordinates) do
    coordinates
    |> call_command(commands)
    |> handle_result(caller, coordinates)
  end

  defp call_command(%Coordinates{} = coordinates, [command | tail])
       when command in @turn_commands do
    with {:ok, %Coordinates{} = new_coordinates} <- Turn.call(coordinates, command) do
      call_command(new_coordinates, tail)
    end
  end

  defp call_command(%Coordinates{} = coordinates, [command | tail])
       when command in @move_commands do
    with {:ok, %Coordinates{} = new_coordinates} <- Move.call(coordinates, command) do
      call_command(new_coordinates, tail)
    end
  end

  defp call_command(%Coordinates{} = coordinates, []) do
    {:ok, coordinates}
  end

  defp handle_result({:ok, %Coordinates{} = new_coordinates} = result, caller, _coordinates) do
    send(caller, result)

    loop(new_coordinates)
  end

  defp handle_result({:error, _reason} = error, caller, coordinates) do
    send(caller, error)

    loop(coordinates)
  end
end
