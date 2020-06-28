defmodule Proj42.Client do
    use GenServer
    
    @default_username_head_len 4
    @default_username_tail_len 4
    @default_password_len 10
    @default_alphabets "abcdefghijklmnopqrstuvwxyz"
    @default_numbers "0123456789"

    def start_link(args) do
        GenServer.start_link(__MODULE__, args)
    end

    def init({server_pid}) do
        state = %{
            "server_pid"            => server_pid,
            "user_id"               => 0,
            "username"              => "",
            "password"              => "",
            "num_tweets"            => 0,
            "num_retweets"          => 0,
            "followers_ids"         => [],
            "subscribed_ids"        => [],
            "connection_status"     => false,
            "origin_tweets"         => [],          # Save a list of [tweet_content, hashtags, mentions]
            "re_tweets"             => [],          # Save a list of tweet_id
            "messages"              => [],          # Save a list of messages
            "subed_query_result"    => [],          # Save a list of tweet_tuple and retweet_tuple
            "hashtag_query_result"  => [],          # Save a list of tweet_tuple and retweet_tuple
            "mention_query_result"  => []           # Save a list of tweet_tuple and retweet_tuple
        }
        {:ok, state}
    end

    # The client should have functions to send message to server to
    # register, to tweet and retweet, to subscribe, and to query. 

    #def handle_cast({:mentioned, message, message_id, usr_id}, state) do
    #    
    #end

    #def handle_cast({:content, message, message_id, usr_id}, state) do
    #    
    #end

    def register_loop(state) do
        username = generate_random_username()
        password = generate_random_password()
        register_result = GenServer.call(state["server_pid"], {:register, username, password})
        if register_result == :usrname_already_exist do
            register_loop(state)
        else
            {register_result, username, password}
        end
    end

    def generate_random_username() do
        head = Enum.reduce(1..@default_username_head_len, "", fn _i, h ->
            h <> String.at(@default_alphabets, Enum.random(0..25))
        end)
        tail = Enum.reduce(1..@default_username_tail_len, "", fn _i, t ->
            t <> String.at(@default_numbers, Enum.random(0..9))
        end)
        head <> tail
    end

    def generate_random_password() do
        Enum.reduce(1..@default_password_len, "", fn _i, p ->
            p <> String.at(@default_numbers, Enum.random(0..9))
        end)
    end
    
    # Register
    def handle_call({:register}, _from, state) do
        {user_id, username, password} = register_loop(state)
        state = Map.put(state, "user_id", user_id)
        state = Map.put(state, "username", username)
        state = Map.put(state, "password", password)
        {:reply, {user_id, username, password}, state}
    end

    # Re-tweet
    def handle_call({:retweet, tweet_id}, _from, state) do
        GenServer.cast(state["server_pid"], {:retweet, tweet_id, state["user_id"]})
        state = Map.put(state, "re_tweets", state["re_tweets"] ++ [tweet_id])
        {:reply, :ok, Map.put(state, "num_retweets", state["num_retweets"] + 1)}
    end

    # Delete account
    def handle_call({:delete}, _from, state) do
        {:reply, GenServer.call(state["server_pid"], {:delete, state["user_id"]}), %{}}
    end

    # Send Tweets
    def handle_call({:send_tweet}, _from, state) do
        tweet_content = "Client ##{state["user_id"]}'s #{state["num_tweets"] + 1}th tweet"
        hashtags = []
        mentions = []
        state = send_tweet_to_server({[tweet_content, hashtags, mentions], state})
        {:reply, :ok, Map.put(state, "num_tweets", state["num_tweets"] + 1)}
    end

    def handle_call({:send_tweet, [tweet_content, hashtags, mentions]}, _from, state) do
        state = send_tweet_to_server({[tweet_content, hashtags, mentions], state})
        {:reply, :ok, Map.put(state, "num_tweets", state["num_tweets"] + 1)}
    end

    # Go online
    def handle_call({:go_online}, _from, state) do
        login_result = GenServer.call(state["server_pid"], {:login, state["user_id"], state["password"]})
        case login_result do
            :usr_nonexist ->
                IO.puts("The username provided doesn't exist")
                {:reply, :ok, state}
            :wrong_password ->
                IO.puts("The password provided doesn't match")
                {:reply, :ok, state}
            {:ok, _message_queue} ->
                # IO.puts("Successfully logged in")
                {:reply, :ok, Map.put(state, "connection_status", true)}
            _ ->
                IO.puts("Should never reach here! Something went terrible wrong!")
                IO.puts("Got #{login_result} as login result")
                {:reply, :ok, state}
        end
    end

    # Go offline
    def handle_call({:go_offline}, _from, state) do
        # Need to tell server
        GenServer.call(state["server_pid"], {:logoff, state["user_id"]})
        {:reply, :ok, Map.put(state, "connection_status", false)}
    end

    # Get connection status
    def handle_call({:get_connection_status}, _from, state) do
        {:reply, state["connection_status"], state}
    end
    
    def handle_call({:get_state}, _from, state) do
        {:reply, state, state}
    end

    # Subscribe
    def handle_call({:subscribe, subscribed_id}, _from, state) do
        GenServer.cast(state["server_pid"], {:subscribe, state["user_id"], subscribed_id})
        {:reply, :ok, Map.put(state, "subscribed_ids", state["subscribed_ids"] ++ [subscribed_id])}
    end

    # Query
    # query_type = :query_subscribed or :query_hashtag or :query_mentioned
    def handle_call({:query, query_type, parameter}, _from, state) do
        cond do
            query_type == :query_subscribed ->
                GenServer.cast(state["server_pid"], {:query, query_type, state["user_id"], state["user_id"]})
            query_type == :query_hashtag ->
                GenServer.cast(state["server_pid"], {:query, query_type, parameter, state["user_id"]})
            query_type == :query_mentioned ->
                GenServer.cast(state["server_pid"], {:query, query_type, parameter, state["user_id"]})
        end
        {:reply, :ok, state}
    end

    def send_tweet_to_server({[tweet_content, hashtags, mentions], state}) do
        GenServer.cast(state["server_pid"], {:tweet, tweet_content, hashtags, mentions, state["user_id"]})
        Map.put(state, "origin_tweets", state["origin_tweets"] ++ [{tweet_content, hashtags, mentions}])
    end
    
    def handle_cast({:subscribed_by, follower_id, _follower_usrname}, state) do
        {:noreply, Map.put(state, "followers_ids", state["followers_ids"] ++ [follower_id])}
    end

    # Receive query result
    # query_type = :query_subscribed or :query_hashtag or :query_mentioned
    def handle_cast({:query_result, query_type, list}, state) do
        # Enum.map(tweets_list, fn tweet ->
            # tweet = [tweet_content, hashtags, mentions]
            # show_tweet(tweet)
        # end)
        cond do
            query_type == :query_subscribed ->
                {:noreply, Map.put(state, "subed_query_result", list)}
            query_type == :query_hashtag ->
                {:noreply, Map.put(state, "hashtag_query_result", list)}
            query_type == :query_mentioned ->
                {:noreply, Map.put(state, "mention_query_result", list)}
        end
    end
    
    def handle_cast({:unsubscribed, usrid}, state) do
        {:noreply, Map.update!(state, "subscribed_ids", fn x -> x -- [usrid] end)}
    end

    def handle_cast({:no_longer_follow, usrid}, state) do
        {:noreply, Map.update!(state, "followers_ids", fn x -> x -- [usrid] end)}
    end

    def handle_cast({:tweet, tweet_tuple}, state) do
        {:noreply, Map.update!(state, "messages", fn x -> x ++ [{:tweet, tweet_tuple}] end)}
    end

    def handle_cast({:retweet, retweet_tuple}, state) do
        {:noreply, Map.update!(state, "messages", fn x -> x ++ [{:retweet, retweet_tuple}] end)}
    end

    def handle_cast({:retweeted, retweeted_tuple}, state) do
        {:noreply, Map.update!(state, "messages", fn x -> x ++ [{:retweeted, retweeted_tuple}] end)}
    end

    def handle_cast({:mentioned, mentioned_tuple}, state) do
        {:noreply, Map.update!(state, "messages", fn x -> x ++ [{:mentioned, mentioned_tuple}] end)}
    end

    # Automatically receive tweets when connected
    def handle_cast({:auto_receive_message, message_queue}, state) do
        state = Enum.reduce(message_queue, state, fn m, map ->
            case elem(m, 0) do
                :subscribed_by ->
                    Map.update!(map, "followers_ids", fn x -> x ++ [elem(m, 1)] end)
                :unsubscribed ->
                    Map.update!(map, "subscribed_ids", fn x -> x -- [elem(m, 1)] end)
                :no_longer_follow ->
                    Map.update!(map, "followers_ids", fn x -> x -- [elem(m, 1)] end)
                _ ->
                    Map.update!(map, "messages", fn x -> x ++ [m] end)
            end
        end)
        {:noreply, state}
    end

    # Show a tweet received
    def show_tweet(tweet) do
        IO.inspect(tweet)
    end
end