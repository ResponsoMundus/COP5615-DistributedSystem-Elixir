[actor_num, topology, algorithm] = System.argv()

topology = if String.equivalent?(topology, "3Dtorus") do
    "torus3D"
else
    topology
end

Proj2.start(:normal, {elem(Integer.parse(actor_num), 0), String.to_atom(topology), String.to_atom(algorithm)})