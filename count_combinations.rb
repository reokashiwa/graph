#!/Users/reo/.rbenv/shims/ruby
# coding: utf-8

def make_nodes(number)
  nodes = Array.new
  for i in 0...number do
    nodes[i] = {'id' => i}
  end
  return nodes
end


def generate_fullmesh(nodes)
  edges = Array.new
  i = 0
  for j in 0...nodes.length - 1 do
    for k in j + 1...nodes.length do
      edges << {'id' => i, 'src' => nodes[j]['id'], 'dst' => nodes[k]['id']}
      i = i + 1
    end
  end

  return edges
end

def recursive_failure(rest_failure_num, next_failure_start_from, edges_failured, topologies)
  if rest_failure_num == 0 then
    topologies << edges_failured
    return
  elsif next_failure_start_from > edges_failured.length - 1 then
    return
  else
    for i in next_failure_start_from...edges_failured.length do
      edges_failured_deleted = Marshal.load(Marshal.dump(edges_failured))
      edges_failured_deleted.delete_at(i)
      recursive_failure(rest_failure_num - 1, i, edges_failured_deleted, topologies)
    end
    return
  end
end

# edges_failureからid => next_failure_edge_id のハッシュが格納された要素を取り除く
# f_rest = f_rest - 1
# if f_rest == 0
# then return edges_failure
# else recursive_failure(f_rest, failure_edge_id + 1, edges_failured)

def clustering(nodes, edges)
  # nodesから1クラスタ1ノードからなるクラスタ配列を作る
  clusters = Array.new
  nodes.each{|node|
    cluster = Array.new
    cluster << node
    clusters << cluster
  }

  edges.each{|edge|
    src_index = nil
    dst_index = nil
    clusters.each_with_index{|cluster, index|
      cluster.each{|node|
        src_index = index if node['id'] == edge['src']
        dst_index = index if node['id'] == edge['dst']
        break if src_index && dst_index
      }
      break if src_index && dst_index
    }
    if src_index != dst_index
      clusters[src_index].concat(clusters[dst_index])
      clusters.delete_at(dst_index)
    end
  }
  return clusters
end

def analyse_clusters(clusters)
  count = Hash.new(0)
  clusters.each{|cluster|
    count[cluster.length] += 1
  }
  return count
end

def analyse_topology(nodes, topology)
  count = Hash.new(0)
  topology.each{|edges|
    # p edges
    clusters = clustering(nodes, edges)
    clusters_count = analyse_clusters(clusters)
    clusters_number = 0
    clusters_count.each{|key,value|
      clusters_number = clusters_number + value
    }
    count[clusters_number] += 1
  }
  return count
end

nodes = make_nodes(ARGV[0])
edges = generate_fullmesh(nodes)

topologies = Array.new
for f in 0..edges.length do
  topologies[f] = Array.new
  # 配列edgesの複製
  edges_failured = Marshal.load(Marshal.dump(edges))
  recursive_failure(f, 0, edges_failured, topologies[f])
end

total_count = 0
topologies.each_with_index{|topology,index|
  printf("%d\t", index)
  count = analyse_topology(nodes, topology)
  p count
  count.each{|key, value|
    total_count = total_count + value
  }
}
p total_count
