defmodule Fleetbattlex.ShipSupervisor do
	use Supervisor
	alias Fleetbattlex.Ship
	alias Fleetbattlex.Massive

	def start_link() do
		Supervisor.start_link(__MODULE__, nil, name: __MODULE__)
	end

	def start_ship_linked(params) do
		Supervisor.start_child(__MODULE__, [params])
	end

	def init(_) do
		processes = [
			worker(Ship, []),
		]
		supervise(processes, strategy: :simple_one_for_one)
	end
end
