require 'socket'
require 'thread'
require 'yaml'
require 'monitor'

# Git commands to update project on Github
# git stage (name of file you updated)
# git commit -m 'What you changed'
# git push origin master

# gen weights file input
# when to run dijkstras, wait for whole topo or whenever we recieve packet

# Screen gra
# Cant look up file

class Packet

	attr_accessor:msg_type,:seq_num,:source,:dest,:topo_hash,:data

	def initialize(type, source, dest, topo_hash, data)
		@msg_type = type
		@seq_num = 1
		@source = source
		@dest = dest
		@topo_hash = topo_hash
		@data = data
	end

	def to_s
		"#{msg_type}, #{seq_num}, #{source}, #{dest}, #{data}"
	end

end

class Node

	attr_accessor:name,:ip_addrs,:adj_hash,:seq_hash,:topo_hash,:lock

	def initialize(name)
		@name = name
		@ip_addrs = Array.new
		@adj_hash = Hash.new
		@seq_hash = Hash.new
		@routing_table = Hash.new
		@topo_hash = Hash.new
		@lock = Monitor.new
	end

	def add_ip_addr(ip)
		ip_addrs.push(ip)
	end

	def add_neighbor(dest_node, cost)
		adj_hash.store(dest_node, cost)
	end

	def add_topo(source, dest_node, cost)
		if(@topo_hash[source] == nil)
			tmp = Hash.new
			tmp[dest_node] = cost
			@topo_hash[source] = tmp
		else
			@topo_hash[source][dest_node] = cost
		end
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
		puts "---Topo Hash---"
		topo_string
	end

	def topo_string(route)
		puts "TOPO HASH STRING"
		s = "{"
		i = 0
		route.each_key{ |k|
			if (i != 0)
				s += ","
			end
			s += "\"#{k}\"=>{"
			j = 0
			route[k].each{ |dest, cost|
				if (j != 0)
					s += ","
				end
				s += "\"#{dest}\"=>#{cost}"
				j += 1
			 }
			 s+="}"
			 i += 1
		}

		s  += "}"
		puts s
	end

	def file_has_changed(file)
		has_changed = false
		f = open(file)
		while line = f.gets
			source, dest, cost = line.split(" \n")
			if(@ip_addrs.include?(source) == true)
				c = cost.to_i
				if(@adj_hash.fetch(dest) != c)
					has_changed = true
				end
			end
		end
		f.close
		return has_changed
	end
end

def print_route(route)
		s = "{"
		i = 0
		route.each_key{ |k|
			if (i != 0)
				s += ","
			end
			s += "\"#{k}\"=>{"
			j = 0
			route[k].each{ |dest, cost|
				if (j != 0)
					s += ","
				end
				s += "\"#{dest}\"=>#{cost}"
				j += 1
			 }
			 s+="}"
			 i += 1
		}

		s  += "}"
		return s
end	


# Gets the name of the node given an IP address
def get_name(ip_addr, file)
	nodes_to_addr_file = open(file)
	while nodes_to_addr_line = nodes_to_addr_file.gets
		name_of_node, ip_addr_file = nodes_to_addr_line.split(" ")
		ip_addr_file.chomp!
		if(ip_addr == ip_addr_file)
			return name_of_node
		end
	end
end


def dijkstra (graph, src)
	dist = {}
	prev = {}
	visit = []
	route = {}

	graph.each_key{ |k| 
		dist[k] =  10000
		prev[k] = nil
		visit.push(k)
	}

	dist[src] = 0

	while !visit.empty? 
		u = minDist(visit,dist)
		visit.delete(u)
		graph[u].each { |k,v|
	
			alt = dist[u] + v
			if alt < dist[k] then
				dist[k] = alt
				prev[k] = u
	 		end
	 	}
	end

	
	graph.each_key{|k|
		check = k
		neighbor = false
		if k == src then
			route[k] = { k => dist[k]}
		elsif prev[k] == src then
			route[k] = { k => dist[k]}
		else
			while neighbor == false do
				graph[src].each_key{ |neigh|
					if prev[check] == neigh then
						neighbor = true
					end
				}
				check = prev[check]
			end
			route[k]= {check => dist[k]}
		end
	}

	return route
