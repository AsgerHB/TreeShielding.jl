@enum Direction safe_above_threshold safe_below_threshold

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
function compute_safety(tree::Tree, points, m)
    unsafe_value = actions_to_int([]) # The value for states where no actions are allowed.
	result = []
	for p in points
        safe = false
        for a in m.action_space
            p′ = m.simulation_function(p, a)
            safe = safe || (get_value(tree, p′) != unsafe_value)
        end
        push!(result, (p, safe))
	end
	result
end

"""
    get_safety_bounds(tree, bounds, m::ShieldingModel)

From a set of `SupportingPoints` defined by the arguments, return bounds which cover safe and unsafe areas within the initial set of `bounds`.

**Returns:** A `(safe, unsafe)` tuple of bounds, which cover (but might not exclusively contain) all safe and unsafe points.

***Args:**
 - `tree` Tree defining safe and unsafe regions.
 - `bounds` The set of bounds used for the `SupportingPoints`. Presumably they represent a leaf.
"""
function get_safety_bounds(tree, bounds, m::ShieldingModel)

	no_action = actions_to_int([])
	dimensionality = get_dim(bounds)

	min_safe = [Inf for _ in 1:dimensionality]
	max_safe = [-Inf for _ in 1:dimensionality]
	min_unsafe = [Inf for _ in 1:dimensionality]
	max_unsafe = [-Inf for _ in 1:dimensionality]

	for point in SupportingPoints(m.samples_per_axis, bounds)
		safe = false

		for action in m.action_space
			point′ = m.simulation_function(point, action)
			if get_value(tree, point′) != no_action
				safe = true
			end
		end

		if safe
			for axis in 1:dimensionality
				if min_safe[axis] > point[axis]
					min_safe[axis] = point[axis]
				end
				if max_safe[axis] < point[axis]
					max_safe[axis] = point[axis]
				end
			end
		else
			for axis in 1:dimensionality
				if min_unsafe[axis] > point[axis]
					min_unsafe[axis] = point[axis]
				end
				if max_unsafe[axis] < point[axis]
					max_unsafe[axis] = point[axis]
				end
			end
		end
	end

	safe, unsafe = Bounds(min_safe, max_safe), Bounds(min_unsafe, max_unsafe)
    return safe, unsafe
end

function get_equivalence_bounds(tree, bounds, m::ShieldingModel)

	no_action = actions_to_int([])
	dimensionality = get_dim(bounds)

	min_safe = Dict(a => [Inf for _ in 1:dimensionality] for a in m.action_space)
	max_safe = Dict(a => [-Inf for _ in 1:dimensionality] for a in m.action_space)
	min_unsafe = Dict(a => [Inf for _ in 1:dimensionality] for a in m.action_space)
	max_unsafe = Dict(a => [-Inf for _ in 1:dimensionality] for a in m.action_space)

	for point in SupportingPoints(m.samples_per_axis, bounds)
		
		for action in m.action_space
			point′ = m.simulation_function(point, action)
			safe = get_value(tree, point′) != no_action

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

