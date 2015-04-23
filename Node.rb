require 'socket'
require 'thread'
require 'yaml'
require 'monitor'

# Authors: Zack Knopp, Kevin Gutierrez, Mike Bellistri

class Packet

	attr_accessor:msg_type,:seq_num,:source,:dest,:topo_hash,:data

	def initialize(type, source, dest, topo_hash, data)
		@msg_type = type
		@seq_num = 0
		@source = source
		@dest = dest
		@topo_hash = topo_hash
		@data = data
	end

end

class Node

	attr_accessor:name,:ip_addrs,:adj_hash,:seq_hash,:topo_hash,:lock,:routing_table,:circuit_table

	def initialize(name)
		@name = name
		@ip_addrs = Array.new
		@adj_hash = Hash.new
		@circuit_table = Hash.new
		@seq_hash = {name => 0}
		@routing_table = Hash.new
		@topo_hash = Hash.new
		@lock = Monitor.new
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

	def file_has_changed(file)
		has_changed = false
		f = open(file)
		while line = f.gets
			s, d, c = line.split(",")
			c = c.to_i
			#puts "#{s} #{d} #{c}"
			if(ip_addrs.include?(s) == true)
				if(adj_hash[d] != c)
					has_changed = true
				end
			end
		end
		f.close
		return has_changed
	end

	def add_route(route_name, sock_fd)require 'socket'
require 'thread'
require 'yaml'
require 'monitor'

# Authors: Zack Knopp, Kevin Gutierrez, Mike Bellistri

class Packet

	attr_accessor:msg_type,:seq_num,:source,:dest,:topo_hash,:data

	def initialize(type, source, dest, topo_hash, data)
		@msg_type = type
		@seq_num = 0
		@source = source
		@dest = dest
		@topo_hash = topo_hash
		@data = data
	end

end

class Node

	attr_accessor:name,:ip_addrs,:adj_hash,:seq_hash,:topo_hash,:lock,:routing_table,:circuit_table

	def initialize(name)
		@name = name
		@ip_addrs = Array.new
		@adj_hash = Hash.new
		@circuit_table = Hash.new
		@seq_hash = {name => 0}
		@routing_table = Hash.new
		@topo_hash = Hash.new
		@lock = Monitor.new
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

	def file_has_changed(file)
		has_changed = false
		f = open(file)
		while line = f.gets
			s, d, c = line.split(",")
			c = c.to_i
			#puts "#{s} #{d} #{c}"
			if(ip_addrs.include?(s) == true)
				if(adj_hash[d] != c)
					has_changed = true
				end
			end
		end
		f.close
		return has_changed
	end

	def add_route(route_name, sock_fd)
		puts "MADE IT"
		@circuit_table[route_name] = sock_fd
	end
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

# Gets the ip address of the node given a node name
def get_ip(name, file)
	f = open(file)
	while line = f.gets
		name_of_node, ip_addr = line.split(" ")
		ip_addr.chomp!
		if(name == name_of_node)
			return ip_addr
		end
	end
end

#Shortest path algorithm
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
		else
			while neighbor == false do
				if prev[check] == src then
					neighbor = true
					next_h = check
				end
				check = prev[check]
			end
			route[k]= {next_h => dist[k]}
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

def calc_next_hop(node, dest_node, node_line)
	tmp = ""
	route = node.routing_table
	route.each_key{ |dest|
	if(dest_node == dest)
		next_hop = route[dest].keys.to_s
		tmp = next_hop
		end
	}
	next_hop = get_ip(tmp, node_line)
	return next_hop
end


# Variables
threads = Array.new

# Execute hostname to get name of the node
name_of_node = `hostname`
name_of_node.chomp!
node = Node.new(name_of_node)

# Process config file

config_file = open(ARGV[0])

max_size = config_file.gets
max_size.chomp!
max_size = max_size.to_i

node_line = config_file.gets
node_line.chomp!
nodes_to_addr_file = open(node_line)

link_line = config_file.gets
link_line.chomp!
link_file = open(link_line)

update_interval = config_file.gets
update_interval.chomp!
update_interval = update_interval.to_i

