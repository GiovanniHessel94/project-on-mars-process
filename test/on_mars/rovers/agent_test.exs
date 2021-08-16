defmodule OnMars.Rovers.ProcessTest do
  use ExUnit.Case, async: false

  import OnMars.Factory

  alias Ecto.Changeset

  alias OnMars.{Coordinates, Error}
  alias OnMars.Rovers.Process, as: RoverProcess

  describe "get_coordinates/0" do
    setup do
      process_name = :process_get_coordinates

      {:ok, _pid} = RoverProcess.start_link(process_name, %{})

      {:ok, process_name: process_name}
    end

    test "when called, should get the coordinates", %{process_name: process_name} do
      expected_response = {:ok, build(:coordinates)}

      send(process_name, {:get_coordinates, self()})

      receive do
        response -> assert response == expected_response
      after
        1_000 -> raise "timeout"
      end
    end
  end

  describe "execute/1" do
    setup do
      process_name = :process_execute

      {:ok, pid} = RoverProcess.start_link(process_name, %{})

      on_exit(fn -> Process.exit(pid, "exit") end)

      {:ok, process_name: process_name}
    end

    test "when called, should execute the commands", %{process_name: process_name} do
      %Changeset{changes: %{commands: commands}, valid?: true} = build(:commands)

      expected_response = {
        :ok,
        %Coordinates{x: 1, y: 1, direction_index: 0}
      }

      send(process_name, {:execute, self(), commands})

      receive do
        response -> assert response == expected_response
      after
        1_000 -> raise "timeout"
      end
    end

    test "when the commands cannot be executed, return an error", %{process_name: process_name} do
      commands = [:GD, :M, :M]

      expected_response = {
        :error,
        %Error{
          reason: "A sonda detectou que essa série de comandos não pode ser executada!",
          status: :bad_request
        }
      }

      send(process_name, {:execute, self(), commands})

      receive do
        response -> assert response == expected_response
      after
        1_000 -> raise "timeout"
      end
    end
  end

  describe "reset_coordinates/0" do
    setup do
      process_name = :process_reset_coordinates

      {:ok, _pid} =
        RoverProcess.start_link(process_name, %Coordinates{direction_index: 0, x: 1, y: 1})

      {:ok, process_name: process_name}
    end

    test "when called, should reset the coordinates", %{process_name: process_name} do
      expected_reset_response = :ok
      expected_after_get_response = {:ok, build(:coordinates)}

      send(process_name, {:reset_coordinates, self()})

      receive do
        response -> assert response == expected_reset_response
      after
        1_000 -> raise "timeout"
      end

      send(process_name, {:get_coordinates, self()})

      receive do
        response -> assert response == expected_after_get_response
      after
        1_000 -> raise "timeout"
      end
    end
  end
end