end

def minDist (x,dist)

	max_dist = 10000
	node = nil
	x.each { |k|
		if dist[k] < max_dist then
			max_dist = dist[k]
			node = k
		end
	}

	return node
end


# Variables
threads = Array.new
nodes = Array.new

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

routing_path_line = config_file.gets
routing_path_line.chomp!

dump_interval = config_file.gets
dump_interval.chomp!
dump_interval = dump_interval.to_i

# Get ip addresses assoc with the node
while nodes_to_addr_line = nodes_to_addr_file.gets
	name_of_node, ip_addr = nodes_to_addr_line.split(" ")
	if(nodes.include?(name_of_node) == false)
		nodes.push(name_of_node)
	end
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
		n = get_name(dest_node, node_line)
		node.add_topo(node.name,n, c)
	end
end

nodes_to_addr_file.close
link_file.close


# Recieving Thread
threads << Thread.new do
	srv_sock = TCPServer.open(9999)
	recv_length = 255
	while(1)
		data = ""
		client = srv_sock.accept
		while(tmp = client.recv(recv_length))
			data += tmp
			break if tmp.length < recv_length
		end

		packet = YAML::load(data)
		if(packet.msg_type == "LINK_PACKET")
			if(node.seq_hash[packet.source] != packet.seq_num)

				# Updates the seq num for the source
				node.seq_hash[packet.source] = packet.seq_num

				# Updates nodes topo table with packets
				packet.topo_hash.each_key{ |source|
					packet.topo_hash[source].each{ |dest, cost|
						node.add_topo(source,dest,cost)
					}
				}

				# Send recieved packet out to neighbors
				recv_serialized_obj = YAML::dump(packet)
				node.adj_hash.each_key{ |neighbor|
					name_of_neighbor = get_name(neighbor, node_line)
					if(packet.source != name_of_neighbor)
						recv_sockfd = TCPSocket.open(neighbor, 9999)
						recv_sockfd.send(recv_serialized_obj, 0)
						recv_sockfd.close
					end
				}
			end
		end
	end
end

stop_writing = false
init = true

# Routing Thread
threads << Thread.new do
	while(1)
		flag = false
		sleep(5)
		if(node.file_has_changed(link_file))
			flag = true
			puts "MADE IT"
		end
		if(flag == true || init == true)
			init = false
			if(flag == true)
				link_file = open(link_line)
				while line = link_file.gets
					source_node, dest_node, cost = line.split(" ")
					if(node.ip_addrs.include?(source_node))
						c = cost.to_i
						node.add_neighbor(dest_node, c)
						n = get_name(dest_node, node_line)	
						@lock.synchronize{
							node.add_topo(node.name,n, c)
						}
					end
				end
				link_file.close
			end 
			node.adj_hash.each_key{ |neighbor|
				out_packet = Packet.new("LINK_PACKET", node.name, neighbor, node.topo_hash,"THIS IS A TEST")
				serialized_obj = YAML::dump(out_packet)
				sockfd = TCPSocket.open(neighbor, 9999)
				sockfd.send(serialized_obj, 0)
				sockfd.close
			}
		end
		
	end
end

# Dump Thread
threads << Thread.new do
	while(1)
		stop_writing = false
		sleep(dump_interval)
		if(stop_writing == false)
			stop_writing = true
			str = ""
			
			@lock.synchronize{
				route = dijkstra(node.topo_hash, node.name)
			}
			
			path = routing_path_line + "/" + "routing_table_#{node.name}.txt"
			f = File.open(path, "w")
			str = ""
			route.each_key{ |dest|
				str += node.name + "," + dest + ","
				route[dest].each{ |nextHop,cost|
					str += cost.to_s + "," + nextHop + "\n"
				}
			}
			f.write(str)
			f.close()
		end
	end
end

threads.each{ |t|
	t.join
}






































