defmodule Fleetbattlex.Ship do
	use GenServer
	require Logger
	alias Fleetbattlex.Massive
	alias Fleetbattlex.Physics

	def start_link(params) do
		Logger.info("starting ship #{inspect params.name}")
		ship_defaults =
			%{engine_max_thrust: 0.1, engine_burn: %{"percentage" => 0.0}, bearing: {0,-1}, dead: false }
			|> Dict.put(:tubes, %{"1" => nil, "2" => nil})
			|> Dict.put(:torpedos, generate_torpedo_ids(params.name, 4) |> Enum.into(%{},&{&1,&1}))

		ship_params = Dict.merge(ship_defaults, params)
		Logger.info("starting ship #{inspect params.name} with ship params #{inspect ship_params}")
		GenServer.start_link(__MODULE__,ship_params, name: via_name(params.name))
	end

	def init(args) do
		{:ok, args}
	end

	def progress_for_time(ship, time, forces \\ []) do
		GenServer.call(via_name(ship),{:progress_for_time,time,forces})
	end

	def current_position(ship) do
		GenServer.call(via_name(ship), {:current_position})
	end

	def start_burn(ship, burn) do
		GenServer.call(via_name(ship), {:start_burn, burn})
	end

	def get_burn(ship), do: GenServer.call(via_name(ship), {:get_burn})

	def set_bearing(ship, bearing), do: GenServer.call(via_name(ship), {:set_bearing, Fleetbattlex.Physics.normalise_vector(bearing)})
	def get_bearing(ship), do: GenServer.call(via_name(ship), {:get_bearing})

	def fire_torpedo(ship, tube_number), do: GenServer.call(via_name(ship), {:fire_torpedo, tube_number})
	def list_torpedos(ship), do: GenServer.call(via_name(ship), {:list_torpedos})
	def load_torpedo_tube(ship, tube, torpedo), do: GenServer.call(via_name(ship), {:load_torpedo_tube, tube, torpedo})

	################################################################################################################

	def handle_call({:progress_for_time, time, external_forces}, _from, state = %{massive: massive}) do
		forces = [calculate_thrust(state) | external_forces]
		updated_massive = Massive.progress_for_time(massive,time,forces)
		summary = updated_massive
			|> Map.take([:position, :mass])
			|> Map.merge(Map.take(state,[:bearing, :name, :engine_burn, :dead]))
		{:reply, summary, %{state | massive: updated_massive}}
	end

	def handle_call({:start_burn, burn}, _from, state) do
		new_state = state |> Dict.put(:engine_burn, burn)
		{:reply, :ok, new_state}
	end

	def handle_call({:get_burn}, _from, state), do: {:reply, state.engine_burn, state}

	def handle_call({:current_position}, _from, state = %{massive: massive}) do
		{:reply,  Map.take(massive,[:position, :mass]), state}
	end

	def handle_call({:set_bearing, bearing}, _from, state) do
		Logger.info "#{inspect state.name} adjusting bearing to #{inspect bearing}"
		{:reply, :ok, %{state | bearing: bearing}}
	end

	def handle_call({:get_bearing}, _from, state = %{bearing: bearing}) do
		{:reply, bearing, state}
	end

	def handle_call({:fire_torpedo,_}, _from, state = %{dead: true}), do: {:reply, {:error, :ship_dead}, state}
	def handle_call({:fire_torpedo, tube_number}, _from, state = %{tubes: tubes, name: {fleet_name, ship_name}, bearing: bearing, massive: ship_massive}) do
		case Dict.get(tubes, tube_number) do
			nil ->
				Logger.info "tired firing empty tube #{tube_number}, load one of #{inspect state.torpedos |> Dict.keys}"
				{:reply, {:error, :tube_empty}, state}
			torpedo_id ->
				Logger.info "firing tube #{tube_number}"
				torpedo_name = {fleet_name, torpedo_id}
				torpedo_position = ship_massive.position |> Physics.sum_vectors(Physics.scale_vector(bearing,40))
				torpedo_params = %{name: torpedo_name, bearing: bearing, massive: %{ship_massive | mass: 0.2, position: torpedo_position}}
				Fleetbattlex.Torpedo.start_link(torpedo_params)
				spawn_link fn -> Fleetbattlex.Game.add_piece(torpedo_name) end
				{:reply, {:ok, torpedo_name}, %{state | tubes: Dict.put(tubes, tube_number, nil)}}
		end
	end

	def handle_call({:list_torpedos}, _from, state), do: {:reply, (state.torpedos |> Dict.keys ), state}

	def handle_call({:load_torpedo_tube, tube, torpedo}, _from, state = %{torpedos: torpedos, tubes: tubes}) do
		has_tube? = tubes |> Dict.has_key?(tube)
		has_torpedo? = torpedos |> Dict.has_key?(torpedo)
		case {has_tube?, has_torpedo?} do
			{true, true} ->
				{:reply, {:ok}, %{state | tubes: Dict.put(tubes, tube, torpedo), torpedos: Dict.delete(torpedos, torpedo)}}
			_ ->
				{:reply, {:error}, state}
		end
	end

	def handle_cast({:collided, with_who}, state) do
		IO.puts "#{inspect state.name} collided with #{inspect with_who}"
		new_state = state
			|> Dict.put(:engine_burn, %{"percentage" => 0})
			|> Dict.put(:engine_max_thrust, 0)
			|> Dict.put(:dead, true)
		{:noreply, new_state}
	end


	defp via_name(name), do: {:via, :gproc, {:n, :l, name}}

	defp calculate_thrust(%{burn: %{"percentage" => 0.0}}), do: {0,0}
	defp calculate_thrust(%{bearing: bearing, engine_max_thrust: engine_max_thrust, engine_burn: %{"percentage" => percentage}}) do
		bearing |> Physics.scale_vector(engine_max_thrust * percentage)
	end

	defp generate_torpedo_ids({_fleet,ship}, length) do
		1..length |> Enum.map &"#{ship}_t#{&1}"
	end
end
