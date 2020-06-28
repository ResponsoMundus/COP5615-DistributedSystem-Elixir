# DOS Project 4.1
## Team members
| Name | UFID |
| :---: | :---: |
| Junran Xie | 10195189 |
| Jingyu Luo | 19140129 |

## How to run the program
Run simulation by
    mix run proj4.exs num_user num_msg

Run test by
    mix test test/proj4_test.exs --seed 0
There are 15 test focusing on every function of the engine in sequence:
    register_test
    login_test
    logout_test
    subscribe_test
    tweet_test_1
    tweet_test_2
    retweet_test_1
    retweet_test_2
    logout_message_test_1
    logout_message_test_2
    query_subscribed_test
    query_mentioned_test
    query_hashtag_test
    delete_test_1
    delete_test_2

## What is implemented
Register and delete accounts
Subscribe to other users
Sending tweets and retweets
Mention and hashtag in tweets
Account login and logout
Query by subscribed, mentioned and hashtag

All functions are working
