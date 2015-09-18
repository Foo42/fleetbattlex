defmodule Fleetbattlex.ShipController do
  use Fleetbattlex.Web, :controller
  alias Fleetbattlex.Ship

  def index(conn, _params) do
    json conn, []
  end

  def show(conn, %{"fleet_id" => fleet_name, "id" => ship_name}) do
  	position = Ship.current_position({fleet_name, ship_name}).position
  	json conn, %{"fleet" => fleet_name, "ship" => ship_name, "position" => position_tuple_to_object(position)} 
  end

  defp position_tuple_to_object {x,y} do
  	%{"x" => x, "y" => y}
  end
end
