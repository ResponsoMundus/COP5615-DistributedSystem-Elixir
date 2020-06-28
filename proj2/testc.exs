[topology, algorithm] = System.argv()

topology = if String.equivalent?(topology, "3Dtorus") do
    "torus3D"
else
    topology
end

IO.puts "100 Actors"
Proj2.start(:normal, {100, String.to_atom(topology), String.to_atom(algorithm)})
IO.puts "\n200 Actors"
Proj2.start(:normal, {200, String.to_atom(topology), String.to_atom(algorithm)})
IO.puts "\n300 Actors"
Proj2.start(:normal, {300, String.to_atom(topology), String.to_atom(algorithm)})
IO.puts "\n400 Actors"
Proj2.start(:normal, {400, String.to_atom(topology), String.to_atom(algorithm)})
IO.puts "\n500 Actors"
Proj2.start(:normal, {500, String.to_atom(topology), String.to_atom(algorithm)})
IO.puts "\n600 Actors"
Proj2.start(:normal, {600, String.to_atom(topology), String.to_atom(algorithm)})
IO.puts "\n700 Actors"
Proj2.start(:normal, {700, String.to_atom(topology), String.to_atom(algorithm)})
IO.puts "\n800 Actors"
Proj2.start(:normal, {800, String.to_atom(topology), String.to_atom(algorithm)})
IO.puts "\n900 Actors"
Proj2.start(:normal, {900, String.to_atom(topology), String.to_atom(algorithm)})
IO.puts "\n1000 Actors"
Proj2.start(:normal, {1000, String.to_atom(topology), String.to_atom(algorithm)})
#Proj2.wait()