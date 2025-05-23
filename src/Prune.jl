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

		if leaf.parent.lt.value == leaf.parent.geq.value
			node = merge!(leaf.parent.lt, leaf.parent.geq, m)
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

function merge!(a::Leaf, b::Leaf, m::ShieldingModel)
	@assert a.value == b.value
	@assert !isequal(a, b)
	@assert isequal(a.parent, b.parent)
	new = Leaf(a.value)
	replace_subtree!(a.parent, new)

	# Set `new.reachable`. Reachable leaves is the union of reachable leaves by a and b
	if m.reachability_caching ∈ [dependency_graph, one_way]
		clear_reachable!(new, m)
		for (action_index, _) in enumerate(a.reachable)
			new.reachable[action_index] = a.reachable[action_index] ∪ b.reachable[action_index]

			# If either cell can reach itself, new cell can reach itself.
			if a ∈ new.reachable || b ∈ new.reachable
				delete!(new.reachabe, a)
				delete!(new.reachabe, b)
				push!(new.reachable, new)
			end
		end
	end

	# Set `incoming` of leaves reached by a or b.
	if m.reachability_caching == dependency_graph
		# a.reachable is grouped by actions but we don't care here.
		for l in (a.reachable, b.reachable) |> Iterators.flatten |> Iterators.flatten |> Set
			if a ∈ l.incoming
				delete!(l.incoming, a)
				push!(l.incoming, new)
			end
			if b ∈ l.incoming
				delete!(l.incoming, b)
				push!(l.incoming, new)
			end
		end
	end

	# Set `new.incoming`. Incoming leaves is the union of incoming leaves from a and b
	if m.reachability_caching == dependency_graph
		incoming = a.incoming ∪ b.incoming
		new.incoming = incoming

		# Replace a and b, in the reachability cache of incoming nodes, with the new node
		for l in incoming
			for leaves in l.reachable
				for (i, l′) in enumerate(leaves)
					if isequal(l′, a) || isequal(l′, b)
						delete!(leaves, l′)
						push!(leaves, new)
					end
				end
			end
		end

		# Replace `a` and `b` with `new` in `new.incoming`.
		if a ∈ new.incoming || b ∈ new.incoming
			delete!(new.incoming, a)
			delete!(new.incoming, b)
			push!(new.incoming, new)
		end
	end

	# Idk how to optimize out asserts, so I'm just commenting these out lol
	#@assert well_formed(new.parent)
	#@assert no_orphans_in_cache(get_root(new))
end