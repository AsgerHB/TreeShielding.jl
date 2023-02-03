"""
    update!(tree::Tree, 
    dimensionality,
    simulation_function, 
    action_space, 
    samples_per_axis)

Updates every properly bounded partition with a new set of safe actions. An action is considered safe for a partition, if none of its supporting points can end up in an unsafe state by following that action.

**Returns:** The number of partitons who had their set of actions changed.

**Args:**
- `Tree` The tree to update.
- `dimensionality` Number of axes. 
- `simulation_function` A function `f(state, action)` which returns the resulting state.
- `action_space` The possible actions to provide `simulation_function`. Should be an `Enum` or at least work with functions `actions_to_int` and `instances`.
- `samples_per_axis` See `SupportingPoints`.
"""
function update!(tree::Tree, 
    dimensionality,
    simulation_function, 
    action_space, 
    samples_per_axis)

    updates = []
    no_actions = actions_to_int([])
    for leaf in Leaves(tree)
        if leaf.value == no_actions
            continue # bad leaves stay bad
        end

        if !bounded(get_bounds(leaf, dimensionality))
            continue # I don't actually know what to do here.
        end

        allowed = Set(instances(action_space))
        for p in SupportingPoints(samples_per_axis, get_bounds(leaf, dimensionality))
            for a in instances(action_space)
                p′ = simulation_function(p, a)
                if get_value(tree, p′) == no_actions
                    delete!(allowed, a)
                end
            end
        end
        new_value = actions_to_int(allowed)
        if leaf.value != new_value
            push!(updates, (leaf, new_value))
        end
    end

    for (leaf, new_value) in updates
        leaf.value = new_value
    end
    length(updates)
end