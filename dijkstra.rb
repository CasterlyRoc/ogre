def minDist (x)

	max_dist = Float::INFINITY
	node = nil
	x.each {|k,v| 
		if v < max_dist then
			max_dist = v
			node = k
	}

	return node
end

def dijkstra (graph, src)
	dist = {}
	prev = {}
	visit = []

	graph.each_key{ |k| 
		dist[k] =  Float::INFINITY
		prev[k] = nil
		visit.push(k)
	 }

	 dist[src] = 0

	 while !visit.empty? 
	 	u = minDist(dist)
	 	visit.delete(u)

	 	graph[u].each_key{ |k,v|
	 		alt = dist[u] + v
	 		if alt < dist[k] then
	 			dist[k] = alt
	 			prev[k] = u
	 		end
	 	}
	 end
end