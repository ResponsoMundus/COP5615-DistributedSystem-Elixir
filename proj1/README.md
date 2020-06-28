### 1. Group members: 
	Junran Xie 10195189    
	Jingyu Luo 19140129

### 2. Number of worker actors created: 
	100

### 3. Size of work unit of each worker actor:
	  Suppose the input is [min_product, max_product, actor_num]
	  Then the factor of the valid vampire numbers we can choose is between:
		    from 	min_factor = trunc(:math.pow(10, length(Integer.to_charrlist(min_product))/2 - 1))
		    to 		max_factor = trunc(:math.sqrt(max_product))
	  So the work unit of each worker is 
		    div(max_factor - min_factor, actor_num)

### 4. Result of running my program for:  mix run proj1.exs 100000 200000
    C:\Users\xjrsf\Desktop\COP5615\proj1>mix run proj1.exs 100000 200000
    Compiling 1 file (.ex)
    Generated proj1 app
    102510 201 510
    104260 260 401
    105210 210 501
    105264 204 516
    105750 150 705
    108135 135 801
    110758 158 701
    115672 152 761
    116725 161 725
    117067 167 701
    118440 141 840
    120600 201 600
    123354 231 534
    124483 281 443
    125248 152 824
    125433 231 543
    125460 246 510 204 615
    125500 251 500
    126000 210 600
    126027 201 627
    126846 261 486
    129640 140 926
    129775 179 725
    131242 311 422
    132430 323 410
    133245 315 423
    134725 317 425
    135828 231 588
    135837 351 387
    136525 215 635
    136948 146 938
    139500 150 930
    140350 350 401
    143500 350 410
    145314 351 414
    146137 317 461
    146952 156 942
    150300 300 501
    152608 251 608
    152685 261 585
    153000 300 510
    153436 356 431
    156240 240 651
    156289 269 581
    156915 165 951
    162976 176 926
    163944 396 414
    172822 221 782
    173250 231 750
    174370 371 470
    175329 231 759
    180225 225 801
    180297 201 897
    182250 225 810
    182650 281 650
    182700 210 870
    186624 216 864
    190260 210 906
    192150 210 915
    193257 327 591
    193945 395 491
    197725 275 719

### 5. Calling: time mix run proj1 100000 200000
  real    0m0.399s
	user    0m1.003s
	sys     0m0.272s
  So the ratio of CPU time to Real Time: (1.003s + 0.272s) / 0.399s = 319.55%

### 6. The largest problem you managed to solve:
  For the monent, 1999378525 with fangs 38975 and 51299 is the largest problem
  we have managed to solve with the command of "mix run proj.exs 1000000000 
  2000000000".

### 7. Inspect code with observer
  See the observer-1.JPG in pic directory for screenshots of CPU usage chart of 
  running command "mix run proj.exs 10000000 99999999" with single 8-thread 
  windows machine

  See the observer-2.JPG in pic directory for screenshots of CPU usage chart of 
  a minute running command "mix run proj.exs 1000000000 2000000000" with single 
  8-thread windows machine

### 8. Bonus Implementation Detail
#### How to distribute the actors on the machines:
	In a cluster with 2 machines, the actors with odd index will be deployed on local machine, and actors with 
	even index will run on remote machine.
#### Step-by-step Instruction:
	On machine 1:
	cd lib
	iex --name "first@IP_of_first_machine" --cookie cookie_name
	c("proj1.ex")
	
	On machine 2:
	cd lib
	iex --name "two@IP_of_second_machine" --cookie cookie_name
	Node.connect :"first@IP_of_first_machine"
	c("proj1.ex")
	Proj1.start_link([100, 1000000000, 2000000000, "first@IP_of_first_machine"])


### 9. Bonus Demo URL
https://www.youtube.com/watch?v=OFCWmZHRDxY&feature=youtu.be
