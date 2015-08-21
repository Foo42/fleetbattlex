defmodule Fleetbattlex.PhysicsTest do
  use ExUnit.Case
  alias Fleetbattlex.Physics

  test "velocity moves positions" do
    original_position = {0,0}
    velocity = {2,4}
    elapsed_time = 0.5

    expected_final_position = {1,2}
    assert Physics.apply_velocity(original_position, velocity, elapsed_time) == expected_final_position
  end

  test "accelleration adjusts velocity" do
  	original_velocity = {0,0}
    accelleration = {2,4}
    elapsed_time = 0.5

    expected_final_velocity = {1,2}
    assert Physics.apply_accelleration(original_velocity, accelleration, elapsed_time) == expected_final_velocity
  end
end
