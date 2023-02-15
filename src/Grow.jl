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
function compute_safety(tree::Tree, simulation_function, action_space::Type, points)
    compute_safety(tree::Tree, simulation_function, instances(action_space), points)
end

function compute_safety(tree::Tree, simulation_function, action_space, points)
    unsafe_value = actions_to_int([]) # The value for states where no actions are allowed.
	result = []
	for p in points
        safe = false
        for a in action_space
            p′ = simulation_function(p, a)
            safe = safe || (get_value(tree, p′) != unsafe_value)
        end
        push!(result, (p, safe))
	end
	result
end

"""
    safety_bounds(tree, bounds, m::ShieldingModel)

From a set of `SupportingPoints` defined by the arguments, return bounds which cover safe and unsafe areas within the initial set of `bounds`.

**Returns:** A `(safe, unsafe)` tuple of bounds, which cover (but might not exclusively contain) all safe and unsafe points.

***Args:**
 - `tree` Tree defining safe and unsafe regions.
 - `bounds` The set of bounds used for the `SupportingPoints`. Presumably they represent a leaf.
"""
function safety_bounds(tree, bounds, m::ShieldingModel)

	no_action = actions_to_int([])
	dimensionality = get_dim(bounds)

	min_safe = [Inf for _ in 1:dimensionality]
	max_safe = [-Inf for _ in 1:dimensionality]
	min_unsafe = [Inf for _ in 1:dimensionality]
	max_unsafe = [-Inf for _ in 1:dimensionality]

	for point in SupportingPoints(m.samples_per_axis, bounds)
		safe = false

		action_space = m.action_space
        if action_space isa Type
            action_space = instances(m.action_space)
        end
		for action in action_space
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

"""
    get_dividing_bounds(tree, 
        bounds,
        m,
        max_recursion_depth=nothing,
        verbose=false)

Recursively finds the best threshold, such that all points to one side of it are safe.

Taking as its arguments a set of bounds and the variables required to define supporting points, 
it returns the area between the last set of safe supporting points, and the unsafe ones. 

If it is not possible to make such a divisoin, it returns `nothing` instead.

This is easiest to see visualised in the `Grow.jl` notebook.

**Args:**
- `tree` Tree defining safe and unsafe regions.
- `bounds` The set of bounds used for the `SupportingPoints`.
"""
function get_dividing_bounds(tree, 
        bounds,
		axis,
        m,
        max_recursion_depth=nothing;
        verbose=false)

	max_recursion_depth = something(max_recursion_depth, m.max_recursion_depth)
	
	offset = get_spacing_sizes(SupportingPoints(m.samples_per_axis, bounds), 
		m.dimensionality)
	
	safe, unsafe = safety_bounds(tree, bounds, m)

	verbose && @info "safe: $safe \nunsafe: $unsafe"

	if !bounded(safe)
		verbose && @warn "No safe points found in partition."
		return nothing, nothing
	elseif !bounded(unsafe)
		verbose && @info "No unsafe points found in partition."
		return nothing, nothing
	end

	threshold = nothing
	safe_above = nothing
	bounds′ = deepcopy(bounds)
	
	if unsafe.lower[axis]  - offset[axis] > safe.lower[axis] ||
			unsafe.lower[axis]  - offset[axis] ≈ safe.lower[axis]
		
		threshold = unsafe.lower[axis] - offset[axis]
		safe_above = false
		
		bounds′.lower[axis] = threshold
		bounds′.upper[axis] = threshold + offset[axis]
		
	elseif unsafe.upper[axis]  + offset[axis] < safe.upper[axis] ||
			unsafe.upper[axis]  + offset[axis] ≈ safe.upper[axis]
		
		threshold = unsafe.upper[axis] + offset[axis]
		safe_above = true
		
		bounds′.lower[axis] = threshold - offset[axis]
		bounds′.upper[axis] = threshold
	else
		return nothing, nothing
	end

    if m.min_granularity > abs(bounds′.lower[axis] - bounds′.upper[axis])
        max_recursion_depth = 0
    end
	
	if max_recursion_depth < 1 
		verbose && @info "Found dividing bounds $bounds′"
		return safe_above, bounds′
	end
	return get_dividing_bounds(tree,
					bounds′,
					axis,
					m,
					max_recursion_depth - 1;
                    verbose)
