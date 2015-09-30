defmodule Fleetbattlex.CollisionDetection do
	def detected?(a, b) do
		abox = bounding_box a
		bbox = bounding_box b
		intersects? abox, bbox
	end

	def bounding_box({{{start_x, start_y},{end_x, end_y}}, size}) do
		bounds = %{top: max(start_x, end_x) + size, bottom: min(start_x, end_x) - size, left: min(start_y, end_y) - size, right: max(start_y, end_y) + size }
		{{bounds.left, bounds.top}, {bounds.right, bounds.top}, {bounds.right, bounds.bottom}, {bounds.left, bounds.bottom}}
	end

	def inside_box?(point = {x,y}, _box = {{left, top}, _, {right, bottom}, _}) do
		result = x >= left && x <= right && y <= top && y >= bottom	
		result
	end

	def intersects?(abox,bbox) do
		aPoints = abox |> Tuple.to_list
		bPoints = bbox |> Tuple.to_list

		aPoints |> Enum.any?(&inside_box?(&1, bbox)) || bPoints |> Enum.any?(&inside_box?(&1,abox))
	end
end
