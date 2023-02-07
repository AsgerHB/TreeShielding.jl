"""
    synthesize!(tree::Tree, 
                    dimensionality, 
                    simulation_function,
                    action_space,
                    samples_per_axis,
                    min_granularity;
                    max_grow_iterations=100,
                    verbose=false)

Turn a tree -- which defines safe and unsafe areas -- into a nondeterministic strategy for avoiding these unsafe areas.

Unsafe partitions are the ones with no actions allowed. All other partitions are treated as safe.

The state space must be properly bounded (see function `bounded`) since partitions which are not properly bounded will not be modified. This can be achieved by calling `tree_from_bounds`.

**Args:**
- `tree` A properly initialized tree. See description.
- `dimensionality` Number of axes must be stated explicitly.
- `simulation_function` A function `f(state, action)` which returns the resulting state.
- `action_space` The possible actions to provide `simulation_function`. Should be an `Enum` or at least work with functions `actions_to_int` and `instances`.
- `samples_per_axis` See `SupportingPoints`.
- `min_granularity` Splits are not made if the resulting size of the partition would be less than `min_granularity` on the given axis. See `grow!`.
- `max_grow_iterations` Growth function automatically terminates after this amount of iterations. See `grow!`.
- `verbose` If true, will print progress updates using the `@info` macro.
"""
function synthesize!(tree::Tree, 
                    dimensionality, 
                    simulation_function,
                    action_space,
                    samples_per_axis,
                    min_granularity;
                    max_grow_iterations=10,
                    max_grow_recursion_depth=5,
                    verbose=false)

    previous_leaf_count = 0 # value not required when loop is entered.
    updates_made = 0
    change_occured = true
    while change_occured
        grown_to = grow!(
            tree, 
            dimensionality, 
            simulation_function, 
            action_space, 
            samples_per_axis, 
            min_granularity, 
            max_iterations=max_grow_iterations,
            max_recursion_depth=max_grow_recursion_depth)

        verbose && @info "Grown to $grown_to leaves"
        
        updates = update!(
            tree, 
            dimensionality, 
            simulation_function, 
            action_space, 
            samples_per_axis)

        verbose && @info "Updated $updates leaves"
        
        pruned_to = prune!(tree)

        verbose && @info "Pruned to $pruned_to leaves"
        
        change_occured = grown_to != previous_leaf_count || updates > 0
        previous_leaf_count = pruned_to
    end

    verbose && @info "Safe strategy synthesised. Making more permissive."

    make_permissive!(tree, 
        dimensionality, 
        simulation_function,
        action_space,
        samples_per_axis,
        min_granularity;
        max_grow_iterations,
        verbose)
end

function make_permissive!(tree::Tree, 
    dimensionality, 
    simulation_function,
    action_space,
    samples_per_axis,
    min_granularity;
    max_grow_iterations=100,
    verbose=false)

    # For every action in turn, grow the tree assuming it is not available.
    # This seperates the safe partitions into the ones where this action is required,
    # and where more actions are allowed.
    for action in instances(action_space)
        action_space′ = filter(a -> a != action, instances(action_space))

        grown_to = grow!(
            tree,
            dimensionality,
            simulation_function,
            action_space′,
            samples_per_axis,
            min_granularity,
            max_iterations=max_grow_iterations)

            verbose && @info "Grown to $grown_to leaves"
    end
        
    # One last update
    updates = update!(
        tree, 
        dimensionality, 
        simulation_function, 
        action_space, 
        samples_per_axis)

    verbose && @info "Updated $updates leaves"
        
    pruned_to = prune!(tree)

    verbose && @info "Pruned to $pruned_to leaves"
end