routing_path_line = config_file.gets
routing_path_line.chomp!

dump_interval = config_file.gets
dump_interval.chomp!
dump_interval = dump_interval.to_i

config_file.close

# Get ip addresses assoc with the node
while (nodes_to_addr_line = nodes_to_addr_file.gets)
	name_of_node, ip_addr = nodes_to_addr_line.split(" ")
	if(name_of_node == node.name)
		node.ip_addrs.push(ip_addr)
	end
end

# Get links between nodes and the cost
while (line = link_file.gets)
	source_node, dest_node, cost = line.split(",")
	if(node.ip_addrs.include?(source_node))
		cost = cost.to_i
		node.adj_hash[dest_node] = cost
		n = get_name(dest_node, node_line)
		node.add_topo(node.name,n,cost)
	end
end

nodes_to_addr_file.close
link_file.close

# Recieving Thread
threads << Thread.new do
	srv_sock = TCPServer.open(9999)
	recv_length = max_size
	while(1)
		data = ""
		client = srv_sock.accept
		while(tmp = client.recv(recv_length))
			data += tmp
			break if tmp.length < recv_length
		end

		packet = YAML::load(data)

		if(packet.msg_type == "LINK_PACKET")
			if(node.seq_hash[packet.source] == nil || node.seq_hash[packet.source] < packet.seq_num)

				# Updates the seq num for the source
				node.seq_hash[packet.source] = packet.seq_num

				# Updates nodes topo table with packets
				node.topo_hash[packet.source] = packet.topo_hash

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
		elsif(packet.msg_type == "CIRCUIT")
			puts "RECIEVED CIRCUIT"
			if(node.ip_addrs.include?(packet.dest) == false)
				dest_name = get_name(packet.dest, node_line)
				next_hop = calc_next_hop(node, dest_name, node_line)
				obj = YAML::dump(packet)
				sock = TCPSocket.open(next_hop, 9999)
				node.add_route(packet.dest, sock)
				sock.send(obj, 0)
			else
				puts "CIRCUIT PACKET HAS REACHED DESTINATION"
			end
		elsif(packet.msg_type == "SENDMSG")
			if(node.ip_addrs.include?(packet.dest) == false)
				puts "SENDMSG RECIEVED"
				obj = YAML::dump(packet)
				node.circuit_table[packet.dest].send(obj, 0)
				node.circuit_table[packet.dest].close
			else
				puts "SENDMSG HAS REACHED DESTINATION"
			end
		else

		end
			
	end
end

stop_writing = false
init = true

# Routing Thread
threads << Thread.new do
	sleep(20)
	while(1)
		flag = false
		sleep(update_interval)

		#Checks for topology change
		if(node.file_has_changed(link_line))
			flag = true
		end
	
		if(init == true || flag == true)
			init = false

			#If topology changed found update topology hash
			if(flag == true && init == false)
				link_file = File.open(link_line)
				while (line = link_file.gets)
					source_node, dest_node, cost = line.split(",")
					if(node.ip_addrs.include?(source_node))
						cost = cost.to_i
						node.adj_hash[dest_node] = cost
						n = get_name(dest_node, node_line)
						node.add_topo(node.name,n,cost)
					end
				end
				link_file.close
			end

			#Sends Link State Packet to neighbors
			node.adj_hash.each_key{ |neighbor|
				out_packet = Packet.new("LINK_PACKET", node.name, neighbor, node.topo_hash[node.name],"THIS IS A TEST")
				out_packet.seq_num = node.seq_hash[node.name] + 1
				serialized_obj = YAML::dump(out_packet)
				sockfd = TCPSocket.open(neighbor, 9999)
				sockfd.send(serialized_obj, 0)
				sockfd.close
			}

			node.seq_hash[node.name] += 1

			#Update routing table
			sleep(10)
			route = dijkstra(node.topo_hash, node.name)
			node.routing_table = route
		end
		
	end
end

