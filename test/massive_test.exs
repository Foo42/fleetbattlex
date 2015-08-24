defmodule Fleetbattlex.MassiveTest do
  use ExUnit.Case
  alias Fleetbattlex.Massive

  test "massive item with velocity moves according to its velocity" do
    original = %Massive{position: {0,0}, velocity: {2,4}}
    elapsed_time = 0.5

    expected_final_position = {1,2}
    assert Massive.progress_for_time(original, elapsed_time)|> Map.get(:position) == expected_final_position
  end
end
