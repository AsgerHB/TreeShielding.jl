
"""
    compute_safety(tree::Tree, simulation_function, action_space, points)

Helper function for visualisation. 
For each point, use the `simulation_function` to check if it would end up in an unsafe place according to `tree`. 

**Returns:** List of (point, bool)-tuples indicating wheter each point is safe. I.e it ends up in an unsafe place.

**Args:**
 - `tree` Defines the set of safe and unsafe states.
 - `simulation_function` A function `f(state, action)` which returns the resulting state.
 - `action_space` The possible actions to provide `simulation_function`. 
 - `points` This is the set of points.
"""
function compute_safety(tree::Tree, bounds::Bounds, m)
    unsafe_value = actions_to_int([]) # The value for states where no actions are allowed.
    result = []
    for (p, r) in all_supporting_points(bounds, m)
        safe = false
        for a in m.action_space
            p′ = m.simulation_function(p, r, a)
            safe = safe || (get_value(tree, p′) != unsafe_value)
        end
        push!(result, (p, safe))
    end
    result
end


"""
    grow!(tree::Tree, m::ShieldingModel)

Grow the entire tree by calling `split_all!` on all leaves, until no more changes can be made, or `max_iterations` is exceeded.

Note that the number of resulting leaves is potentially exponential in the number of iterations. Therefore, setting a suitably high `granularity` and a suitably low `max_iterations` is adviced.

- `animation_callback`: Function on the form animation_callback(tree::Tree). Use to create a step-by-step animation. Mind that this can be extremely slow.

**Returns:** The number of leaves in the resulting tree.

**Args:**
 - `tree` Tree to modify.
"""

const no_action = actions_to_int([])
function grow!(tree::Tree, m::ShieldingModel; animation_callback=nothing)

    stack = Tree[tree]
    loop_break = 10000000
    while !isempty(stack) && loop_break > 0
        loop_break -= 1
        node = pop!(stack)
        if node isa Node
            push!(stack, node.lt)
            push!(stack, node.geq)
        elseif node isa Leaf
            leaf = node
            leaf.value == no_action && continue
            homogenous(tree, leaf, m) && continue

            split_result = leaf

            if m.grow_method == caap_split
                split_result = try_split_caap!(tree, leaf, m)
            elseif m.grow_method == plus
                split_result = try_split_plus!(tree, leaf, m)
            elseif m.grow_method == minus
                split_result = try_split_minus!(tree, leaf, m)
            elseif m.grow_method == smart_minus
                split_result = try_split_smart_minus!(tree, leaf, m)
            elseif m.grow_method == binary_search
                split_result = try_split_binary_search!(tree, leaf, m)
            elseif m.grow_method == binary_search_minus_fallback
                split_result = try_split_binary_search_minus_fallback!(tree, leaf, m)
            else
                error("Unexpected growing method $(m.grow_method)")
            end

            if split_result isa Node
                push!(stack, split_result)
                if !isnothing(animation_callback); animation_callback(tree) end
            end
        else
            error("Uexpected node type")
        end
    end
    if loop_break <= 0
        @warn "Loop was cancelled early! Not done! Due to loop_break."
    end
end

###############################################
#region try_split_caap!

function try_split_caap!(tree::Tree, leaf::Leaf, m::ShieldingModel)
    error("Not implemented")
end

#endregion
###############################################

###############################################
#region try_split_plus!

"""
	try_split_plus!(leaf::Leaf, m::ShieldingModel)

Perform a "plus shaped" split, such that the leaf is split down the middle of each axis.

If the dimensionality is `n` then this creates `2^n` new leaves.
"""
function try_split_plus!(tree::Tree, leaf::Leaf, m::ShieldingModel)

	queue = Leaf[leaf]
	result = leaf
	for axis in 1:m.dimensionality
		queue′ = Leaf[]
		while length(queue) > 0
			l = pop!(queue)
			bounds = get_bounds(l, m.dimensionality)
            !bounded(bounds) && continue
			width = bounds.upper[axis] - bounds.lower[axis]
            @assert width != NaN
            @assert width != Inf
			if width/2 < m.granularity
				continue
			end
			threshold = bounds.lower[axis] + width/2
            @assert threshold != Inf
			node = split!(l, axis, threshold)
			if result == leaf
				result = node
			end
			push!(queue′, node.lt)
			push!(queue′, node.geq)
		end
		queue = queue′
	end
    if result isa Node
        clear_reachable!(result, m)
    end
	return result
