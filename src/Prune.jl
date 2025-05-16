"""
    prune!(tree::Tree; animation_callback)

Attempt to remove redundant leaves from the tree.

- `animation_callback`: Function on the form animation_callback(tree::Tree). Use to create a step-by-step animation. Mind that this can be extremely slow.

**Returns:** The number of changes made to the tree.
"""
function prune!(tree::Tree, m::ShieldingModel; animation_callback=nothing)
	if m.pruning == naïve
		return naïve_prune!(tree, m; animation_callback)
	elseif m.pruning == caap_reduction
		error("caap_reduction not implemented")
	elseif m.pruning == no_pruning
		return count([true for _ in Leaves(tree)])
	else
		error("Unexpected pruning: $(m.pruning)")
	end
end

function naïve_prune!(tree::Tree, m::ShieldingModel; animation_callback=nothing)
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
			node = replace_subtree!(leaf.parent, Leaf(leaf.value))
			clear_reachable!(node, m)
			changes_made += 1
            leaf_count -= 1

			if !isnothing(animation_callback); animation_callback(tree) end
		end
	end

	if changes_made > 0
		return prune!(tree, m)
    else
        return leaf_count
    end
end