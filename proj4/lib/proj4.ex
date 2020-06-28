defmodule Proj4 do
    def simulate(num_user, num_msg, debug \\ false) do
        {:ok, _pid} = Supervisor.start_link(
            [
                %{
                    id: Proj4.ActorSupervisor,
                    start: {Proj4.ActorSupervisor, :start_link, [:ok]}
                }
            ],
            [
                strategy: :one_for_all,
                name: Proj4.Supervisor
            ]
        )

        server_pid = Proj4.ActorSupervisor.start_server()
        client_pid_list = Proj4.ActorSupervisor.start_clients(num_user, server_pid)
        client_id_list = Enum.map(0..(num_user - 1), fn x -> x end)
        num_sub = Kernel.trunc(:math.sqrt(num_user))
        
        start_time = :os.system_time(:millisecond)
        Enum.map(client_pid_list, fn client_pid ->
            GenServer.call(client_pid, {:register})
        end)
        time_1 = :os.system_time(:millisecond) - start_time
        if debug do
            IO.puts("#{time_1}ms to register all users")
        end

        start_time = :os.system_time(:millisecond)
        Enum.map(client_pid_list, fn client_pid ->
            GenServer.call(client_pid, {:go_online})
        end)
        time_2 = :os.system_time(:millisecond) - start_time
        if debug do
            IO.puts("#{time_2}ms to login all users")
        end

        start_time = :os.system_time(:millisecond)
        Enum.map(client_id_list, fn id ->
            pid = Enum.at(client_pid_list, id)
            Enum.reduce(1..num_sub, client_id_list -- [id], fn _, list ->
                random_usrid = Enum.random(list)
                GenServer.call(pid, {:subscribe, random_usrid})
                list -- [random_usrid]
            end)
        end)
        time_3 = :os.system_time(:millisecond) - start_time
        if debug do
            IO.puts("#{time_3}ms for every user to subscribe #{num_sub} other random users")
        end

        start_time = :os.system_time(:millisecond)
        Enum.map(client_pid_list, fn pid ->
            Enum.map(1..num_msg, fn _ ->
                GenServer.call(pid, {:send_tweet})
            end)
        end)
        GenServer.call(server_pid, {:check}, :infinity)
        time_4 = :os.system_time(:millisecond) - start_time
        if debug do
            IO.puts("#{time_4}ms for server to deal with all the tweets")
        end

        start_time = :os.system_time(:millisecond)
        Enum.map(1..10, fn _ ->
            GenServer.call(Enum.random(client_pid_list), {:send_tweet})
        end)
        GenServer.call(server_pid, {:check}, :infinity)
        time_5 = (:os.system_time(:millisecond) - start_time) / 10
        if debug do
            IO.puts("#{time_5}ms average for server to deal with one tweet after #{num_user * num_msg} msgs")
        end

        new_client_pid_list = Proj4.ActorSupervisor.start_clients(10, server_pid)

        start_time = :os.system_time(:millisecond)
        Enum.map(new_client_pid_list, fn client_pid ->
            GenServer.call(client_pid, {:register})
        end)
        time_6 = (:os.system_time(:millisecond) - start_time) / 10
        if debug do
            IO.puts("#{time_6}ms average for server to deal with one register after #{num_user * num_msg} msgs")
        end

        start_time = :os.system_time(:millisecond)
        Enum.map(new_client_pid_list, fn client_pid ->
            GenServer.call(client_pid, {:go_online})
        end)
        time_7 = (:os.system_time(:millisecond) - start_time) / 10
        if debug do
            IO.puts("#{time_7}ms average for server to deal with one login after #{num_user * num_msg} msgs")
        end

        start_time = :os.system_time(:millisecond)
        Enum.map(num_user..(num_user + 9), fn id ->
            pid = Enum.at(new_client_pid_list, id - num_user)
            Enum.reduce(1..10, client_id_list, fn _, list ->
                random_usrid = Enum.random(list)
                GenServer.call(pid, {:subscribe, random_usrid})
                list -- [random_usrid]
            end)
        end)
        time_8 = (:os.system_time(:millisecond) - start_time) / 100
        if debug do
            IO.puts("#{time_8}ms average for server to deal with one sub after #{num_user * num_msg} msgs")
        end

        start_time = :os.system_time(:millisecond)
        Enum.map(client_pid_list ++ new_client_pid_list, fn client_pid ->
            GenServer.call(client_pid, {:go_offline})
        end)
        time_9 = (:os.system_time(:millisecond) - start_time) / (num_user + 10)
        if debug do
            IO.puts("#{time_9}ms to logoff all users")
        end

        Supervisor.stop(Proj4.Supervisor)
        {time_1, time_2, time_3, time_4, time_5, time_6, time_7, time_8, time_9}
    end
end
