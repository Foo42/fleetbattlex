defmodule Fleetbattlex.Torpedo do
	use GenServer
	require Logger
	alias Fleetbattlex.Massive
	alias Fleetbattlex.Physics

	def start_link(params) do
		torpedo_defaults = %{engine_max_thrust: 0.1, engine_burn: %{"percentage" => 50.0}, bearing: {0,-1}, dead: false}
		torpedo_params = Dict.merge(torpedo_defaults, params)
		GenServer.start_link(__MODULE__,torpedo_params, name: via_name(params.name))
	end

	def init(args) do
		{:ok, args}
	end

	def progress_for_time(name, time, forces \\ []) do
		GenServer.call(via_name(name),{:progress_for_time,time,forces})
	end

	def current_position(name) do
		GenServer.call(via_name(name), {:current_position})
	end

	def start_burn(name, burn) do
		GenServer.call(via_name(name), {:start_burn, burn})
	end

	def get_burn(name), do: GenServer.call(via_name(name), {:get_burn})

	def set_bearing(name, bearing), do: GenServer.call(via_name(name), {:set_bearing, Fleetbattlex.Physics.normalise_vector(bearing)})
	def get_bearing(name), do: GenServer.call(via_name(name), {:get_bearing})

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

	def handle_cast({:collided, with_who}, state) do
		IO.puts "#{inspect state.name} collided with #{inspect with_who}"
		explode()
		new_state = state
			|> Dict.put(:engine_burn, %{"percentage" => 0})
			|> Dict.put(:engine_max_thrust, 0)
			|> Dict.put(:dead, true)
		{:noreply, new_state}
	end

	defp via_name(name), do: {:via, :gproc, {:n, :l, name}}

	defp explode(), do: Logger.info "Torpedo exploded"

	defp calculate_thrust(%{burn: %{"percentage" => 0.0}}), do: {0,0}
	defp calculate_thrust(%{bearing: bearing, engine_max_thrust: engine_max_thrust, engine_burn: %{"percentage" => percentage}}) do
		bearing |> Physics.scale_vector(engine_max_thrust * percentage)
	end
end
