# Proj2

## Team members
| Name | UFID |
| :---: | :---: |
| Junran Xie | 10195189 |
| Jingyu Luo | 19140129 |

## How to run
##### Create an executable file in Elixir:
mix escript.build
##### Run in Windows:
escript my_program actor_num topology algorithm
##### Run in Linux:
my_program actor_num topology algorithm

## What is working
All topologies in both algorithms are working. But the efficiency of different algorithms varies a lot. 
The implementation and result details can be seen in our report.

## What is the largest network you managed to deal with for each type of topology and algorithm
| Topology  | gossip largest actor num | gossip time | push-sum largest actor num | push-sum time |
| :---: | :---: | :---: | :---: | :---: |
| full | 5000 | 431918ms | 1000 | 308624ms |
| line | 50000 | 1176ms | 3000 | 84210ms |
| rand2D | 5000 | 8162ms | 2000 | 114889ms |
| 3Dtorus | 30000 | 16984ms | 10000 | 132796ms |
| honeycomb | 30000 | 1921ms | 3000 | 242793ms |
| randhoneycomb | 20000 | 29611ms | 1000 | 230500ms |
