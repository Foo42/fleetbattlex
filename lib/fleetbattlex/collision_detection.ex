defmodule Fleetbattlex.Collisions do
	
	def detected?(%{start_position: start_position_a, end_position: end_position_a, size: size_a}, %{start_position: start_position_b, end_position: end_position_b, size: size_b}) do
		detected?({{start_position_a, end_position_a}, size_a}, {{start_position_b, end_position_b}, size_b})
	end

	def detected?(a, b) do
		abox = bounding_box a
		bbox = bounding_box b
		intersects? abox, bbox
	end

	def detect_all(movements) do

		movements |> Enum.map(fn 
			vector -> 
				is_self = fn %{name: other_name} -> other_name == vector.name end
				movements 
					|> Enum.reject(is_self)
					|> Enum.filter(&(detected?(&1, vector)))
					|> Enum.map(&{&1.name, vector.name})

		end ) |> List.flatten
	end

	def notify_of_collision(one, other), do: GenServer.cast(via_name(one),{:collided, other})
	defp via_name(name), do: {:via, :gproc, {:n, :l, name}}

	defp bounding_box({{{start_x, start_y},{end_x, end_y}}, size}) do
		bounds = %{top: max(start_x, end_x) + size, bottom: min(start_x, end_x) - size, left: min(start_y, end_y) - size, right: max(start_y, end_y) + size }
		{{bounds.left, bounds.top}, {bounds.right, bounds.top}, {bounds.right, bounds.bottom}, {bounds.left, bounds.bottom}}
	end

	defp inside_box?(point = {x,y}, _box = {{left, top}, _, {right, bottom}, _}) do
		result = x >= left && x <= right && y <= top && y >= bottom	
		result
	end

	defp intersects?(abox,bbox) do
		aPoints = abox |> Tuple.to_list
		bPoints = bbox |> Tuple.to_list

		aPoints |> Enum.any?(&inside_box?(&1, bbox)) || bPoints |> Enum.any?(&inside_box?(&1,abox))
	end
end
