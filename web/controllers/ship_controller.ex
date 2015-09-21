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

  def list_burns(conn,%{"fleet_id" => fleet_name, "ship_id" => ship_name}) do
    ship = {fleet_name,ship_name}
    burns = Ship.list_burns(ship)
    [first | _ ] = burns
  	json conn, burns 
  end

  def post_burn(conn, params = %{"fleet_id" => fleet_name, "ship_id" => ship_name}) do
    ship = {fleet_name,ship_name}
    
    defaults = %{"power" => 100.0}
    Logger.info "params: #{inspect params}"
    burn = params |> Dict.take(["power","duration"]) |> as_floats(["power","duration"])
    
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
end
