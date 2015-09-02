defmodule Fleetbattlex.PositionsChannel do
  use Phoenix.Channel
  require Logger

  def join("positions:updates", auth_msg, socket) do
	Logger.info "Connection joined channel"  	
    {:ok, socket}
  end
end
