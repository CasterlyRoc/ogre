require 'socket'
require 'thread'
require 'yaml'

# Git commands to update project on Github
# git stage (name of file you updated)
# git commit -m 'What you changed'
# git push origin master

class Packet

	attr_accessor:msg_type,:seq_num,:source,:dest,:adj_hash,:data

	def initialize(type, source, dest, data, adj_hash)
		@msg_type = type
		@seq_num = 1
		@source = source
		@dest = dest
		@adj_hash = adj_hash
		@data = data
	end

	def to_s
		"#{msg_type}, #{seq_num}, #{source}, #{dest}, #{data}"
	end

end

class Node

	attr_accessor:name,:ip_addrs,:adj_hash,:seq_hash,:topo_hash

	def initialize(name)
		@name = name
		@ip_addrs = Array.new
		@adj_hash = Hash.new
		@seq_hash = Hash.new
		@routing_table = Hash.new
	end

	def add_ip_addr(ip)
		ip_addrs.push(ip)
	end

	def add_neighbor(dest_node, cost)
		adj_hash.store(dest_node, cost)
	end

	def to_s
		puts "Node: #{name}"
		puts "---IP Addresses---"
		ip_addrs.each{ |s|
			puts "  " + s
		}
		puts "---Neighbors---"
		adj_hash.each{ |k,v|
			puts "  has an edge to #{k} with cost #{v}"
		}
	end

end

# Variables
threads = Array.new

# Execute hostname to get name of the node
name_of_node = `hostname`
name_of_node.chomp!
node = Node.new(name_of_node)

# Process config file

config_file = open(ARGV[0])

node_line = config_file.gets
node_line.chomp!
nodes_to_addr_file = open(node_line)

link_line = config_file.gets
link_line.chomp!
link_file = open(link_line)

# Get ip addresses assoc with the node
while nodes_to_addr_line = nodes_to_addr_file.gets
	name_of_node, ip_addr = nodes_to_addr_line.split(" ")
	if(name_of_node == node.name)
		node.add_ip_addr(ip_addr)
	end
end

# Get links between nodes and the cost
while link_line = link_file.gets
	source_node, dest_node, cost = link_line.split(" ")
	if(node.ip_addrs.include?(source_node))
		c = cost.to_i
		node.add_neighbor(dest_node, c)
	end
end

# Recieving Thread
threads << Thread.new do
	srv_sock = TCPServer.open(9999)
	data = ""
	recv_length = 255
	client = srv_sock.accept
	while(tmp = client.recv(recv_length))
		data += tmp
		break if tmp.length < recv_length
	end

	packet = YAML::load(data)

	if(packet.msg_type == "LINK_PACKET")
		puts packet.to_s
	end
end

# Routing Thread
threads << Thread.new do
	sleep(10)
	node.adj_hash.each_key{ |neighbor|
		out_packet = Packet.new("LINK_PACKET", node.name, neighbor, "THIS IS A TEST")
		serialized_obj = YAML::dump(out_packet)
		sockfd = TCPSocket.open(neighbor, 9999)
		sockfd.send(serialized_obj, 0)
		s.close
	}
end

threads.each{ |t|
	t.join
}






































