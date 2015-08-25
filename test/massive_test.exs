defmodule Fleetbattlex.MassiveTest do
  use ExUnit.Case
  alias Fleetbattlex.Massive

  test "massive item with velocity moves according to its velocity" do
    original = %Massive{position: {0,0}, velocity: {2,4}}
    elapsed_time = 0.5

    expected_final_position = {1,2}
    assert Massive.progress_for_time(original, elapsed_time)|> Map.get(:position) == expected_final_position
  end

  test "massive item accellerates when force is applied" do
    original = %Massive{position: {0,0}, velocity: {2,4}}
    elapsed_time = 1

    forces = [{1,1}]
    new_velocity = Massive.progress_for_time(original, elapsed_time, forces) |> Map.get(:velocity)

    assert new_velocity == {3.0,5.0}
  end
end
