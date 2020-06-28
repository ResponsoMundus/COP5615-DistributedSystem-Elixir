[from, to] = System.argv
actor_num = 100
Proj1.start_link([actor_num, elem(Integer.parse(from), 0), elem(Integer.parse(to), 0), nil])
Proj1.wait()