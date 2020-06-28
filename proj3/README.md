# DOS Project 3

## Team members
| Name | UFID |
| :---: | :---: |
| Junran Xie | 10195189 |
| Jingyu Luo | 19140129 |

## To run the program
Using command 
  mix run proj3.exs num_nodes num_requests

## What is Working
Dynamic join based on acknowledge multicast was successfully
implemented.
Routing from actor to actor is fully operational. It was used to 
find surrogate when joining, and find next hop location when
requesting or publishing


## Largest network managed to deal with
6500 actors with the command below
mix run proj3.exs 6500 10
It took 890.047 seconds to run (and about 9.4G memory).
The maximum number of hops was 5.
The average number of hops was 3.3.