end;


"""
	homogenous(root::Tree, leaf::Tree, m::ShieldingModel)

Check if all samples within the bounds of `leaf` are homogenous in terms of which actions are safe. That is, the function returns true if all samples in the partition have the same set of safe actions, and false otherwise.

This is used to determine whether it makes sense to split the leaf further.
"""
function homogenous(tree::Tree, leaf::Tree, m::ShieldingModel)
	clear_reachable!(leaf, m)
	no_action = actions_to_int([])
	bounds = get_bounds(leaf, m.dimensionality)
	actions_allowed = nothing
	for p in SupportingPoints(m.samples_per_axis, bounds)
		actions_allowed′ = []
		action_index = 1
		for a in m.action_space
			action_safe = true
			
			for r in SupportingPoints(m.samples_per_axis, 
				m.random_variable_bounds)
				
				p′ = m.simulation_function(p, r, a)
				push!(leaf.reachable[action_index], get_leaf(tree, p′))
				leaf′ = get_leaf(tree, p′)
				action_safe = action_safe && get_value(leaf′) != no_action
				!action_safe && break
			end
			if action_safe
				push!(actions_allowed′, a)
			end
			action_index += 1
		end
		if isnothing(actions_allowed)
			actions_allowed = actions_allowed′
		elseif actions_allowed != actions_allowed′
                leaf.dirty = true
				return false
		end
	end
    leaf.dirty =  false
	return true
end;

#endregion
###############################################

###############################################
#region try_split_minus!

function try_split_minus!(tree::Tree, leaf::Leaf, m::ShieldingModel)
    error("Not implemented")
end

#endregion
###############################################

###############################################
#region try_split_smart_minus!

function try_split_smart_minus!(tree::Tree, leaf::Leaf, m::ShieldingModel)
    error("Not implemented")
end

#endregion
###############################################
###############################################
#region try_split_binary_search_minus_fallback!

function try_split_binary_search_minus_fallback!(tree::Tree, leaf::Leaf, m::ShieldingModel)
    error("Not implemented")
end

#endregion
###############################################



#########################
#region binary_search

function try_split_binary_search!(tree::Tree, leaf::Leaf, m::ShieldingModel)

    axis, threshold = get_split_by_binary_search(tree, leaf, m)

    if threshold !== nothing
        new_tree = split!(leaf, axis, threshold)
        clear_reachable!(new_tree, m)

        m.verbose && @info "Performed split."

        return new_tree
    end

    return leaf
end


"""
    get_action_safety_bounds(tree, bounds, m::ShieldingModel)

Used by `get_dividing_bounds`.
This is nearly impossible to explain. It works, but has bad intuition.
Uses samples given by `m` within `bounds`. 

Computes bounds for each action, which covers every sample for which that action was safe. 
And vice versa, it computes the bounds for every sample for which the action is unsafe.

Returns the tuple `(safe, unsafe)` which are both `action => bounds` dictionaries.
"""
function get_action_safety_bounds(tree, bounds, m::ShieldingModel)

    no_action = actions_to_int([])
    dimensionality = get_dim(bounds)

    min_safe = Dict(a => [Inf for _ in 1:dimensionality] for a in m.action_space)
    max_safe = Dict(a => [-Inf for _ in 1:dimensionality] for a in m.action_space)
    min_unsafe = Dict(a => [Inf for _ in 1:dimensionality] for a in m.action_space)
    max_unsafe = Dict(a => [-Inf for _ in 1:dimensionality] for a in m.action_space)

    for point in SupportingPoints(m.samples_per_axis, bounds)
        
        for action in m.action_space
            safe = true
            for random_variables in SupportingPoints(m.samples_per_axis, m.random_variable_bounds)
                point′ = m.simulation_function(point, random_variables, action)
                safe = safe && get_value(tree, point′) != no_action
            end

            if safe
                for axis in 1:dimensionality
                    if min_safe[action][axis] > point[axis]
                        min_safe[action][axis] = point[axis]
                    end
                    if max_safe[action][axis] < point[axis]
                        max_safe[action][axis] = point[axis]
                    end
                end
            else
                for axis in 1:dimensionality
                    if min_unsafe[action][axis] > point[axis]
                        min_unsafe[action][axis] = point[axis]
                    end
                    if max_unsafe[action][axis] < point[axis]
                        max_unsafe[action][axis] = point[axis]
                    end
                end
            end
        end
    end

    safe = Dict(a => Bounds(min_safe[a], max_safe[a]) for a in m.action_space)
    unsafe = Dict(a => Bounds(min_unsafe[a], max_unsafe[a]) for a in m.action_space)
    return safe, unsafe
