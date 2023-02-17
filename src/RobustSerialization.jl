function robust_serialize(dir, tree::Tree)
	list = []

	for node in PreOrderDFS(tree)
		if node isa Node
			node_info = :Node, node.axis, node.threshold
		elseif node isa Leaf
			node_info = :Leaf, node.value
		else
			error("Unexpected node type")
		end
		push!(list, node_info)
	end
	serialize(dir, list)
	list
end

function robust_deserialize(file_name)
	list = deserialize(file_name)
	convert_to_tree(list)
end

function convert_to_tree(list, index=1)
	node_info = list[index]
	if node_info[1] == :Leaf
		next_index = index + 1
		return next_index, Leaf(node_info[2])
	elseif node_info[1] == :Node
		next_index, left = convert_to_tree(list, index + 1)
		next_index, right = convert_to_tree(list, next_index)

		return next_index, Node(node_info[2], node_info[3], left, right)
	else
		error("Unsupported node type")
	end		
end
