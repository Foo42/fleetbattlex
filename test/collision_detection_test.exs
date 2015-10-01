defmodule Fleetbattlex.CollisionDetectionTests do
  use ExUnit.Case
  alias Fleetbattlex.CollisionDetection, as: Collision

  test "non-overlapping vectors do not collide" do
    a = {{{0,0},{0,1}}, 1}
    b = {{{10,0},{10,1}}, 1}
    
    assert Collision.detected?(a,b) == false
  end

  test "crossing vectors collide" do
    a = {{{-1,1},{1,-1}}, 1}
    b = {{{1,-1},{-1,1}}, 1}
    
    assert Collision.detected?(a,b) == true
  end

  test "vector overlayed with part of other vector collides" do
    a = {{{0,0},{10,10}}, 1}
    b = {{{2,2},{4,4}}, 1}
    
    assert Collision.detected?(a,b) == true
  end

  test "size of items increases their intersection" do
    a = {{{0,0},{2,2}}, 1}
    b = {{{5,0},{7,2}}, 1}
    bLarge = {{{5,0},{7,2}}, 2}
    
    assert Collision.detected?(a,b) == false
    assert Collision.detected?(a,bLarge) == true
  end

  test "detect_all returns a list of colliding vector combinations when given a list of vectors" do
    north = %{name: {"going north"}, start_position: {0,2}, end_position: {0,5}, size: 0.5}
    east = %{name: {"going east"}, start_position: {2,0}, end_position: {5,0}, size: 0.5}
    diagonal_intecepter = %{name: {"smasher"}, start_position: {-1,4}, end_position: {4,-1}, size: 1}

    collisions = Collision.detect_all [north,east,diagonal_intecepter]
    assert not Enum.member? collisions, {{"going north"}, {"going east"}}
    assert Enum.member? collisions, {{"going north"}, {"smasher"}}
    assert collisions |> Enum.all?(fn {name , other_name} -> name != other_name end)
  end
end