end

"""
    get_threshold(tree::Tree, 
        bounds::Bounds,
		m::ShieldingModel,
        verbose=false)

Find a threshold along any axis, such that to one side all points are safe.

**Args:** 
- `tree` Tree defining safe and unsafe regions.
- `bounds` The set of bounds used for the `SupportingPoints`.
"""
function get_threshold(tree::Tree, 
        bounds::Bounds,
		m::ShieldingModel;
        verbose=false)

	for axis in 1:m.dimensionality
		safe_above, dividing_bounds = get_dividing_bounds(tree, bounds, axis, m; verbose)
		
	
		if safe_above === nothing
			continue
		elseif safe_above
			threshold = dividing_bounds.upper[axis] + m.margin
		else
			threshold = dividing_bounds.lower[axis] - m.margin
		end

		lower, upper = bounds.lower[axis], bounds.upper[axis]
		if  abs(threshold - lower) < m.min_granularity ||
			abs(threshold - upper) < m.min_granularity
			verbose && @info "Skipped a split that went below min_granularity."
			continue
		end

		return axis, threshold
	end

	return nothing, nothing
end


"""
    try_splitting!(leaf::Leaf, 
	    m::ShieldingModel,
		verbose=false)

Makes calls to `get_threshold` for each axis, and performs the first split which can be made. A split can be made if 

 - The leaf has at least one safe action it can take. Splitting unsafe partitions is useless.
 - The leaf is properly bounded. That is, its bounds are finite on all axes.
 - `get_threshold` returns something other than `nothing`, i.e. there exists a thereshold such that all points are safe on one side of it.
 - The threshold would not create a bound whose size is smaller than `min_granularity`.
   
**Returns:** `true` if a split is made, and `false` otherwise.

**Args:**
 - `leaf` This leaf will be split at the first axis where a division can be made between safe and unsafe points.
"""
function try_splitting!(leaf::Leaf, 
	    m::ShieldingModel,
		verbose=false)

    root = getroot(leaf)
    bounds = get_bounds(leaf, m.dimensionality)
    unsafe_value = actions_to_int([]) # The value for states where no actions are allowed.

    if leaf.value == unsafe_value
		verbose && @info "Skipping leaf since it has no safe actions."
        return false
    end

    if !bounded(bounds)
		verbose && @info "Skipping leaf since one of its bounds are infinite."
        return false
    end

	axis, threshold = get_threshold(root, bounds, m; verbose)

        
	if threshold === nothing 
		verbose && @info "Leaf cannot be split further."
		return false
	end

	verbose && @info "Split axis $axis at $threshold"
	
	split!(leaf, axis, threshold)
	return true
end


"""
    grow!(tree::Tree, m::ShieldingModel)

Grow the entire tree by calling `split_all!` on all leaves, until no more changes can be made, or `max_iterations` is exceeded.

Note that the number of resulting leaves is potentially exponential in the number of iterations. Therefore, setting a suitably high `min_granularity` and a suitably low `max_iterations` is adviced.

**Returns:** The number of leaves in the resulting tree.

**Args:**
 - `tree` Tree to modify.
 - `dimensionality` Number of axes. 
 - `simulation_function` A function `f(state, action)` which returns the resulting state.
 - `action_space` The possible actions to provide `simulation_function`. 
 - `samples_per_axis` See `SupportingPoints`.
 - `min_granularity` Splits are not made if the resulting size of the partition would be less than `min_granularity` on the given axis
 - `max_recursion_depth` Amount of times to repeat the computation, refining the bound.
 - `margin` This value will be added to the threshold after it is computed, as an extra margin of error.
 - `max_iterations` Function automatically terminates after this number of iterations.
"""
function grow!(tree::Tree, m::ShieldingModel)

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

			split_successful = try_splitting!(leaf, m)

			if split_successful
                changes_made += 1
                leaf_count += 1 # One leaf was removed, two leaves were added.
            end
		end
	end
	leaf_count
end