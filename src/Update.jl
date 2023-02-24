struct ValueUpdate
    leaf::Leaf
    new_value
end

"""
    apply_updates!(updates::AbstractVector{ValueUpdate})

Apply updates, splitting unsafe leaves as much as possible.
"""
function apply_updates!(updates::AbstractVector{ValueUpdate})
    for update in updates
        update.leaf.value = update.new_value
    end
end


function get_allowed_actions(tree::Tree,
        bounds::Bounds,
        m::ShieldingModel)

    no_actions = actions_to_int([])

    allowed = Set(m.action_space)
    for (p, r) in all_supporting_points(bounds, m)
        for a in m.action_space
            p′ = m.simulation_function(p, r, a)
            if get_value(tree, p′) == no_actions
                # m.verbose && @info "$a is unsafe at $p."
                delete!(allowed, a)
            end
        end
    end
    return allowed
end

function get_allowed_actions(leaf::Tree, m::ShieldingModel)

    tree = getroot(leaf)
    bounds = get_bounds(leaf, m.dimensionality)

    get_allowed_actions(tree, bounds, m)
end

function get_updates(tree::Tree, m::ShieldingModel)
    updates = ValueUpdate[]
    no_actions = actions_to_int([])
    for leaf in Leaves(tree)
        if leaf.value == no_actions
            continue # bad leaves stay bad
        end

        if !bounded(get_bounds(leaf, m.dimensionality))
            continue # I don't actually know what to do here.
        end

        allowed = get_allowed_actions(leaf, m)

        new_value = actions_to_int(allowed)
        
        if leaf.value != new_value
            push!(updates, ValueUpdate(leaf, new_value))
        end
    end
    updates
end

"""
    update!(tree::Tree, m::ShieldingModel)

Updates every properly bounded partition with a new set of safe actions. An action is considered safe for a partition, if none of its supporting points can end up in an unsafe state by following that action.

**Returns:** The number of partitons who had their set of actions changed.

**Args:**
- `tree` The tree to update.
"""
function update!(tree::Tree, m::ShieldingModel)
    updates = get_updates(tree, m)

    apply_updates!(updates)

    length(updates)
end