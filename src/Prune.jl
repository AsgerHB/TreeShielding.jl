# It's a bit barren now, but I hope to add more pruning tricks.

"""
    prune!(tree::Tree)

Attempt to remove redundant leaves from the tree.

**Returns:** The number of changes made to the tree.
"""
function prune!(tree::Tree)
	changes_made = 0
    leaf_count = 0

    # If a node heas two leaves and they have the same value, replace it with a single leaf.
	for leaf in Leaves(tree)
        leaf_count += 1
		if leaf.parent.lt !== leaf
			continue
		elseif !(leaf.parent.geq isa Leaf)
			continue
		end

		if leaf.parent.geq.value == leaf.value
			replace_subtree!(leaf.parent, Leaf(leaf.value))
			changes_made += 1
            leaf_count -= 1
		end
	end

	if changes_made > 0
		return prune!(tree)
    else
        return leaf_count
    end
end