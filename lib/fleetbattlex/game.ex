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
			%{name: {"red", "dog"}, bearing: {0,1}, massive: %Massive{velocity: {0.0, 0.0}, position: {100.0, -1000.0}, mass: 25}},
			%{name: {"red", "cat"}, bearing: {0,1}, massive: %Massive{velocity: {0.0, 0.0}, position: {-100.0, -1000.0}, mass: 25}},
			%{name: {"blue", "go"}, massive: %Massive{velocity: {0.0, -0.0}, position: {100.0, 1000.0}, mass: 25}},
			%{name: {"blue", "nad"}, massive: %Massive{velocity: {0.0, -0.0}, position: {-100.0, 1000.0}, mass: 25}}
		]
		ships |> Enum.each(&ShipSupervisor.start_ship_linked(&1))
		ship_names = ships |> Enum.map(&(&1.name))
		GenServer.start_link(__MODULE__,%{ships: ship_names}, name: :game)
	end

	def init(args) do
		seconds = @speed
		:erlang.send_after(trunc(seconds * 1000), self(), :game_tick)
		{:ok, initialise_positions(args)}
	end

	def add_piece(name) do
		GenServer.call(:game, {:add_piece, name})
	end

	def handle_call({:add_piece, name}, _from, state = %{ships: ship_names, last_positions: last_positions}) do
		Logger.info "Adding piece with name: #{inspect name}"
		Logger.info "ships before: #{inspect ship_names}"
		after_ships = [name | ship_names]
		updated_posititions = last_positions |> Dict.put(name, Ship.current_position(name))
		Logger.info "ships after: #{inspect after_ships}"
		{:reply, :ok, %{state | ships: after_ships, last_positions: updated_posititions}}
	end

	def handle_info(:game_tick, state = %{ships: ships, last_positions: last_positions }) do
		Logger.info "tick #{length(ships)}"

		seconds = @speed

		ships_with_gravity = last_positions |> Enum.map(fn {ship, position} -> {ship, gravity_from_others(ship, position, last_positions)} end)

		updated_posititions = ships_with_gravity
			|> Enum.into(%{}, fn {ship, gravity} ->
				{ship, Ship.progress_for_time(ship, seconds, [gravity])}
			end)

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

	defp gravity_from_others(self, target = %{position: position, mass: mass}, others) do
		is_self = fn
			{name, _} -> name == self
		end

		others
      |> Enum.filter(fn {name, ship} -> ship.mass >= 500 end)
			|> Enum.reject(is_self)
			|> Enum.map(fn {_ship, position} -> position end)
			|> Enum.map(&Physics.calculate_gravitational_field(target, &1))
			|> Physics.sum_vectors
	end

	defp initialise_positions(state)do
		Logger.info "initialising positions for #{inspect state.ships}"
		positions = state.ships
			|> Enum.into(%{}, fn ship -> {ship, Ship.current_position(ship) |> Map.put(:name, ship)} end)
		Dict.put(state,:last_positions, positions)
	end

	defp push_position_updates_to_clients(updated_posititions) do
		position_update_message = updated_posititions
			|> Dict.values
			|> Enum.map(&summary_to_ship_update/1)
		Fleetbattlex.Endpoint.broadcast! "positions:updates", "update", %{positions: position_update_message}
	end

	defp detect_collisions(last_positions, updated_posititions) do
		movements = last_positions
			|> Enum.map(fn {ship, last_position} -> {last_position, Dict.get(updated_posititions , ship)} end)
			|> Enum.filter(fn
				{_,nil} -> false
				_ -> true
			end)
		movements
			|> Enum.map(fn {%{mass: size, position: start_position},%{name: name, position: end_position}} -> %{name: name, start_position: start_position, end_position: end_position, size: size} end)
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
