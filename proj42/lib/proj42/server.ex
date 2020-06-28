defmodule Proj42.Server do
    use GenServer
    
    def start_link(args) do
        GenServer.start_link(__MODULE__, args, name: __MODULE__)
    end

    def init(_args) do
        {
            :ok,
            %{
                "usr_num" => 0,
                "tweet_num" => 0,

                "usr" => %{},           # key is usrid and value is tuples of usrname, passwords and id
                "usrstatus" => %{},     # key is usrid and value is pid if the usr is online and nil if the usr is offline
                "subscribe" => %{},     # key is usrid and value is list of usrids that subscrible to the usr
                "followers" => %{},     # key is usrid and value is list of usrids that are subscribled to the usr
                "tweet" => %{},         # key is tweet_id and value is a tuple in form of {:original, content, usrid} or {:retweet, tweet_id, usrid}
                "mention" => %{},       # key is tweet_id and value is list of usrids that are mentioned
                "hashtag" => %{},       # key is hashtag and value is list of tweet_id that is under the hashtag
                "tweet_hashtag" => %{}, # key is tweet_id and value is list of hashtags that the tweet is under
                "usr_tweet" => %{},     # key is usrid and value is list of tweet_id that tweeted from usr
                "usr_mention" => %{},   # key is usrid and value is list of tweet_id that tweeted mentions the usr
                "message_queue" => %{}  # key is usrid and value is a list of tuples that stores the messages for the usr when the usr is offline
            }
        }
    end
    
    def handle_call({:get_state}, _from, state) do
        {:reply, state, state}
    end

    def handle_call({:check}, _from, state) do
        {:reply, :ok, state}
    end

    # Register user with usrname and password, generate a uid for user
    # Return the usr_id to the user
    def handle_call({:register, usrname, password}, _from, state) do
        if usrname in Enum.map(Map.values(state["usr"]), fn x -> elem(x, 0) end) do
            IO.puts("Usrname: #{usrname} exist")
            {:reply, :usrname_already_exist, state}
        else
            usrid = state["usr_num"]
            state = Map.update!(state, "usr_num", fn x -> x + 1 end)
            state = Map.update!(state, "usr", fn x ->
                Map.put(x, usrid, {usrname, password, usrid})
            end)
            state = Map.update!(state, "usrstatus", fn x ->
                Map.put(x, usrid, nil)
            end)
            state = Map.update!(state, "subscribe", fn x ->
                Map.put(x, usrid, [])
            end)
            state = Map.update!(state, "followers", fn x ->
                Map.put(x, usrid, [])
            end)
            state = Map.update!(state, "message_queue", fn x ->
                Map.put(x, usrid, [])
            end)
            state = Map.update!(state, "usr_tweet", fn x ->
                Map.put(x, usrid, [])
            end)
            state = Map.update!(state, "usr_mention", fn x ->
                Map.put(x, usrid, [])
            end)
            {:reply, usrid, state}
        end
    end

    def handle_call({:delete, usrid}, _from, state) do
        if usrid not in Map.keys(state["usr"]) do
            {:reply, :usrid_not_found, state}
        else
            subscribe_list = state["subscribe"][usrid]
            followers_list = state["followers"][usrid]
            mentioned_list = state["usr_mention"][usrid]
            tweet_list = state["usr_tweet"][usrid]

            state = Enum.reduce(subscribe_list, state, fn x, map ->
                map = send_or_save({:no_longer_follow, usrid}, x, map)
                Map.update!(map, "followers", fn y ->
                    Map.update!(y, x, fn z ->
                        z -- [usrid]
                    end)
                end)
            end)
            state = Enum.reduce(followers_list, state, fn x, map ->
                send_or_save({:unsubscribed, usrid}, x, map)
            end)
            state = Enum.reduce(mentioned_list, state, fn x, map ->
                Map.update!(map, "mention", fn y ->
                    Map.update!(y, x, fn z ->
                        z -- [usrid]
                    end)
                end)
            end)
            state = Enum.reduce(tweet_list, state, fn x, map ->
                map = Map.update!(map, "tweet", fn y ->
                    Map.delete(y, x)
                end)
                map = Map.update!(map, "mention", fn y ->
                    Map.delete(y, x)
                end)
                Map.update!(map, "tweet_hashtag", fn y ->
                    Map.delete(y, x)
                end)
            end)
            state = Map.update!(state, "usr", fn x ->
                Map.delete(x, usrid)
            end)
            state = Map.update!(state, "usrstatus", fn x ->
                Map.delete(x, usrid)
            end)
            state = Map.update!(state, "usrstatus", fn x ->
                Map.delete(x, usrid)
            end)
            state = Map.update!(state, "subscribe", fn x ->
                Map.delete(x, usrid)
            end)
            state = Map.update!(state, "followers", fn x ->
                Map.delete(x, usrid)
            end)
            state = Map.update!(state, "usr_tweet", fn x ->
                Map.delete(x, usrid)
            end)
            state = Map.update!(state, "usr_mention", fn x ->
                Map.delete(x, usrid)
            end)
            state = Map.update!(state, "message_queue", fn x ->
                Map.delete(x, usrid)
            end)

            {:reply, :ok, state}
        end
    end

    # Log in user with usrid and password
    def handle_call({:login, usrid, password}, from, state) do
        if usrid not in Map.keys(state["usr"]) do
            {:reply, :usr_nonexist, state}
        else
            if password != elem(state["usr"][usrid], 1) do
                {:reply, :wrong_password, state}
            else
                state = Map.update!(state, "usrstatus", fn x ->
                    Map.update!(x, usrid, fn _ ->
                        elem(from, 0)
                    end)
                end)
                message_queue = state["message_queue"][usrid]
                state = Map.update!(state, "message_queue", fn x ->
                    Map.put(x, usrid, [])
                end)
                usrs = state["usr"]
                usrinfo = {usrid, elem(usrs[usrid], 0)}
                followers = state["followers"][usrid]
                followers = Enum.reduce(followers, [], fn x, list ->
                    list ++ [{x, elem(usrs[x], 0)}]
                end)
                subscribe = state["subscribe"][usrid]
                subscribe = Enum.reduce(subscribe, [], fn x, list ->
                    list ++ [{x, elem(usrs[x], 0)}]
                end)
                {:reply, {:ok, %{usrinfo: usrinfo, message_queue: message_queue, followers: followers, subscirbe: subscribe}}, state}
            end
        end
    end

    def handle_call({:logoff, usrid}, _from, state) do
        state = Map.update!(state, "usrstatus", fn x ->
            Map.update!(x, usrid, fn _ -> nil end)
        end)
        {:reply, :ok, state}
    end

    def handle_call({:fetch_update, usrid}, _from, state) do
        message_list = Map.get(
            Map.get(state, "message_queue"),
            usrid
        )
        state = if message_list != [] do
            Map.update!(state, "message_queue", fn x ->
                Map.put(x, usrid, [])
            end)
        else
            state
        end
        {:reply, message_list, state}
    end

    # Handle tweet messages and distribute it
    def handle_cast({:tweet, tweet, hashtags, mentions, usrid}, state) do
        tweet_id = state["tweet_num"]

        state = Map.update!(state, "tweet_num", fn x -> x + 1 end)
        state = Map.update!(state, "usr_tweet", fn x ->
            Map.update!(x, usrid, fn y ->
                y ++ [tweet_id]
            end)
        end)
        state = Map.update!(state, "tweet", fn x ->
            Map.put(x, tweet_id, {:original, tweet, usrid})
        end)
        state = Map.update!(state, "mention", fn x ->
            Map.put(x, tweet_id, mentions)
        end)
        state = Enum.reduce(mentions, state, fn x, map ->
            Map.update!(map, "usr_mention", fn y ->
                Map.update!(y, x, fn z -> z ++ [tweet_id] end)
            end)
        end)
        state = Map.update!(state, "tweet_hashtag", fn x ->
            Map.put(x, tweet_id, hashtags)
        end)
        
        state = Enum.reduce(hashtags, state, fn hashtag, map ->
            if hashtag not in Map.keys(map["hashtag"]) do
                Map.update!(map, "hashtag", fn x ->
                    Map.put(x, hashtag, [tweet_id])
                end)
            else
                Map.update!(map, "hashtag", fn x ->
                    Map.update!(x, hashtag, fn y ->
                        y ++ [tweet_id]
                    end)
                end)
            end
        end)
        
        tweet_tuple = {
            :tweet,                             # atomic
            {
                usrid,                          # usrid of the author
                elem(state["usr"][usrid], 0),   # usrname of the author
                tweet,                          # tweet content
                tweet_id,                       # tweet_id
                hashtags,                       # hashtags
                mentions                        # usrids of mentioned usrs 
            }
        }

        state = Enum.reduce(state["followers"][usrid], state, fn uid, map ->
            send_or_save(tweet_tuple, uid, map)
        end)
        state = Enum.reduce(mentions, state, fn uid, map ->
            send_or_save({:mentioned, tweet_tuple}, uid, map)
        end)
        {:noreply, state}
    end

    # Handle subscirbe requests
    def handle_cast({:subscribe, from, to}, state) do
        state = Map.update!(state, "followers", fn x ->
            Map.update!(x, to, fn y -> y ++ [from] end)
        end)
        state = Map.update!(state, "subscribe", fn x ->
            Map.update!(x, from, fn y -> y ++ [to] end)
        end)
        
        usrname = elem(state["usr"][from], 0)
        state = send_or_save({:subscribed_by, from, usrname}, to, state)

        {:noreply, state}
    end

    # Handle retweet messages and distribute it
    def handle_cast({:retweet, tweet_id, usrid}, state) do
        new_tweet_id = state["tweet_num"]
        
        state = Map.update!(state, "tweet_num", fn x -> x + 1 end)
        state = Map.update!(state, "usr_tweet", fn x ->
            Map.update!(x, usrid, fn y ->
                y ++ [new_tweet_id]
            end)
        end)
        state = Map.update!(state, "tweet", fn x ->
            Map.put(x, new_tweet_id, {:retweet, tweet_id, usrid})
        end)

        mentions = state["mention"][tweet_id]
        state = Map.update!(state, "mention", fn x -> 
            Map.put(x, new_tweet_id, [])
        end)

        hashtags = state["tweet_hashtag"][tweet_id]
        state = Map.update!(state, "tweet_hashtag", fn x ->
            Map.put(x, new_tweet_id, hashtags)
        end)
        state = Enum.reduce(hashtags, state, fn hashtag, map ->
            Map.update!(map, "hashtag", fn x ->
                Map.update!(x, hashtag, fn y ->
                    y ++ [new_tweet_id]
                end)
            end)
        end)

        usrname = elem(state["usr"][usrid], 0)
        original_usrid = elem(state["tweet"][tweet_id], 2)
        original_tweet_info = state["tweet"][tweet_id]

        retweet_tuple = {
            :retweet,                                   # atomic
            {
                usrid,                                  # usrid of the usr that retweeted
                usrname,                                # usrname of the usr that retweeted
                new_tweet_id,                           # tweet_id of the retweet
                original_usrid,                         # usrid of the original author
                elem(state["usr"][original_usrid], 0),  # usrname of the original author
                tweet_id,                               # tweet_id of the original id
                elem(original_tweet_info, 1),           # tweet content
                hashtags,                               # hashtags
                mentions                                # original mentions may be useless
            }
        }

        state = send_or_save({:retweeted, retweet_tuple}, original_usrid, state)

        state = Enum.reduce(state["followers"][usrid], state, fn uid, map ->
            send_or_save(retweet_tuple, uid, map)
        end)

        {:noreply, state}
    end

    # Handle query requests
    # Return a list of results
    def handle_cast({:query, query_type, parameter, usrid}, state) do
        result = query(query_type, parameter, state)
        # IO.inspect result
        if state["usrstatus"][usrid] do
            GenServer.cast(state["usrstatus"][usrid], {:query_result, query_type, result})
        end
        {:noreply, state}
    end

    def query(query_type, parameter, state) do
        case query_type do
            :query_subscribed ->
                subscribe_list = state["subscribe"][parameter]
                Enum.reduce(subscribe_list, [], fn usrid, list ->
                    usrname = elem(state["usr"][usrid], 0)
                    tweet_id_list = state["usr_tweet"][usrid]
                    list ++ Enum.reduce(tweet_id_list, [], fn tweet_id, l ->
                        tweet_info = state["tweet"][tweet_id]
                        if elem(tweet_info, 0) == :original do
                            l ++ [{
                                :tweet,
                                usrid,                              # usrid of the author
                                usrname,                            # usrname of the author
                                elem(tweet_info, 1),                # tweet content
                                tweet_id,                           # tweet_id
                                state["tweet_hashtag"][tweet_id],   # hashtags
                                state["mention"][tweet_id],         # usrids of mentioned usrs 
                            }]
                        else
                            original_tweet_id = elem(tweet_info, 1)
                            original_usrid = elem(state["tweet"][original_tweet_id], 2)
                            original_tweet_info = state["tweet"][original_tweet_id]
                            l ++ [{
                                :retweeted,                                 # atomic
                                usrid,                                      # usrid of the usr that retweeted
                                usrname,                                    # usrname of the usr that retweeted
                                tweet_id,                                   # tweet_id of the retweet
                                original_usrid,                             # usrid of the original author
                                elem(state["usr"][original_usrid], 0),      # usrname of the original author
                                original_tweet_id,                          # tweet_id of the original id
                                elem(original_tweet_info, 1),               # tweet content
                                state["tweet_hashtag"][original_tweet_id],  # hashtags
                                state["mention"][original_tweet_id]         # original mentions may be useless
                            }]
                        end
                    end)
                end)
            :query_hashtag ->
                fetch_tweet_list(state["hashtag"][parameter], state)
            :query_mentioned ->
                fetch_tweet_list(state["usr_mention"][parameter], state) 
        end
    end

    def fetch_tweet_list(tweet_id_list, state) do
        Enum.reduce(tweet_id_list, [], fn tweet_id, l ->
            tweet_info = state["tweet"][tweet_id]
            usrid = elem(tweet_info, 2)
            usrname = elem(state["usr"][usrid], 0)
            if elem(tweet_info, 0) == :original do
                l ++ [{
                    :tweet,
                    usrid,                              # usrid of the author
                    usrname,                            # usrname of the author
                    elem(tweet_info, 2),                # tweet content
                    tweet_id,                           # tweet_id
                    state["tweet_hashtag"][tweet_id],   # hashtags
                    state["mention"][tweet_id],         # usrids of mentioned usrs 
                }]
            else
                original_tweet_id = elem(tweet_info, 1)
                original_usrid = elem(state["tweet"][original_tweet_id], 2)
                original_tweet_info = state["tweet"][original_tweet_id]
                l ++ [{
                    :retweeted,                                 # atomic
                    usrid,                                      # usrid of the usr that retweeted
                    usrname,                                    # usrname of the usr that retweeted
                    tweet_id,                                   # tweet_id of the retweet
                    original_usrid,                             # usrid of the original author
                    elem(state["usr"][original_usrid], 0),      # usrname of the original author
                    original_tweet_id,                          # tweet_id of the original id
                    elem(original_tweet_info, 1),               # tweet content
                    state["tweet_hashtag"][original_tweet_id],  # hashtags
                    state["mention"][original_tweet_id]         # original mentions may be useless
                }]
            end
        end)
    end

    def send_or_save(message, usrid, state) do
        # if state["usrstatus"][usrid] do
        #     GenServer.cast(state["usrstatus"][usrid], message)
        #     state
        # else
        #     Map.update!(state, "message_queue", fn x ->
        #         Map.update!(x, usrid, fn y ->
        #             y ++ [message]
        #         end)
        #     end)
        # end
        Map.update!(state, "message_queue", fn x ->
            Map.update!(x, usrid, fn y ->
                y ++ [message]
            end)
        end)
    end
end