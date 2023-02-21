"""
    synthesize!(tree::Tree, m::ShieldingModel)

Turn a tree -- which defines safe and unsafe areas -- into a nondeterministic strategy for avoiding these unsafe areas.

Unsafe partitions are the ones with no actions allowed. All other partitions are treated as safe.

The state space must be properly bounded (see function `bounded`) since partitions which are not properly bounded will not be modified. This can be achieved by calling `tree_from_bounds`.

**Args:**
- `tree` A properly initialized tree. See description.
"""
function synthesize!(tree::Tree, m::ShieldingModel)

    previous_leaf_count = 0 # value not required when loop is entered.
    updates_made = 0
    change_occured = true
    while change_occured
        grown_to = grow!(tree, m)

        m.verbose && @info "Grown to $grown_to leaves"
        
        updates = update!(tree, m)

        m.verbose && @info "Updated $updates leaves"
        
        pruned_to = prune!(tree)

        m.verbose && @info "Pruned to $pruned_to leaves"
        
        change_occured = updates > 0 || previous_leaf_count != pruned_to
        previous_leaf_count = pruned_to
    end

    m.verbose && @info "Safe strategy synthesised. Making more permissive."

    make_permissive!(tree, m)
end

function make_permissive!(tree::Tree, m)

    # For every action in turn, grow the tree assuming it is not available.
    # This seperates the safe partitions into the ones where this action is required,
    # and where more actions are allowed.
    for action in m.action_space
        action_space′ = filter(a -> a != action, m.action_space)

        m′ = ShieldingModel(m.simulation_function,
            action_space′,
            m.dimensionality,
            m.samples_per_axis,
            min_granularity=m.min_granularity,
            max_iterations=m.max_iterations,
            margin=m.margin)

        grown_to = grow!(tree, m′)

            m.verbose && @info "Grown to $grown_to leaves"
    end
        
    # One last update
    updates = update!(tree, m)

    m.verbose && @info "Updated $updates leaves"
        
    pruned_to = prune!(tree)

    m.verbose && @info "Pruned to $pruned_to leaves"
end