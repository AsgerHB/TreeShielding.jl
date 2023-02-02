# It's a bit barren now, but I hope to add more pruning tricks.

"""
    prune!(tree::Tree)

Attempt to remove redundant leaves from the tree.
"""
function prune!(tree::Tree)
	changes_made = 0

    # If a node heas two leaves and they have the same value, replace it with a single leaf.
	for leaf in Leaves(tree)
		if node.parent.lt != node
			continue
		elseif !(leaf.parent.geq isa Leaf)
			continue
		end

		if leaf.parent.geq.value == leaf.value
			replace_subtree!(leaf.parent, Leaf(leaf.value))
			changes_made += 1
		end
	end

	if changes_made > 0
		prune!(tree)
	end
	tree
end