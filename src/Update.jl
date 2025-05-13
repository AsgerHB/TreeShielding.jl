struct ValueUpdate
    leaf::Leaf
    new_value
end

function apply_updates!(updates::AbstractVector{ValueUpdate})
    for update in updates
        update.leaf.value = update.new_value
    end
end


"""
    get_allowed_actions(tree::Tree,
        bounds::Bounds,
        m::ShieldingModel)

Returns a `set` of actions that are safe within `bounds`.

 - `tree` The (root) of the tree defining actions for regions.
 - `bounds` Bounds specifying initial location.
 - `m` A [ShieldingModel].
"""
function get_allowed_actions(tree::Tree, leaf::Leaf, m::ShieldingModel)

    no_actions = actions_to_int([])

    allowed = Set(m.action_space)
    action_index = 1
    for a in m.action_space
        for l in leaf.reachable[action_index]
            if get_value(l) == no_actions
                # m.verbose && @info "$a is unsafe."
                delete!(allowed, a)
            end
        end
        action_index += 1
    end
    return allowed
end

skipped::Int64 = 0
recomputed::Int64 = 0
const unsafe = actions_to_int([]) 

function set_reachable!(tree::Tree, leaf::Leaf{T}, m::ShieldingModel) where {T}
    bounds = get_bounds(leaf, m.dimensionality)
    global skipped, recomputed, unsafe
    if !leaf.dirty || !bounded(bounds) || leaf.value == unsafe
        if !leaf.dirty
            skipped += 1
        end
        return 
    end
    
    recomputed += 1
    clear_reachable!(leaf, m)
    for (p, r) in all_supporting_points(bounds, m)
        action_index = 1
        for a in m.action_space
            p′ = m.simulation_function(p, r, a)
            dest = get_leaf(tree, p′)::Leaf{T}
            push!(leaf.reachable[action_index], dest)
            push!(dest.incoming[action_index], leaf)
            action_index += 1
        end
    end
    leaf.dirty = false
end


function set_reachable!(tree::Tree, node::Node{T}, m::ShieldingModel) where {T}
    set_reachable!(tree, node.lt, m)
    set_reachable!(tree, node.geq, m)
end

function set_reachable!(tree::Tree{T}, m::ShieldingModel) where {T} 
    set_reachable!(tree, tree, m)
end

function clear_reachable!(node::Node, m::ShieldingModel)
    clear_reachable!(node.lt, m)
    clear_reachable!(node.geq, m)
end

function clear_reachable!(leaf::Leaf{T}, m::ShieldingModel) where {T}
    leaf.dirty = true # This is redundant as the function is currently used. But things mean things, damnit!
    empty!(leaf.reachable)
    empty!(leaf.incoming)

    for a in m.action_space
        push!(leaf.reachable, Set{Leaf{T}}())
        push!(leaf.incoming, Set{Leaf{T}}())
    end
end


function get_updates(tree::Tree, m::ShieldingModel)
    updates = ValueUpdate[]
    no_actions = actions_to_int([])
    global skipped = 0
    global recomputed = 0
    set_reachable!(tree, tree, m) # Update reachability for dirty nodes
    for leaf in Leaves(tree)
        if leaf.value == no_actions
            continue # bad leaves stay bad
        end

        if !bounded(get_bounds(leaf, m.dimensionality))
            continue # I don't actually know what to do here.
        end
        allowed = get_allowed_actions(tree, leaf, m)

        new_value = actions_to_int(allowed)
        
        if leaf.value != new_value
            push!(updates, ValueUpdate(leaf, new_value))
        end
    end
    if m.verbose
        @info "Skipped $skipped out of $(skipped + recomputed) nodes when updating reachability."
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