# Dump Thread
threads << Thread.new do
	sleep (update_interval+30)
	while(1)
		sleep(dump_interval)
		route = node.routing_table
		path = routing_path_line + "/routing_table_#{node.name}.txt"
		str = ""
		route.each_key{ |dest|
			str = str + "#{node.name},#{dest},"
			route[dest].each{ |nextHop,cost|
				str = str + "#{cost},#{nextHop}\n"
			}
		}
		f = File.open(path, 'w')
		f.write(str)
		f.close()
	end
end

# Sending Thread
threads << Thread.new do
	i = 1
	while(1)
		send_line = $stdin.gets.chomp
		tmp = ""
		msg_type, destination, message = send_line.split(" ")
		dest_node = get_name(destination, node_line)
		next_hop = calc_next_hop(node, dest_node, node_line)
		
		# Set up circuit packet
		out_packet = Packet.new("CIRCUIT", node.name, destination, nil, "")
		serialized_obj = YAML::dump(out_packet)
		send_sockfd = TCPSocket.open(next_hop, 9999)

		# Opens first circuit path
		node.add_route(destination, send_sockfd)
		send_sockfd.send(serialized_obj, 0)
		
		sleep(5)

		send_packet = Packet.new(msg_type, node.name, destination, nil, message)
		serialized_obj = YAML::dump(send_packet)
		send_sockfd.send(serialized_obj)
		send_sockfd.close
	end
end

threads.each{ |t|
	t.join
}










		puts "MADE IT"
		@circuit_table[route_name] = sock_fd
	end
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

# Gets the ip address of the node given a node name
def get_ip(name, file)
	f = open(file)
	while line = f.gets
		name_of_node, ip_addr = line.split(" ")
		ip_addr.chomp!
		if(name == name_of_node)
			return ip_addr
		end
	end
end

#Shortest path algorithm
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
		else
			while neighbor == false do
				if prev[check] == src then
					neighbor = true
					next_h = check
				end
				check = prev[check]
			end
			route[k]= {next_h => dist[k]}
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

def calc_next_hop(node, dest_node, node_line)
	tmp = ""
	route = node.routing_table
	route.each_key{ |dest|
	if(dest_node == dest)
		next_hop = route[dest].keys.to_s
		tmp = next_hop
		end
	}
	next_hop = get_ip(tmp, node_line)
	return next_hop
end


# Variables
threads = Array.new

# Execute hostname to get name of the node
name_of_node = `hostname`
name_of_node.chomp!
node = Node.new(name_of_node)

# Process config file

config_file = open(ARGV[0])

max_size = config_file.gets
max_size.chomp!
max_size = max_size.to_i

node_line = config_file.gets
node_line.chomp!
nodes_to_addr_file = open(node_line)

link_line = config_file.gets
link_line.chomp!
link_file = open(link_line)

update_interval = config_file.gets
update_interval.chomp!
update_interval = update_interval.to_i

routing_path_line = config_file.gets
routing_path_line.chomp!

dump_interval = config_file.gets
dump_interval.chomp!
dump_interval = dump_interval.to_i

config_file.close

# Get ip addresses assoc with the node
while (nodes_to_addr_line = nodes_to_addr_file.gets)
	name_of_node, ip_addr = nodes_to_addr_line.split(" ")
	if(name_of_node == node.name)
		node.ip_addrs.push(ip_addr)
	end
end

# Get links between nodes and the cost
while (line = link_file.gets)
	source_node, dest_node, cost = line.split(",")
	if(node.ip_addrs.include?(source_node))
		cost = cost.to_i
		node.adj_hash[dest_node] = cost
		n = get_name(dest_node, node_line)
		node.add_topo(node.name,n,cost)
	end
end

nodes_to_addr_file.close
link_file.close

