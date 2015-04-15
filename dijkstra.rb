
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

	 return dist, prev
end

def minDist (x,dist)

	max_dist = Float::INFINITY
	node = nil
	x.each { |k|
		if dist[k] < max_dist then
			max_dist = dist[k]
			node = k
		end
	}

	return node
end
