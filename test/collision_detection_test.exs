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
end
