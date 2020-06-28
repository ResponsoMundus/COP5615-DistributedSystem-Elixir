defmodule Proj4Test do
    use ExUnit.Case, async: false
    doctest Proj4

    @default_user_num 10

    setup_all do
        {:ok, _pid} = Supervisor.start_link(
            [
                %{
                    id: Proj4.ActorSupervisor,
                    start: {Proj4.ActorSupervisor, :start_link, [:ok]}
                }
            ],
            [
                strategy: :one_for_all
            ]
        )

        server_pid = Proj4.ActorSupervisor.start_server()
        client_id_list = Proj4.ActorSupervisor.start_clients(@default_user_num, server_pid)
        {:ok, %{"server" => server_pid, "client_list" => client_id_list}}
    end

    test "register_test", state do
        {server_pid, client_pid_list} = {state["server"], state["client_list"]}
        client_map = Enum.reduce(client_pid_list, %{}, fn client_pid, map -> 
            {user_id, username, password} = GenServer.call(client_pid, {:register})
            Map.put(map, user_id, {username, password})
        end)
        server_state = GenServer.call(server_pid, {:get_state})
        assert(client_map == server_state["usr"])
    end

    test "login_test", state do
        {server_pid, client_pid_list} = {state["server"], state["client_list"]}
        Enum.map(client_pid_list, fn client_pid -> 
            GenServer.call(client_pid, {:go_online})
        end)
        Enum.map(client_pid_list, fn id -> 
            client_state = GenServer.call(id, {:get_state})
            assert(client_state["connection_status"])
        end)
        server_state = GenServer.call(server_pid, {:get_state})
        Enum.map(Map.values(server_state["usrstatus"]), fn x ->
            assert(x)
        end)
    end

    test "logout_test", state do
        {server_pid, client_pid_list} = {state["server"], state["client_list"]}
        Enum.map(client_pid_list, fn client_pid -> 
            GenServer.call(client_pid, {:go_offline})
        end)
        Enum.map(client_pid_list, fn id -> 
            client_state = GenServer.call(id, {:get_state})
            assert(not client_state["connection_status"])
        end)
        server_state = GenServer.call(server_pid, {:get_state})
        Enum.map(Map.values(server_state["usrstatus"]), fn x ->
            assert(x == nil)
        end)
        Enum.map(client_pid_list, fn client_pid -> 
            GenServer.call(client_pid, {:go_online})
        end)
    end

    test "subscribe_test", state do
        {server_pid, client_pid_list} = {state["server"], state["client_list"]}
        [subscribed_user | subscribers] = client_pid_list
        Enum.map(subscribers, fn subscriber -> 
            GenServer.call(subscriber, {:subscribe, 0})
        end)
        server_state = GenServer.call(server_pid, {:get_state})
        # Check the status of the last 9 clients(subscribers)
        Enum.map(0..(length(subscribers) - 1), fn index -> 
            pid = Enum.at(subscribers, index)
            client_state = GenServer.call(pid, {:get_state})
            assert((client_state["subscribed_ids"] == [0]) and (server_state["subscribe"][index + 1] == [0]))
        end)
        # Check the status of first client(subscribed_user)
        subscribed_user_state = GenServer.call(subscribed_user, {:get_state})
        assert(subscribed_user_state["followers_ids"] == server_state["followers"][0])
    end

    test "tweet_test_1", state do
        {server_pid, client_pid_list} = {state["server"], state["client_list"]}
        [subscribed_user | subscribers] = client_pid_list
        GenServer.call(subscribed_user, {:send_tweet})
        server_state = GenServer.call(server_pid, {:get_state})
        assert(length(Map.to_list(server_state["tweet"])) == 1)
        Enum.map(subscribers, fn pid -> 
            client_state = GenServer.call(pid, {:get_state})
            assert(length(client_state["messages"]) == 1)
        end)
        subscribed_user_state = GenServer.call(subscribed_user, {:get_state})
        assert(length(subscribed_user_state["origin_tweets"]) == 1)
    end

    test "tweet_test_2", state do
        {server_pid, client_pid_list} = {state["server"], state["client_list"]}
        [subscribed_user | subscribers] = client_pid_list
        tweet_info = ["Client #0's 2nd tweet", ["test"], [1, 2, 3, 4, 5, 6, 7, 8, 9]]
        GenServer.call(subscribed_user, {:send_tweet, tweet_info})
        server_state = GenServer.call(server_pid, {:get_state})
        assert(length(Map.to_list(server_state["tweet"])) == 2)
        assert(length(Map.to_list(server_state["hashtag"])) == 1)
        assert(length(Map.to_list(server_state["mention"])) == 2)
        Enum.map(subscribers, fn pid -> 
            client_state = GenServer.call(pid, {:get_state})
            assert(length(client_state["messages"]) == 3)
        end)
        subscribed_user_state = GenServer.call(subscribed_user, {:get_state})
        assert(length(subscribed_user_state["origin_tweets"]) == 2)
    end

    test "retweet_test_1", state do
        {server_pid, client_pid_list} = {state["server"], state["client_list"]}
        [subscribed_user | subscribers] = client_pid_list
        GenServer.call(subscribed_user, {:retweet, 1})
        server_state = GenServer.call(server_pid, {:get_state})
        assert(length(Map.to_list(server_state["tweet"])) == 3)
        assert(length(Map.to_list(server_state["hashtag"])) == 1)
        assert(length(Map.to_list(server_state["mention"])) == 3)
        Enum.map(subscribers, fn pid -> 
            client_state = GenServer.call(pid, {:get_state})
            assert(length(client_state["messages"]) == 4)
        end)
        subscribed_user_state = GenServer.call(subscribed_user, {:get_state})
        assert(length(subscribed_user_state["origin_tweets"]) == 2)
        assert(length(subscribed_user_state["messages"]) == 1)
        assert(length(subscribed_user_state["re_tweets"]) == 1)
        # IO.inspect server_state
    end

    test "retweet_test_2", state do
        {server_pid, client_pid_list} = {state["server"], state["client_list"]}
        [subscribed_user | subscribers] = client_pid_list
        Enum.map(subscribers, fn subscriber ->
            GenServer.call(subscriber, {:retweet, 1})
        end)
        server_state = GenServer.call(server_pid, {:get_state})
        assert(length(Map.to_list(server_state["tweet"])) == 12)
        assert(length(Map.to_list(server_state["hashtag"])) == 1)
        assert(length(Map.to_list(server_state["mention"])) == 12)
        Enum.map(subscribers, fn pid -> 
            client_state = GenServer.call(pid, {:get_state})
            assert(length(client_state["re_tweets"]) == 1)
        end)
        subscribed_user_state = GenServer.call(subscribed_user, {:get_state})
        assert(length(subscribed_user_state["messages"]) == 10)
        #IO.inspect server_state
    end

    test "logout_message_test_1", state do
        {_server_pid, client_pid_list} = {state["server"], state["client_list"]}
        [subscribed_user | subscribers] = client_pid_list
        Enum.map(subscribers, fn client_pid -> 
            GenServer.call(client_pid, {:go_offline})
        end)
        GenServer.call(subscribed_user, {:send_tweet})
        Enum.map(subscribers, fn client_pid -> 
            GenServer.call(client_pid, {:go_online})
            client_state = GenServer.call(client_pid, {:get_state})
            assert(length(client_state["messages"]) == 5)
        end)
    end

    test "logout_message_test_2", state do
        {_server_pid, client_pid_list} = {state["server"], state["client_list"]}
        [subscribed_user | subscribers] = client_pid_list
        Enum.map(subscribers, fn client_pid -> 
            GenServer.call(client_pid, {:go_offline})
        end)
        GenServer.call(subscribed_user, {:retweet, 1})
        Enum.map(subscribers, fn client_pid -> 
            GenServer.call(client_pid, {:go_online})
            client_state = GenServer.call(client_pid, {:get_state})
            assert(length(client_state["messages"]) == 6)
        end)
    end

    test "query_subscribed_test", state do
        {server_pid, client_pid_list} = {state["server"], state["client_list"]}
        client = Enum.at(client_pid_list, 1)
        GenServer.call(client, {:query, :query_subscribed, nil})
        GenServer.call(server_pid, {:check}) # Test the server to tell the query has finished
        client_state = GenServer.call(client, {:get_state})
        # IO.inspect client_state["subed_query_result"]
        assert(length(client_state["subed_query_result"]) == 5)
    end

    test "query_mentioned_test", state do
        {server_pid, client_pid_list} = {state["server"], state["client_list"]}
        client = Enum.at(client_pid_list, 1)
        GenServer.call(client, {:query, :query_mentioned, 3})
        GenServer.call(server_pid, {:check}) # Test the server to tell the query has finished
        client_state = GenServer.call(client, {:get_state})
        # IO.inspect client_state["mention_query_result"]
        assert(length(client_state["mention_query_result"]) == 1)
    end

    test "query_hashtag_test", state do
        {server_pid, client_pid_list} = {state["server"], state["client_list"]}
        client = Enum.at(client_pid_list, 1)
        GenServer.call(client, {:query, :query_hashtag, "test"})
        GenServer.call(server_pid, {:check}) # Test the server to tell the query has finished
        client_state = GenServer.call(client, {:get_state})
        # IO.inspect client_state["hashtag_query_result"]
        assert(length(client_state["hashtag_query_result"]) == 12)
    end

    test "delete_test_1", state do
        {server_pid, client_pid_list} = {state["server"], state["client_list"]}
        [subscribed_user | subscribers] = client_pid_list
        client = hd(subscribers)
        GenServer.call(client, {:delete})
        server_state = GenServer.call(server_pid, {:get_state})
        # IO.inspect server_state
        assert(length(Map.to_list(server_state["usr"])) == 9)
        assert(length(Map.to_list(server_state["usrstatus"])) == 9)
        assert(length(server_state["followers"][0]) == 8)
        assert(length(Map.to_list(server_state["tweet"])) == 13)
        subscribed_user_state = GenServer.call(subscribed_user, {:get_state})
        assert(length(subscribed_user_state["followers_ids"]) == 8)
        # IO.inspect subscribed_user_state
    end

    test "delete_test_2", state do
        {server_pid, client_pid_list} = {state["server"], state["client_list"]}
        client = hd(client_pid_list)
        GenServer.call(client, {:delete})
        server_state = GenServer.call(server_pid, {:get_state})
        # IO.inspect server_state
        assert(length(Map.to_list(server_state["usr"])) == 8)
        assert(length(Map.to_list(server_state["usrstatus"])) == 8)
        Enum.map(2..9, fn x ->
            assert(length(server_state["followers"][x]) == 0)
        end)
        assert(length(Map.to_list(server_state["tweet"])) == 8)
        Enum.map(tl(tl(client_pid_list)), fn pid ->
            client_state = GenServer.call(pid, {:get_state})
            assert(length(client_state["subscribed_ids"]) == 0)
        end)
    end
end
