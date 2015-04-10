require 'socket'
require 'yaml'

# Git commands to update project on Github
# git stage (name of file you updated)
# git commit -m 'What you changed'
# git push origin master

class Packet

	attr_accessor:msg_type,:seq_num,:source,:dest,:adj_hash,:data

	def initialize(type, source, dest, data)
		@msg_type = type
		@seq_num = 1
		@source = source
		@dest = dest
		@adj_hash = Hash.new
		@data = data
	end

	def to_s
		"#{msg_type}, #{seq_num}, #{source}, #{dest}, #{data}"
	end

end

class Node

	attr_accessor:name,:ip_addrs

end

# Execute hostname to get name
# Look up node's IP address with name
# Find neighbors and cost

