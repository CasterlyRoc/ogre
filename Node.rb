require 'socket'

class Packet

	attr_accessor :name,:number

	def initialize(name, number)
		@name = name
		@number = number
	end

end