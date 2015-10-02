defmodule Fleetbattlex.Game do
	use GenServer
	require Logger
	alias Fleetbattlex.Massive
	alias Fleetbattlex.Physics
	alias Fleetbattlex.Ship
	alias Fleetbattlex.ShipSupervisor
	alias Fleetbattlex.Collisions

	@speed 0.1

	def start_link() do
		Logger.info "in game start_link"
		ships = [
			%{name: {"red", "defiance"}, massive: %Massive{velocity: {0,8}, position: {50,0}}},
			%{name: {"blue", "jane"}, massive: %Massive{velocity: {0.0, 0.0}, position: {100,0}, mass: 25}}
		]
		ships |> Enum.each(&ShipSupervisor.start_ship_linked(&1))
		ship_names = ships |> Enum.map(&(&1.name))
		GenServer.start_link(__MODULE__,%{ships: ship_names})
	end

	def init(args) do
		seconds = @speed
		:erlang.send_after(trunc(seconds * 1000), self(), :game_tick)
		{:ok, initialise_positions(args)}
	end

	def handle_info(:game_tick, state = %{ships: ships, last_positions: last_positions }) do
		Logger.info "tick"

		seconds = @speed

		gravity_for_each = last_positions |> Enum.map(&gravity_from_others(&1, last_positions))
		ships_with_gravity = Enum.zip(ships,gravity_for_each)

		updated_posititions = ships_with_gravity |> Enum.map(fn {ship, gravity} -> Ship.progress_for_time(ship, seconds, [gravity]) end)

		collisions = detect_collisions(last_positions, updated_posititions)
		case collisions do
			[] -> nil
			_ -> Logger.info("Collisions! #{inspect collisions}")
		end
		collisions
			|> Enum.each(fn {who, who_else} -> Collisions.notify_of_collision(who, who_else) end)

		push_position_updates_to_clients(updated_posititions)

		:erlang.send_after(trunc(seconds * 1000), self(), :game_tick)
		{:noreply, %{state | last_positions: updated_posititions}}
	end

	defp gravity_from_others(target = %{position: position, mass: mass}, others) do
		is_self = fn %{position: other_position} -> other_position == position end

		others 
			|> Enum.reject(is_self)
			|> Enum.map(&Physics.calculate_gravitational_field(target, &1))
			|> Physics.sum_vectors
	end

	defp initialise_positions(state)do
		Logger.info "initialising positions for #{inspect state.ships}"
		positions = state.ships 
			|> Enum.map(fn ship -> Ship.current_position(ship) |> Map.put(:name, ship) end)
		Dict.put(state,:last_positions, positions)
	end

	defp push_position_updates_to_clients(updated_posititions) do
		position_update_message = updated_posititions 
			|> Enum.map(&summary_to_ship_update/1)
		Fleetbattlex.Endpoint.broadcast! "positions:updates", "update", %{positions: position_update_message}
	end

	defp detect_collisions(last_positions, updated_posititions) do
		Enum.zip(last_positions,updated_posititions) 
			|> Enum.map(fn {%{name: name, mass: size, position: start_position},%{position: end_position}} -> %{name: name, start_position: start_position, end_position: end_position, size: size} end)
			|> Collisions.detect_all
	end

	defp summary_to_ship_update(summary) do
		summary
			|> Enum.map(fn
				{:position, {x,y}} -> {:position, %{x: x, y: y}}
				{:bearing, {x,y}} -> {:bearing, %{x: x, y: y}}
				{:name, {fleet,ship}} -> {:name, %{fleet: fleet, ship: ship}}
				other -> other
			end)
			|> Enum.into(%{})
	end
end