# Recieving Thread
threads << Thread.new do
	srv_sock = TCPServer.open(9999)
	recv_length = max_size
	while(1)
		data = ""
		client = srv_sock.accept
		while(tmp = client.recv(recv_length))
			data += tmp
			break if tmp.length < recv_length
		end

		packet = YAML::load(data)

		if(packet.msg_type == "LINK_PACKET")
			if(node.seq_hash[packet.source] == nil || node.seq_hash[packet.source] < packet.seq_num)

				# Updates the seq num for the source
				node.seq_hash[packet.source] = packet.seq_num

				# Updates nodes topo table with packets
				node.topo_hash[packet.source] = packet.topo_hash

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
		elsif(packet.msg_type == "CIRCUIT")
			if(node.ip_addrs.include?(packet.dest) == false)
				dest_name = get_name(packet.dest, node_line)
				next_hop = calc_next_hop(node, dest_name, node_line)
				obj = YAML::dump(packet)
				sock = TCPSocket.open(next_hop, 9999)
				node.add_route(packet.dest, sock)
				sock.send(obj, 0)
			else
				puts "CIRCUIT PACKET HAS REACHED DESTINATION"
			end
		elsif(packet.msg_type == "SENDMSG")
			if(node.ip_addrs.include?(packet.dest) == false)
				puts "SENDMSG RECIEVED"
				obj = YAML::dump(packet)
				node.circuit_table[packet.dest].send(obj, 0)
				node.circuit_table[packet.dest].close
			else
				puts "SENDMSG HAS REACHED DESTINATION"
			end
		else

		end
			
	end
end

stop_writing = false
init = true

# Routing Thread
threads << Thread.new do
	sleep(20)
	while(1)
		flag = false
		sleep(update_interval)

		#Checks for topology change
		if(node.file_has_changed(link_line))
			flag = true
		end
	
		if(init == true || flag == true)
			init = false

			#If topology changed found update topology hash
			if(flag == true && init == false)
				link_file = File.open(link_line)
				while (line = link_file.gets)
					source_node, dest_node, cost = line.split(",")
					if(node.ip_addrs.include?(source_node))
						cost = cost.to_i
						node.adj_hash[dest_node] = cost
						n = get_name(dest_node, node_line)
						node.add_topo(node.name,n,cost)
					end
				end
				link_file.close
			end

			#Sends Link State Packet to neighbors
			node.adj_hash.each_key{ |neighbor|
				out_packet = Packet.new("LINK_PACKET", node.name, neighbor, node.topo_hash[node.name],"THIS IS A TEST")
				out_packet.seq_num = node.seq_hash[node.name] + 1
				serialized_obj = YAML::dump(out_packet)
				sockfd = TCPSocket.open(neighbor, 9999)
				sockfd.send(serialized_obj, 0)
				sockfd.close
			}

			node.seq_hash[node.name] += 1

			#Update routing table
			sleep(10)
			route = dijkstra(node.topo_hash, node.name)
			node.routing_table = route
		end
		
	end
end

# Dump Thread
threads << Thread.new do
	sleep (update_interval+30)
	while(1)
		sleep(dump_interval)
		route = node.routing_table
		path = routing_path_line + "/routing_table_#{node.name}.txt"
		str = ""
		route.each_key{ |dest|
			str = str + "#{node.name},#{dest},"
			route[dest].each{ |nextHop,cost|
				str = str + "#{cost},#{nextHop}\n"
			}
		}
		f = File.open(path, 'w')
		f.write(str)
		f.close()
	end
end

# Sending Thread
threads << Thread.new do
	i = 1
	while(1)
		send_line = $stdin.gets.chomp
		tmp = ""
		msg_type, destination, message = send_line.split(" ")
		dest_node = get_name(destination, node_line)
		next_hop = calc_next_hop(node, dest_node, node_line)

		# Get outgoing ip address
		link_file = open(link_line)
		while l = link_file.gets
			start_pt, end_pt, num = line.split(" ")
			if(end_pt == str)
				tmp = start_pt
				break
			end
		end
		
		# Set up circuit packet
		out_packet = Packet.new("CIRCUIT", node.name, destination, nil, "")
		serialized_obj = YAML::dump(out_packet)
		send_sockfd = TCPSocket.open(next_hop, 9999)

		# Opens first circuit path
		node.add_route(destination, send_sockfd)
		send_sockfd.send(serialized_obj, 0)
		
		sleep(5)

		send_packet = Packet.new(msg_type, node.name, destination, nil, message)
		serialized_obj = YAML::dump(send_packet)
		send_sockfd.send(serialized_obj)
		send_sockfd.close
	end
end

threads.each{ |t|
	t.join
}









