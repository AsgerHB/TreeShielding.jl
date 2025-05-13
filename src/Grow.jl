@enum Direction::Int safe_above_threshold safe_below_threshold

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


"""
    grow!(tree::Tree, m::ShieldingModel)

Grow the entire tree by calling `split_all!` on all leaves, until no more changes can be made, or `max_iterations` is exceeded.

Note that the number of resulting leaves is potentially exponential in the number of iterations. Therefore, setting a suitably high `granularity` and a suitably low `max_iterations` is adviced.

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