end

@enum Direction::Int safe_above_threshold safe_below_threshold

"""
    get_dividing_bounds(tree::Tree, bounds::Bounds, axis, action, direction::Direction, m::ShieldingModel)

Single computation step in getting a dividing threshold. Pardon the imprecise language; it might be better visualized in the `Grow.jl` notebook.
Bases itself off of the samples defined by `m` taken within `bounds`. 

For a given action and direciton, returns a result of type `Bounds`. 
The result represents an area which divides the samples along `axis`, such that on one side of the bound *all samples consider the action safe.* 
The "safe" side includes as many samples as possible. Additinoally, the bound stretches between the last safe samples and the first unsafe samples.
"""
function get_dividing_bounds(tree::Tree, bounds::Bounds, axis, action, direction::Direction, m::ShieldingModel)
    safe, unsafe = get_action_safety_bounds(tree, bounds, m)
    
    m.verbose && @info @sprintf "action: %s\nsafe:   ]%-+0.05f; %-+0.05f] \nunsafe: ]%-+0.05f; %-+0.05f]" "$action" safe[action].lower[axis] safe[action].upper[axis] unsafe[action].lower[axis] unsafe[action].upper[axis]
    if !bounded(safe[action]) || !bounded(unsafe[action])
        m.verbose && @info "No dividing_bounds exist for $action."
        return nothing
    end

    offset = get_spacing_sizes(SupportingPoints(m.samples_per_axis, bounds), 
        m.dimensionality)

    threshold = nothing
    gt_is_safe = nothing
    dividing_bounds = deepcopy(bounds)
    
    if direction == safe_below_threshold && 
        (unsafe[action].lower[axis]  - offset[axis] > safe[action].lower[axis] ||
        unsafe[action].lower[axis]  - offset[axis] ≈ safe[action].lower[axis])
        
        threshold = unsafe[action].lower[axis] - offset[axis]
        gt_is_safe = false
        
        dividing_bounds.lower[axis] = threshold
        dividing_bounds.upper[axis] = threshold + offset[axis]
        
    elseif direction == safe_above_threshold &&
        (unsafe[action].upper[axis]  + offset[axis] < safe[action].upper[axis] ||
        unsafe[action].upper[axis]  + offset[axis] ≈ safe[action].upper[axis])
        
        threshold = unsafe[action].upper[axis] + offset[axis]
        gt_is_safe = true
        
        dividing_bounds.lower[axis] = threshold - offset[axis]
        dividing_bounds.upper[axis] = threshold
    else
        m.verbose && @info "No dividing_bounds exist for $action."
        return nothing
    end

    return dividing_bounds
end

