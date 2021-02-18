# Zhegnhui Wang(zw2520) and Linshan Li(ll3720)

# distributed algorithms, n.dulay, 29 jan 21
# coursework, paxos made moderately complex

# make options for Multipaxos

CLEAN UP
--------
make clean   - remove compiled code
make compile - compile 

make run     - same as make run SERVERS=5 CLIENTS=5 CONFIG=default DEBUG=0 MAX_TIME=15000

#for debug, quite useful in low request case.
#not for debug the huge requests situation.
make run CONFIG=custom_debug

# for test case 1 ---- 1 server 1 client 
make run SERVERS=1 CLIENTS=1 CONFIG=default DEBUG=0 MAX_TIME=5000


# for test case 2_1 ----- 2 servers 3 clients 5 windows
make run SERVERS=2 CLIENTS=3 CONFIG=default DEBUG=0 MAX_TIME=25000

# for test case 2_2 ----- 2 servers 3 clients 100 windows
make run SERVERS=2 CLIENTS=3 CONFIG=test_case_2_2 DEBUG=0 MAX_TIME=25000

# for test case 3_1 ----- 10 servers 3 clients
make run SERVERS=10 CLIENTS=3 CONFIG=default DEBUG=0 MAX_TIME=25000

# for test case 3_2 ----- 2 servers 10 clients 
make run SERVERS=2 CLIENTS=10 CONFIG=default DEBUG=0 MAX_TIME=25000

# for test case 4 ----- 3 servers 3 clients clash_server1
make run SERVERS=3 CLIENTS=3 CONFIG=test_case_4 DEBUG=0 MAX_TIME=10000

# for test case 5 ----- 3 servers 3 clients clash_server1&2
make run SERVERS=3 CLIENTS=3 CONFIG=test_case_5 DEBUG=0 MAX_TIME=10000

# for test case 6_1 ----- 2 servers 3 clients 100 max_request
make run SERVERS=2 CLIENTS=3 CONFIG=test_case_6_1 DEBUG=0 MAX_TIME=10000

# for test case 6_2 ----- 2 servers 3 clients 5000 max_request
make run SERVERS=2 CLIENTS=3 CONFIG=test_case_6_2 DEBUG=0 MAX_TIME=25000

# for test case 7 ----- 5 servers 5 clients 100 windows
make run SERVERS=5 CLIENTS=5 CONFIG=test_case_7 DEBUG=0 MAX_TIME=25000
