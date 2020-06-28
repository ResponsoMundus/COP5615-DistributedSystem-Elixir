defmodule Proj42Web.UserChannel do
    use Phoenix.Channel

    def join("user:register", %{"username" => username, "password" => password}, socket) do
        userid = GenServer.call(Proj42.Server, {:register, username, password})
        if userid != :usrname_already_exist do
            {:ok, userid, socket}
        else
            {:error, %{reason: "User name already existed!"}}
        end
    end

    def join("user:login", %{"userid" => userid, "password" => password}, socket) do
        case GenServer.call(Proj42.Server, {:login, userid, password}) do
            {:ok, map} ->
                socket = assign(socket, :info, map)
                {:ok, nil, socket}
            :usr_nonexist ->
                {:error, %{reason: "User id not exist!"}}
            :wrong_password ->
                {:error, %{reason: "Wrong Password!"}}
            _ ->
                {:error, %{reason: "Unknow Error!"}}
        end
    end

    def join("user:info", _, socket) do
        IO.inspect socket.assigns.info
        {:ok, socket.assigns.info, socket}
    end

    def join("user:subscribe", _, socket) do
        {:ok, nil, socket}
    end

    def join("user:subscribe_and_refresh", %{"userid" => userid, "subscribeUserid" => subscribeUserid}, socket) do
        state = GenServer.call(Proj42.Server, {:get_state})
        if (Map.has_key?(state["usr"], userid)
            and Map.has_key?(state["usr"], subscribeUserid)
            and (!Enum.member?(state["subscribe"], userid)
            or !Enum.member?(state["subscribe"][userid], subscribeUserid))) do
            GenServer.cast(Proj42.Server, {:subscribe, userid, subscribeUserid})
            {:ok, nil, socket}
        else
            {:error, %{reason: "Invalid subscription!"}}
        end
    end

    def join("user:tweet", _, socket) do
        {:ok, nil, socket}
    end

    def join("user:tweet_and_refresh", %{"userid" => userid, "tweet" => tweet, "hashTag" => hashTag, "mention" => mention}, socket) do
        hashTags = if String.length(hashTag) == 0 do
            []
        else 
            String.split(hashTag, ",")
        end

        mentions = if String.length(mention) == 0 do
            []
        else 
            String.split(mention, ",")
        end

        mentions = Enum.map(mentions, fn x -> elem(Integer.parse(x), 0) end)
        GenServer.cast(Proj42.Server, {:tweet, tweet, hashTags, mentions, userid})
        {:ok, nil, socket}
    end

    def join("user:search", _, socket) do
        {:ok, nil, socket}
    end

    def join("user:back", _, socket) do
        {:ok, nil, socket}
    end

    def join("user:subsearch", %{"userid" => userid}, socket) do
        try do
            state = GenServer.call(Proj42.Server, {:get_state})
            subscribe_list = state["subscribe"][userid]
            tweet_list = Enum.reduce(subscribe_list, [], fn usrid, list ->
                usrname = elem(state["usr"][usrid], 0)
                tweet_id_list = state["usr_tweet"][usrid]
                list ++ Enum.reduce(tweet_id_list, [], fn tweet_id, l ->
                    tweet_info = state["tweet"][tweet_id]
                    if elem(tweet_info, 0) == :original do
                        l ++ [[
                            :tweet,
                            usrid,                              # usrid of the author
                            usrname,                            # usrname of the author
                            elem(tweet_info, 1),                # tweet content
                            tweet_id,                           # tweet_id
                            state["tweet_hashtag"][tweet_id],   # hashtags
                            state["mention"][tweet_id],         # usrids of mentioned usrs 
                        ]]
                    else
                        original_tweet_id = elem(tweet_info, 1)
                        original_usrid = elem(state["tweet"][original_tweet_id], 2)
                        original_tweet_info = state["tweet"][original_tweet_id]
                        l ++ [[
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
                        ]]
                    end
                end)
            end)
            {:ok, tweet_list, socket}
        rescue
            _ -> {:error, %{reason: "Unknow"}}
        end
        
    end

    def join("user:mentionsearch", %{"userid" => userid}, socket) do
        try do
            state = GenServer.call(Proj42.Server, {:get_state})
            tweet_id_list = state["usr_mention"][userid]
            tweet_list = Enum.reduce(tweet_id_list, [], fn tweet_id, l ->
                tweet_info = state["tweet"][tweet_id]
                usrid = elem(tweet_info, 2)
                usrname = elem(state["usr"][usrid], 0)
                if elem(tweet_info, 0) == :original do
                    l ++ [[
                        :tweet,
                        usrid,                              # usrid of the author
                        usrname,                            # usrname of the author
                        elem(tweet_info, 1),                # tweet content
                        tweet_id,                           # tweet_id
                        state["tweet_hashtag"][tweet_id],   # hashtags
                        state["mention"][tweet_id],         # usrids of mentioned usrs 
                    ]]
                else
                    original_tweet_id = elem(tweet_info, 1)
                    original_usrid = elem(state["tweet"][original_tweet_id], 2)
                    original_tweet_info = state["tweet"][original_tweet_id]
                    l ++ [[
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
                    ]]
                end
            end)
            {:ok, tweet_list, socket}
        rescue
            _ -> {:error, %{reason: "Unknow"}}
        end
    end

    def join("user:hashtagsearch", %{"hashtag" => hashtag}, socket) do
        try do
            state = GenServer.call(Proj42.Server, {:get_state})
            tweet_id_list = state["hashtag"][hashtag]
            tweet_list = Enum.reduce(tweet_id_list, [], fn tweet_id, l ->
                tweet_info = state["tweet"][tweet_id]
                usrid = elem(tweet_info, 2)
                usrname = elem(state["usr"][usrid], 0)
                if elem(tweet_info, 0) == :original do
                    l ++ [[
                        :tweet,
                        usrid,                              # usrid of the author
                        usrname,                            # usrname of the author
                        elem(tweet_info, 1),                # tweet content
                        tweet_id,                           # tweet_id
                        state["tweet_hashtag"][tweet_id],   # hashtags
                        state["mention"][tweet_id],         # usrids of mentioned usrs 
                    ]]
                else
                    original_tweet_id = elem(tweet_info, 1)
                    original_usrid = elem(state["tweet"][original_tweet_id], 2)
                    original_tweet_info = state["tweet"][original_tweet_id]
                    l ++ [[
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
                    ]]
                end
            end)
            {:ok, tweet_list, socket}
        rescue
            _ -> {:error, %{reason: "Unknow"}}
        end
    end

end