function get_threshold(tree::Tree, bounds::Bounds, axis, action, direction::Direction, m::ShieldingModel)
    dividing_bounds = get_dividing_bounds(tree, bounds, axis, action, direction, m)

    if dividing_bounds === nothing
        m.verbose && @info "Skipping split at axis $axis since no dividing bounds were found."
        return nothing
    end

    # Mainmatter. Keep refining the threshold until splitting_tolerance is reached.
    iterations = 0
    while dividing_bounds.upper[axis] - dividing_bounds.lower[axis] > m.splitting_tolerance
        (iterations += 1) >= 100 &&	(@warn "Maximum iterations exceeded while refining threshold"; break)
        
        dividing_bounds = get_dividing_bounds(tree, dividing_bounds, axis, action, direction, m)

        if dividing_bounds === nothing
            m.verbose && @warn "Looks like it gave up at some point trying to refine the bounds. I am concerned with the fact that this can happen."
            return nothing
        end
    end

    m.verbose && @info "Found dividing bounds $dividing_bounds $iterations iterations" axis direction

    # It is not known whether the points inside dividing_bounds are safe
    # But it is known that all points to one side of dividing_bounds are.
    # Threshold should be the last value known to be safe.
    # If all points greater than the dividing_bounds are safe, 
    # then the uppper bound is the last set of points known to be safe. Otherwise it is the lower.
    threshold = direction == safe_above_threshold ? dividing_bounds.upper[axis] : dividing_bounds.lower[axis]
    
    m.verbose && @info "Resolved to threshold $threshold" axis direction

    # Apply granularity
    if m.granularity != 0
        # Trust me on this. 
        if direction == safe_above_threshold
            if threshold > 0
                threshold = threshold - threshold%m.granularity + m.granularity
            else
                threshold = threshold - threshold%m.granularity
            end
        else
            if threshold > 0
                threshold = threshold - threshold%m.granularity
            else
                threshold = threshold - threshold%m.granularity - m.granularity
            end
        end
        m.verbose && @info "Applied granularity. Threshold is now $threshold." axis direction threshold granularity=m.granularity
        @assert (abs(threshold%m.granularity) < 1E-10) || (abs(threshold%m.granularity) ≈ m.granularity) "Somehow got $threshold which is inconsistent with granularity $(m.granularity)"
    end
    
    # We don't want to split right on top of a previous split
    if ≈(threshold, bounds.lower[axis], atol=m.splitting_tolerance) || 
       ≈(threshold, bounds.upper[axis], atol=m.splitting_tolerance)
       m.verbose && @info "Skipping split since it's on top of a previous one"  axis direction threshold bounds
        return nothing
    end

    @assert bounds.lower[axis] < threshold < bounds.upper[axis] "Threshold out of bounds: $(bounds.lower[axis]) < $threshold < $(bounds.upper[axis])"
    
    return threshold
end

"""
    get_split_by_binary_search(root::Tree, leaf::Leaf, m::ShieldingModel)


Finds an `(axis, threshold)` pair where a split can be made such that all partitions to one side of the split are safe, and some partitions to the other side are unsafe.

Finds the tightest such threshold within `m.splitting_tolerance`.
   
**Returns:** `(axis, threshold)` named tuple
"""
function get_split_by_binary_search(root::Tree, leaf::Leaf, m::ShieldingModel)
    leaf.value == actions_to_int([]) && return nothing, nothing
    bounds = get_bounds(leaf, m.dimensionality)
    !bounded(bounds) && return nothing, nothing

    m.verbose && @info "Trying to split partition $bounds"

    threshold = nothing
    axis = 1
    for i in 1:m.dimensionality
        m.verbose && @info "Trying axis $i"
        axis = i
        if bounds.upper[axis] - bounds.lower[axis] <= m.granularity*2
            m.verbose && @info "Split would be less than granularity" granularity=m.granularity
            continue
        end
        for action in m.action_space
            for direction in instances(Direction)
                m.verbose && @info "Trying direction $direction"
                threshold = get_threshold(root, bounds, axis, action, direction, m)
                if threshold !== nothing
                    @goto break_outer # Break out of both for-loops
                end
            end
        end
    end
    @label break_outer

    if threshold === nothing 
        m.verbose &&  @info "Leaf could not be split further" 
        return nothing, nothing
    end

    return (;axis, threshold)
end

#endregion
#########################

