defmodule Proj42Web.UserView do
    use Proj42Web, :view

    def get_user_information(userid) do
        userid = elem(Integer.parse(userid), 0)
        server_state = GenServer.call(Proj42.Server, {:get_state})
        subscribeids = if server_state["subscribe"][userid] == nil do
            []
        else
            server_state["subscribe"][userid]
        end
        subscribeids = Enum.reduce(subscribeids, "", fn id, head -> head <> "User#{id} " end)

        if String.length(subscribeids) == 0 do
            "You haven't subscribe anyone"
        else
            subscribeids
        end
    end

    def get_followers(userid) do
        userid = elem(Integer.parse(userid), 0)
        server_state = GenServer.call(Proj42.Server, {:get_state})
        followerids = if server_state["followers"][userid] == nil do
            []
        else
            server_state["followers"][userid]
        end
        followerids = Enum.reduce(followerids, "", fn id, head -> head <> "#{id} " end)

        if String.length(followerids) == 0 do
            "You haven't no follower"
        else
            followerids
        end
    end

    def get_tweets(userid) do
        userid = elem(Integer.parse(userid), 0)
        server_state = GenServer.call(Proj42.Server, {:get_state})

        if server_state["usr_tweet"][userid] == nil or length(server_state["usr_tweet"][userid]) == 0 do
            ["You have tweeted nothing"]
        else
            tweetids = server_state["usr_tweet"][userid]
            usrname = elem(server_state["usr"][userid], 0)
            tweetlists = Enum.reduce(tweetids, [], fn tweet_id, l ->
                tweet_info = server_state["tweet"][tweet_id]
                if elem(tweet_info, 0) == :original do
                    l ++ [[
                        :tweet,
                        userid,                             # usrid of the author
                        usrname,                            # usrname of the author
                        elem(tweet_info, 1),                # tweet content
                        tweet_id,                           # tweet_id
                        server_state["tweet_hashtag"][tweet_id],   # hashtags
                        server_state["mention"][tweet_id],         # usrids of mentioned usrs 
                    ]]
                else
                    original_tweet_id = elem(tweet_info, 1)
                    original_usrid = elem(server_state["tweet"][original_tweet_id], 2)
                    original_tweet_info = server_state["tweet"][original_tweet_id]
                    l ++ [[
                        :retweeted,                                 # atomic
                        userid,                                     # usrid of the usr that retweeted
                        usrname,                                    # usrname of the usr that retweeted
                        tweet_id,                                   # tweet_id of the retweet
                        original_usrid,                             # usrid of the original author
                        elem(server_state["usr"][original_usrid], 0),      # usrname of the original author
                        original_tweet_id,                          # tweet_id of the original id
                        elem(original_tweet_info, 1),               # tweet content
                        server_state["tweet_hashtag"][original_tweet_id],  # hashtags
                        server_state["mention"][original_tweet_id]         # original mentions may be useless
                    ]]
                end
            end)
            Enum.reduce(tweetlists, [], fn tweet, head -> 
                if Enum.at(tweet, 0) == :tweet do
                    user_mentioned = Enum.reduce(Enum.at(tweet, 6), "", fn mentioned_id, h ->
                        h <> "User#{mentioned_id} "
                    end)
                    hashtags = Enum.reduce(Enum.at(tweet, 5), "", fn tag, h ->
                        h <> tag <> " "
                    end)
                    head ++ ["User " <> Enum.at(tweet, 2) <> "(#{Enum.at(tweet, 1)})\n"
                    <> "Content: " <> Enum.at(tweet, 3) <> "\n" 
                    <> "User Mentioned: " <> user_mentioned <> "\n"
                    <> "Hashtag:" <> hashtags <> "\n"]
                else
                    user_mentioned = Enum.reduce(Enum.at(tweet, 9), "", fn mentioned_id, h ->
                        h <> "User#{mentioned_id} "
                    end)
                    hashtags = Enum.reduce(Enum.at(tweet, 8), "", fn tag, h ->
                        h <> tag <> " "
                    end)
                    head ++ ["User " <> Enum.at(tweet, 2) <> "(#{Enum.at(tweet, 1)}) retweeted from " <> Enum.at(tweet, 5) <> "(#{Enum.at(tweet, 4)})\n"
                    <> "Content: " <> Enum.at(tweet, 7) <> "\n" 
                    <> "User Mentioned: " <> user_mentioned <> "\n"
                    <> "Hashtag:" <> hashtags <> "\n"]
                end
            end)
        end
    end

    def get_subscribed_tweets(userid) do
        userid = elem(Integer.parse(userid), 0)
        server_state = GenServer.call(Proj42.Server, {:get_state})

        subscribed_id_list = if server_state["subscribe"][userid] == nil or length(server_state["subscribe"][userid]) == 0 do
            []
        else
            server_state["subscribe"][userid]
        end

        tweet_lists = Enum.reduce(subscribed_id_list, [], fn id, list -> 
            usrname = elem(server_state["usr"][id], 0)
            tweet_id_list = server_state["usr_tweet"][id]
            tweetlists = Enum.reduce(tweet_id_list, [], fn tweet_id, l ->
                tweet_info = server_state["tweet"][tweet_id]
                if elem(tweet_info, 0) == :original do
                    l ++ [[
                        :tweet,
                        id,                             # usrid of the author
                        usrname,                            # usrname of the author
                        elem(tweet_info, 1),                # tweet content
                        tweet_id,                           # tweet_id
                        server_state["tweet_hashtag"][tweet_id],   # hashtags
                        server_state["mention"][tweet_id],         # usrids of mentioned usrs 
                    ]]
                else
                    original_tweet_id = elem(tweet_info, 1)
                    original_usrid = elem(server_state["tweet"][original_tweet_id], 2)
                    original_tweet_info = server_state["tweet"][original_tweet_id]
                    l ++ [[
                        :retweeted,                                 # atomic
                        id,                                     # usrid of the usr that retweeted
                        usrname,                                    # usrname of the usr that retweeted
                        tweet_id,                                   # tweet_id of the retweet
                        original_usrid,                             # usrid of the original author
                        elem(server_state["usr"][original_usrid], 0),      # usrname of the original author
                        original_tweet_id,                          # tweet_id of the original id
                        elem(original_tweet_info, 1),               # tweet content
                        server_state["tweet_hashtag"][original_tweet_id],  # hashtags
                        server_state["mention"][original_tweet_id]         # original mentions may be useless
                    ]]
                end
            end)
            list ++ tweetlists
        end)

        if length(tweet_lists) == 0 do
            ["The subscribed users have tweeted nothing"]
        else
            Enum.reduce(tweet_lists, [], fn tweet, head -> 
                if Enum.at(tweet, 0) == :tweet do
                    user_mentioned = Enum.reduce(Enum.at(tweet, 6), "", fn mentioned_id, h ->
                        h <> "User#{mentioned_id} "
                    end)
                    hashtags = Enum.reduce(Enum.at(tweet, 5), "", fn tag, h ->
                        h <> tag <> " "
                    end)
                    head ++ ["User " <> Enum.at(tweet, 2) <> "(#{Enum.at(tweet, 1)})\n"
                    <> "Content: " <> Enum.at(tweet, 3) <> "\n" 
                    <> "User Mentioned: " <> user_mentioned <> "\n"
                    <> "Hashtag:" <> hashtags <> "\n"]
                else
                    user_mentioned = Enum.reduce(Enum.at(tweet, 9), "", fn mentioned_id, h ->
                        h <> "User#{mentioned_id} "
                    end)
                    hashtags = Enum.reduce(Enum.at(tweet, 8), "", fn tag, h ->
                        h <> tag <> " "
                    end)
                    head ++ ["User " <> Enum.at(tweet, 2) <> "(#{Enum.at(tweet, 1)}) retweeted from " <> Enum.at(tweet, 5) <> "(#{Enum.at(tweet, 4)})\n"
                    <> "Content: " <> Enum.at(tweet, 7) <> "\n" 
                    <> "User Mentioned: " <> user_mentioned <> "\n"
                    <> "Hashtag:" <> hashtags <> "\n"]
                end
            end)
        end
    end
end