"""
    synthesize!(tree::Tree, m::ShieldingModel)

Turn a tree -- which defines safe and unsafe areas -- into a nondeterministic strategy for avoiding these unsafe areas.

Unsafe partitions are the ones with no actions allowed. All other partitions are treated as safe.

The state space must be properly bounded (see function `bounded`) since partitions which are not properly bounded will not be modified. This can be achieved by calling `tree_from_bounds`.

**Args:**
- `tree` A properly initialized tree. See description.
- `animation_callback`: Function on the form animation_callback(tree::Tree). Use to create a step-by-step animation. Mind that this can be extremely slow.
"""
function synthesize!(tree::Tree, m::ShieldingModel; animation_callback=nothing)

    clear_reachable!(tree, m)
    previous_leaf_count = 0 # value not required when loop is entered.
    change_occured = true
    while change_occured
        grown_to = grow!(tree, m; animation_callback)

        m.verbose && @info "Grown to $grown_to leaves"
        
        updates = update!(tree, m; animation_callback)

        m.verbose && @info "Updated $updates leaves"
        
        pruned_to = prune!(tree, m; animation_callback)

        m.verbose && @info "Pruned to $pruned_to leaves"
        
        change_occured = updates > 0 || previous_leaf_count != pruned_to
        previous_leaf_count = pruned_to
    end
end