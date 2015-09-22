defmodule Fleetbattlex.Ship do
	use GenServer
	require Logger
	alias Fleetbattlex.Massive

	def start_link(params) do
		ship_defaults = %{engine_max_thrust: 0.1, engine_burn: %{"percentage" => 0.0}}
		ship_params = Dict.merge(ship_defaults, params)
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

	def handle_call({:progress_for_time, time, external_forces}, _from, state) do
		%{massive: massive, engine_max_thrust: engine_max_thrust, engine_burn: burn} = state;
		forces = [calculate_thrust(engine_max_thrust, time, burn) | external_forces]
		updated_massive = Massive.progress_for_time(massive,time,forces)
		{:reply, Map.take(updated_massive,[:position, :mass]), %{state | massive: updated_massive}}
	end

	def handle_call({:start_burn, burn}, _from, state) do
		new_state = state |> Dict.put(:engine_burn, burn)
		{:reply, :ok, new_state}
	end

	def handle_call({:get_burn}, _from, state), do: {:reply, state.engine_burn, state}

	def handle_call({:current_position}, _from, state = %{massive: massive}) do
		{:reply,  Map.take(massive,[:position, :mass]), state}
	end

	defp via_name(name), do: {:via, :gproc, {:n, :l, name}}

	defp calculate_thrust(_engine_max_thrust, time, %{"percentage" => 0.0}), do: {0,0}
	defp calculate_thrust(engine_max_thrust, time, %{"percentage" => percentage}), do: {0, percentage * engine_max_thrust * time}
end
