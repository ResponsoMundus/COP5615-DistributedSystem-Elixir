[topology, algorithm] = System.argv()

topology = if String.equivalent?(topology, "3Dtorus") do
    "torus3D"
else
    topology
end

IO.puts "500 Actors"
Proj2.start(:normal, {500, String.to_atom(topology), String.to_atom(algorithm)})
IO.puts "\n1000 Actors"
Proj2.start(:normal, {1000, String.to_atom(topology), String.to_atom(algorithm)})
IO.puts "\n1500 Actors"
Proj2.start(:normal, {1500, String.to_atom(topology), String.to_atom(algorithm)})
IO.puts "\n2000 Actors"
Proj2.start(:normal, {2000, String.to_atom(topology), String.to_atom(algorithm)})
IO.puts "\n2500 Actors"
Proj2.start(:normal, {2500, String.to_atom(topology), String.to_atom(algorithm)})
IO.puts "\n3000 Actors"
Proj2.start(:normal, {3000, String.to_atom(topology), String.to_atom(algorithm)})
IO.puts "\n3500 Actors"
Proj2.start(:normal, {3500, String.to_atom(topology), String.to_atom(algorithm)})
IO.puts "\n4000 Actors"
Proj2.start(:normal, {4000, String.to_atom(topology), String.to_atom(algorithm)})
IO.puts "\n4500 Actors"
Proj2.start(:normal, {4500, String.to_atom(topology), String.to_atom(algorithm)})
IO.puts "\n5000 Actors"
Proj2.start(:normal, {5000, String.to_atom(topology), String.to_atom(algorithm)})
#Proj2.wait()