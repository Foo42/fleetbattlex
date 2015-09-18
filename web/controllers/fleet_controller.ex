defmodule Fleetbattlex.FleetController do
  use Fleetbattlex.Web, :controller

  def index(conn, _params) do
    json conn, ["red","blue"]
  end

  def show(conn, %{"id" => fleet_name}) do
  	json conn, %{"name" => fleet_name} 
  end
end
