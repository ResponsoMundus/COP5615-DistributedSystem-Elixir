defmodule Proj2.Topology do
    """
        This function is supposed to generate the topology
        of actors based on actor's pid (you can change it into
        consecutive numbers representing actors) and call/cast
        the actor's with {:update_neighbor, neighbor_list} to
        tell every actor its neighbors

        PS: Feel free to add new functions if you need
    """    
    def generate_topology(actor_pid_list, :full) do
        Enum.map(actor_pid_list, fn cur_actor -> actor_pid_list -- [cur_actor] end)
    end

    def generate_topology(actor_pid_list, :line) do
        actor_pid_tuple = List.to_tuple(actor_pid_list)
        Enum.map(0..(length(actor_pid_list) - 1), fn x -> 
            cond do
                x == 0 && x == length(actor_pid_list) - 1 -> []
                x == 0 -> [elem(actor_pid_tuple, x + 1)]
                x == length(actor_pid_list) - 1 -> [elem(actor_pid_tuple, x - 1)]
                true -> [elem(actor_pid_tuple, x - 1), elem(actor_pid_tuple, x + 1)]
            end
        end)
    end

    def generate_topology(actor_pid_list, :rand2D) do
        position_list = Enum.map(1..length(actor_pid_list), fn _ -> [Enum.random(0..1000)/1000, Enum.random(0..1000)/1000] end)
        neighbor_list = Enum.map(position_list, fn pos -> 
            Enum.reduce(0..(length(actor_pid_list) - 1), [], fn pair_index, acc -> 
                pair_pos = Enum.at(position_list, pair_index)
                cond do
                    (:math.pow(Enum.at(pair_pos, 0) - Enum.at(pos, 0), 2) + :math.pow(Enum.at(pair_pos, 1) - Enum.at(pos, 1), 2) <= 0.1) -> [Enum.at(actor_pid_list, pair_index) | acc]
                    true -> acc
                end
            end)
        end)
        Enum.map(0..(length(actor_pid_list) - 1), fn x -> Enum.at(neighbor_list, x) -- [Enum.at(actor_pid_list, x)] end)
    end

    def generate_topology(actor_pid_list, :torus3D) do
        line_num = trunc(:math.pow(length(actor_pid_list), 1/3))
        layer_num = line_num * line_num
        last_point_layer_index = trunc((length(actor_pid_list) - 1) / layer_num)
        last_point_in_layer_index = rem(length(actor_pid_list) - 1, layer_num)
        last_point_line_index = trunc(rem(length(actor_pid_list) - 1, layer_num) / line_num)
        last_point_in_line_index = rem(rem(length(actor_pid_list) - 1, layer_num), line_num)
        Enum.map(0..(length(actor_pid_list) - 1), fn index -> 
            layer_index = trunc(index / layer_num)
            in_layer_index = rem(index, layer_num)
            line_index = trunc(in_layer_index / line_num)
            in_line_index = rem(in_layer_index, line_num)
            neighbor_list = if (index + 1 < length(actor_pid_list) && in_line_index + 1 < line_num) do [Enum.at(actor_pid_list, index + 1)] 
                else (if in_line_index != 0 do [Enum.at(actor_pid_list, layer_index * layer_num + line_index * line_num)] else [] end) end
            neighbor_list = neighbor_list ++ if in_line_index != 0 do [Enum.at(actor_pid_list, index - 1)]
                else (if index == length(actor_pid_list) - 1 || line_num == 1 do [] else [Enum.at(actor_pid_list, min(length(actor_pid_list) - 1, index + line_num - 1))] end) end
            neighbor_list = neighbor_list ++ if line_index != line_num - 1 && index + line_num < length(actor_pid_list) do [Enum.at(actor_pid_list, index + line_num)]
                else (if line_index == 0 do [] else [Enum.at(actor_pid_list, index - line_index * line_num)] end) end
            neighbor_list = neighbor_list ++ if line_index != 0 do [Enum.at(actor_pid_list, index - line_num)]
                else (if line_num == 1 || index + line_num >= length(actor_pid_list) do [] 
                    else [Enum.at(actor_pid_list, (if index + (line_num - 1) * line_num < length(actor_pid_list) do index + (line_num - 1) * line_num 
                        else (if last_point_in_line_index >= in_line_index do index + line_num * last_point_line_index else index + line_num * (last_point_line_index - 1) end) end))] end) end
            neighbor_list = neighbor_list ++ if index + layer_num < length(actor_pid_list) do [Enum.at(actor_pid_list, index + layer_num)]
                else (if layer_index == 0 do [] else [Enum.at(actor_pid_list, in_layer_index)] end) end
            neighbor_list ++ if layer_index != 0 do [Enum.at(actor_pid_list, index - layer_num)]
                else (if index + layer_num >= length(actor_pid_list) do [] 
                    else (if last_point_in_layer_index >= in_layer_index do [Enum.at(actor_pid_list, index + last_point_layer_index * layer_num)] 
                        else [Enum.at(actor_pid_list, index + (last_point_layer_index - 1) * layer_num)] end) end) end
        end)
    end

    def generate_topology(actor_pid_list, :honeycomb) do
        line_num = max(2,  trunc(:math.pow(length(actor_pid_list), 0.5) / 2) * 2)
        Enum.map(0..(length(actor_pid_list) - 1), fn index -> 
            index_in_2_lines = rem(index, line_num * 2)
            if (index_in_2_lines < line_num && rem(index_in_2_lines, 2) == 1) || (index_in_2_lines >= line_num && rem(index_in_2_lines, 2) == 0) do
                cur_list = if index_in_2_lines == line_num do [] else [Enum.at(actor_pid_list, index - 1)] end
                cur_list = cur_list ++ if index + line_num < length(actor_pid_list) do [Enum.at(actor_pid_list, index + line_num)] else [] end
                cur_list ++ if index - line_num >= 0 do [Enum.at(actor_pid_list, index - line_num)] else [] end
            else
                cur_list = if index_in_2_lines == 2 * line_num - 1 || index == length(actor_pid_list) - 1 do [] else [Enum.at(actor_pid_list, index + 1)] end
                cur_list = cur_list ++ if index + line_num < length(actor_pid_list) do [Enum.at(actor_pid_list, index + line_num)] else [] end
                cur_list ++ if index - line_num >= 0 do [Enum.at(actor_pid_list, index - line_num)] else [] end
            end
        end)
    end

    def generate_topology(actor_pid_list, :randhoneycomb) do
        neighbor_list = generate_topology(actor_pid_list, :honeycomb)

        neighbor_index_map = Enum.reduce(0..(length(actor_pid_list) - 1), %{}, fn index, map -> 
            Map.put(map, Enum.at(actor_pid_list, index), index)
        end)
        
        empty_random_neighbor_list = Enum.map(1..length(actor_pid_list), fn _ -> 0 end)
        remained_pid_list = actor_pid_list

        [random_neighbor_list, []] = Enum.reduce(0..(length(actor_pid_list) - 1), [empty_random_neighbor_list, remained_pid_list], fn index, [ernl, rpl] ->
            cond do
                Enum.at(ernl, index) != 0 ->
                    [ernl, rpl]
                Enum.at(ernl, index) == 0 ->
                    rpl = rpl -- [Enum.at(actor_pid_list, index)]
                    if length(rpl) == 0 do
                        [ernl, rpl]
                    else
                        random_neighbor_index = Enum.random(0..(length(rpl) - 1))
                        random_neighbor = Enum.at(rpl, random_neighbor_index)
                        ernl = List.replace_at(ernl, index, random_neighbor)
                        ernl = List.replace_at(ernl, Map.get(neighbor_index_map, random_neighbor), Enum.at(actor_pid_list, index))
                        [ernl, rpl -- [random_neighbor]]
                    end
            end
        end)

        Enum.map(0..(length(actor_pid_list) - 1), fn index -> 
            if Enum.at(random_neighbor_list, index) != 0 do
                tmp_list = Enum.at(neighbor_list, index) -- [Enum.at(random_neighbor_list, index)]
				tmp_list ++ [Enum.at(random_neighbor_list, index)]
            else
                Enum.at(neighbor_list, index)
            end
        end)
    end

end