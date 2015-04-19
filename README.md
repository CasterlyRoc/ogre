

How to Run Our Code:

Our code is run using the config file: project.config
This file has 6 parameters and are as follows

	Maximum Packet Size
	Path to nodes-to-addresses
	Path to weights
	Update Interval
	Path to Routing Table Text File
	Dump Interval

The config file is used as a command line argument. Our code is called using the ruby call: ruby Node.rb project.config

Our code can also be run using the shell script file: test.sh

The weights file must be structured: source,dest,weight ex. 10.0.0.20,10.0.0.21,4
The nodes-to-adresses should be structed: hostname	address (where the whitespace is a tab) ex. n1	10.0.0.20

What Our Code Does:

Our code creates 3 threads: a recieving thread, a routing thread, and a dumping thread

The recieving thread accepts packets passed over the network. Depending on the type of packet recieved this thread will decide what action to take.

The routing thread checks for a topology change. If it notices a change it will change it's own topology and send out the change over the network. It will check for changes based on the update interval defined in the project.config file.

The dump thread gets the routing table stored in the node and outputs the routing table into a text file stored at the path specified in the config file. It is dumped every dump interval also specified in the config file. 

The routing and dump threads sleep to allow our script to be run on every node before it begins sending packets. The routing thread also sleeps before getting the routing table from dijkstra to allow time to recieve all packets from the topology change.