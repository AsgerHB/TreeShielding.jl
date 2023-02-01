"""
    get_splitting_point(points_safe, axis, margin)

**Returns:** the threshold for splitting the state space, such that all unsafe supporting points are to one side. 

If such a threshold exists, that is. Otherwise it returns `nothing`.

**Args:**
- `points_safe` (Better name pending.) A list of points that contains (point,bool)-tuples indicating whether each point is safe. See `compute_safety`.
- `axis` Which axis to split on.
- `margin` This value will be added to the returned threshold. Should ideally be half the distance between points.
"""
function get_splitting_point(points_safe, axis, margin)
	if !any([safe for (p, safe) in points_safe]) ||  
			!any([!safe for (p, safe) in points_safe])
		return nothing
	end
	
	# least upper bound
	lub_safe = max([p[axis] for (p, safe) in points_safe if safe]...)
	lub_unsafe = max([p[axis] for (p, safe) in points_safe if !safe]...)

	# greatest lower bound
	glb_safe = min([p[axis] for (p, safe) in points_safe if safe]...)
	glb_unsafe = min([p[axis] for (p, safe) in points_safe if !safe]...)
	
	if glb_unsafe > glb_safe
		return glb_unsafe - margin
	elseif lub_unsafe < lub_safe
		return lub_unsafe + margin
	else
		return nothing
	end
end

"""
    compute_safety(tree::Tree, simulation_function, points [unsafe_value=0])

For each point, use the `simulation_function` to check if it would end up in an unsafe place according to `tree`. 

**Returns:** List of (point, bool)-tuples indicating wheter each point is safe. I.e it ends up in an unsafe place.

**Args:**
 - `tree` Defines the set of safe and unsafe states.
 - `simulation_function` A function `f(state, action)` which returns the resulting state.
 - `action_space` The possible actions to provide `simulation_function`. Should be an `Enum` or at least work with functions `actions_to_int` and `instances`.
 - `points` This is the set of points.
"""
function compute_safety(tree::Tree, simulation_function, action_space, points)
    unsafe_value = actions_to_int(action_space, []) # The value for states where no actions are allowed.
	result = []
	for p in points
        safe = false
        for a in instances(action_space)
            p′ = simulation_function(p, a)
            safe = safe || (get_value(tree, p′) != unsafe_value)
        end
        push!(result, (p, safe))
	end
	result
end

"""
    try_splitting!(leaf::Leaf, dimensionality, simulation_function,  samples_per_axis, min_granularity)

Makes calls to `get_splitting_point` for each axis, and performs the first split which can be made. The split can be made if 

 - The leaf is properly bounded. That is, its bounds are finite on all axes.
 - `get_splitting_point` returns something other than `nothing`, i.e. there exists a thereshold such that all points are safe on one side of it.
 - The threshold would not create a bound whose size is smaller than `min_granularity`.
   
**Returns:** `true` if a split is made, and `false` otherwise.

**Args:**
 - `leaf` This leaf will be split at the first axis where a division can be made between safe and unsafe points.
 - `dimensionality` Number of axes. 
 - `simulation_function` A function `f(state, action)` which returns the resulting state.
 - `action_space` The possible actions to provide `simulation_function`. Should be an `Enum` or at least work with functions `actions_to_int` and `instances`.
 - `samples_per_axis` See `SupportingPoints`.
 - `min_granularity` Splits are not made if the resulting size of the partition would be less than `min_granularity` on the given axis
"""
function try_splitting!(leaf::Leaf, 
    dimensionality, 
    simulation_function, 
    action_space,
    samples_per_axis,
    min_granularity)

    root = getroot(leaf)
    bounds = get_bounds(leaf, dimensionality)

    if !bounded(bounds)
        return false
    end

    supporting_points = SupportingPoints(samples_per_axis, bounds)
    points_safe = compute_safety(root, simulation_function, action_space, supporting_points)
    spacings = get_spacing_sizes(supporting_points, dimensionality)

    for axis in (1:dimensionality)
        margin = spacings[axis]/2
        threshold = get_splitting_point(points_safe, axis, margin)
        
        if threshold === nothing 
            continue
        end

        lower, upper = bounds.lower[axis], bounds.upper[axis]
        if  abs(threshold - lower) < min_granularity ||
            abs(threshold - upper) < min_granularity
            continue
        end
        
        split!(leaf, axis, threshold)
        return true
    end

    return false
end

"""
    grow!(tree::Tree, dimensionality, simulation_function, action_space, samples_per_axis, min_granularity, [max_iterations=10])

Grow the entire tree by calling `split_all!` on all leaves, until no more changes can be made, or `max_iterations` is exceeded.

Note that the number of resulting leaves is potentially exponential in the number of iterations. Therefore, setting a suitably high `min_granularity` and a suitably low `max_iterations` is adviced.

**Returns:** The tree that has just been edited.

**Args:**
 - `tree` Tree to modify.
 - `dimensionality` Number of axes. 
 - `simulation_function` A function `f(state, action)` which returns the resulting state.
 - `action_space` The possible actions to provide `simulation_function`. Should be an `Enum` or at least work with functions `actions_to_int` and `instances`.
 - `samples_per_axis` See `SupportingPoints`.
 - `min_granularity` Splits are not made if the resulting size of the partition would be less than `min_granularity` on the given axis
 - `max_iterations` Function automatically terminates after this number of iterations.
"""
function grow!(tree::Tree, 
                dimensionality,
                simulation_function, 
                action_space,
                samples_per_axis,
                min_granularity;
                max_iterations=10)
	

	changes = [true] # Array to keep up with wether any leaf was split
	while any(changes)
		if (max_iterations -= 1) < 0
			break
		end
		
		changes = [] 
		queue = collect(Leaves(tree))
		for leaf in queue
			changed = try_splitting!(leaf, 
				dimensionality, 
				simulation_function, 
                action_space,
				samples_per_axis,
				min_granularity)
			push!(changes, changed)
		end
	end
	tree
end