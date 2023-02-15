function get_allowed_actions(tree::Tree,
        bounds::Bounds,
        simulation_function,
        action_space,
        samples_per_axis)

    no_actions = actions_to_int([])

    allowed = Set(instances(action_space))
    for p in SupportingPoints(samples_per_axis, bounds)
        for a in instances(action_space)
            p′ = simulation_function(p, a)
            if get_value(tree, p′) == no_actions
                delete!(allowed, a)
            end
        end
    end
    return allowed
end

function get_allowed_actions(leaf::Tree,
        dimensionality,
        simulation_function,
        action_space,
        samples_per_axis)

    tree = getroot(leaf)
    bounds = get_bounds(leaf, dimensionality)

    get_allowed_actions(tree, bounds, simulation_function, action_space, samples_per_axis)
end

abstract type Update
end

struct ValueUpdate <: Update
    leaf::Leaf
    new_value
end

struct SplitUpdate <: Update
    leaf::Leaf
    axis
    threshold
    lt_value
    geq_value
end


function apply_updates!(updates)
    for update in updates
        if update isa ValueUpdate
            update.leaf.value = update.new_value
        elseif update isa SplitUpdate
            split!(update...)
        else
            error("Unsupported update type")
        end
    end
end

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

        allowed = get_allowed_actions(leaf, 
            dimensionality,
            simulation_function, 
            action_space, 
            samples_per_axis)

        new_value = actions_to_int(allowed)

        if new_value == no_actions
            #todo: split instead
            push!(updates, ValueUpdate(leaf, new_value))
        elseif leaf.value != new_value
            push!(updates, ValueUpdate(leaf, new_value))
        end
    end

    apply_updates!(updates)

    length(updates)
end