function get_dividing_bounds(tree::Tree, bounds::Bounds, axis, action, direction::Direction, m::ShieldingModel)
	safe, unsafe = get_equivalence_bounds(tree, bounds, m)
	
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
	end

	m.verbose && @info "Found dividing bounds $dividing_bounds $iterations iterations" axis direction

	# It is not known whether the points inside dividing_bounds are safe
	# But it is known that all points to one side of dividing_bounds are.
	# Threshold should be the last value known to be safe.
	# If all points greater than the dividing_bounds are safe, 
	# then the uppper bound is the last set of points known to be safe. Otherwise it is the lower.
	threshold = direction == safe_above_threshold ? dividing_bounds.upper[axis] : dividing_bounds.lower[axis]
	
	m.verbose && @info "Resolved to threshold $threshold" axis direction

	# Apply safety margin
	if 	direction == safe_above_threshold
		threshold = min(threshold + m.margin, bounds.upper[axis])
	else
		threshold = max(threshold - m.margin, bounds.lower[axis])
	end
	
	m.verbose && @info "Applied safety margin.   Threshold is now $threshold."  axis direction threshold margin=m.margin

	# Apply min_granularity
	min_granularity_boost = 1.05 # Just to be absolutely sure that the double-precision result will be greater than min_granularity
	threshold = min(threshold, bounds.upper[axis] - m.min_granularity*min_granularity_boost)
	threshold = max(threshold, bounds.lower[axis] + m.min_granularity*min_granularity_boost)
	m.verbose && @info "Applied min_granularity. Threshold is now $threshold." axis direction threshold min_granularity=m.min_granularity

	# Check against min_granularity
	# Because maybe the partition was already as small as could be.
	if bounds.upper[axis] - threshold < m.min_granularity || 
       threshold - bounds.lower[axis] < m.min_granularity
		
		m.verbose && @info "Skipping split since it exceeds min_granularity" axis direction threshold min_granularity=m.min_granularity
        return nothing
	end
	
	# We don't want to split right on top of a previous split
	if ≈(threshold, bounds.lower[axis], atol=m.splitting_tolerance) || 
	   ≈(threshold, bounds.upper[axis], atol=m.splitting_tolerance)
	   m.verbose && @info "Skipping split since it's on top of a previous one"  axis direction threshold bounds
		return nothing
	end

	@assert bounds.lower[axis] < threshold < bounds.upper[axis] "$(bounds.lower[axis]) < $threshold < $(bounds.upper[axis])"
	
	return threshold
end

"""
    get_split(root::Tree, leaf::Leaf, m::ShieldingModel)


Finds an `(axis, threshold)` pair where a split can be made such that all partitions to one side of the split are safe, and some partitions to the other side are unsafe.

Finds the tightest such threshold within `m.splitting_tolerance`.
   
**Returns:** `(axis, threshold)` named tuple
"""
function get_split(root::Tree, leaf::Leaf, m::ShieldingModel)
	leaf.value == actions_to_int([]) && return nothing, nothing
    bounds = get_bounds(leaf, m.dimensionality)
	!bounded(bounds) && return nothing, nothing

	m.verbose && @info "Trying to split partition $bounds"

	threshold = nothing
	axis = 1
	for i in 1:m.dimensionality
		m.verbose && @info "Trying axis $i"
		axis = i
		if bounds.upper[axis] - bounds.lower[axis] <= m.min_granularity*2
			m.verbose && @info "Split would be less than min_granularity" min_granularity=m.min_granularity
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


"""
    grow!(tree::Tree, m::ShieldingModel)

Grow the entire tree by calling `split_all!` on all leaves, until no more changes can be made, or `max_iterations` is exceeded.

Note that the number of resulting leaves is potentially exponential in the number of iterations. Therefore, setting a suitably high `min_granularity` and a suitably low `max_iterations` is adviced.

**Returns:** The number of leaves in the resulting tree.

**Args:**
 - `tree` Tree to modify.
"""
function grow!(tree::Tree, m::ShieldingModel)

	no_action = actions_to_int([])
	changes_made = 1 # just to enter loop
    leaf_count = 0
	max_iterations = m.max_iterations
	while changes_made > 0
		if (max_iterations -= 1) < 0
			@warn "Max iterations reached while growing tree."
			break
		end
		
		changes_made = 0
		queue = collect(Leaves(tree))
        leaf_count = length(queue)
		for leaf in queue

			leaf.value == no_action && continue

			axis, threshold = get_split(tree, leaf, m)

			if threshold !== nothing
				split!(leaf, axis, threshold)

				m.verbose && @info "Performed split."
				
				changes_made += 1
                leaf_count += 1 # One leaf was removed, two leaves were added.
            end
		end
	end
	leaf_count
end