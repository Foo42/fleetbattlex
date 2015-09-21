defmodule Fleetbattlex.ShipController do
  use Fleetbattlex.Web, :controller
  alias Fleetbattlex.Ship
  require Logger

  def index(conn, _params) do
    json conn, []
  end

  def show(conn, %{"fleet_id" => fleet_name, "id" => ship_name}) do
  	position = Ship.current_position({fleet_name, ship_name}).position
  	json conn, %{"fleet" => fleet_name, "ship" => ship_name, "position" => position_tuple_to_object(position)} 
  end

  def get_burn(conn,%{"fleet_id" => fleet_name, "ship_id" => ship_name}) do
    ship = {fleet_name,ship_name}
    burn = Ship.get_burn(ship)
  	json conn, burn 
  end

  def post_burn(conn, params = %{"fleet_id" => fleet_name, "ship_id" => ship_name}) do
    ship = {fleet_name,ship_name}
    
    defaults = %{"percentage" => 100.0}
    Logger.info "params: #{inspect params}"
    burn = params |> Dict.take(["percentage","thrust"]) |> as_floats(["percentage", "thrust"]) |> limit_value("percentage",100.0)
    
    Ship.start_burn(ship,Dict.merge(defaults, burn))
  	json conn, %{}
  end

  defp position_tuple_to_object {x,y} do
  	%{"x" => x, "y" => y}
  end

  defp as_floats(dict, keys) do
    keys |> Enum.reduce(dict, fn (key, dict) -> 
      if Dict.has_key?(dict,key) do
        dict |> Dict.update!(key,fn val -> elem(Float.parse(val),0) end)
      else
        dict
      end
    end)
  end

  defp limit_value(dict, key, max_value) do
      if Dict.has_key?(dict,key) do
        dict |> Dict.update!(key, &min(&1,max_value))
      else
        dict
      end
  end 
end
