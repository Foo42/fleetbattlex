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
end
