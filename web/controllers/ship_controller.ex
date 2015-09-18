defmodule Fleetbattlex.ShipController do
  use Fleetbattlex.Web, :controller

  def index(conn, _params) do
    json conn, []
  end

  def show(conn, %{"fleet_id" => fleet_name, "id" => ship_name}) do
  	json conn, %{"fleet" => fleet_name, "ship" => ship_name} 
  end
end
