struct ValueUpdate
    leaf::Leaf
    new_value
end

function apply_updates!(updates::AbstractVector{ValueUpdate}; animation_callback=nothing)
    for update in updates
        update.leaf.value = update.new_value
        if !isnothing(animation_callback); animation_callback(get_root(update.leaf)) end
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
        for l in get_reachable(tree, leaf, action_index, m)
            if get_value(l) == no_actions
                # m.verbose && @info "$a is unsafe."
                delete!(allowed, a)
            end
        end
        action_index += 1
    end
    return allowed
end

"""OBS: Use action_index, not action."""
function get_reachable(tree::Tree, leaf::Leaf{T}, action_index::Int, m::ShieldingModel) where {T}
    if m.reachability_caching == no_caching
        action = m.action_space[action_index]
        reachable = Leaf{T}[]
        bounds = get_bounds(leaf, m.dimensionality)
        for (p, r) in all_supporting_points(bounds, m)
            p′ = m.simulation_function(p, r, action)
            leaf′ = get_leaf(tree, p′)::Leaf{T}
            push!(reachable, leaf′)
        end
        return reachable
    else
        @assert !isnothing(leaf.reachable)
        return leaf.reachable[action_index]
    end
end

skipped::Int64 = 0
recomputed::Int64 = 0
const unsafe = actions_to_int([]) 


function set_reachable!(tree::Tree{T}, m::ShieldingModel) where {T}
    save_reachable = m.reachability_caching ∈ [one_way, dependency_graph]
    save_incoming = m.reachability_caching == dependency_graph
    @assert save_reachable "This function should be called when m.reachability_caching = $(m.reachability_caching)."

    clear_reachable!(tree, m)
    queue = Tree[tree]
    while !isempty(queue)
        t = pop!(queue)
        if t isa Node
            push!(queue, t.lt)
            push!(queue, t.geq)
        elseif t isa Leaf
            leaf = t
            bounds = get_bounds(leaf, m.dimensionality)
            global skipped, recomputed, unsafe
            if !leaf.dirty || !bounded(bounds) || leaf.value == unsafe
                if !leaf.dirty
                    skipped += 1
                end
                continue
            end
            
            recomputed += 1
            for (p, r) in all_supporting_points(bounds, m)
                action_index = 1
                for a in m.action_space
                    p′ = m.simulation_function(p, r, a)
                    dest = get_leaf(tree, p′)::Leaf{T}
                    push!(leaf.reachable[action_index], dest)
                    if save_incoming; push!(dest.incoming, leaf) end
                    action_index += 1
                end
            end
            leaf.dirty = false
        else
            error("Unkown tree type $t")
        end
    end
end

"""
    clear_reachable!(node::Tree, m::ShieldingModel)

Marks leaf as dirty and initializes `reachable` and `incoming` fields to empty.
"""
function clear_reachable!(node::Node, m::ShieldingModel)
    clear_reachable!(node.lt, m)
    clear_reachable!(node.geq, m)
end

function clear_reachable!(leaf::Leaf{T}, m::ShieldingModel) where {T}
    leaf.dirty = true

    if isnothing(leaf.reachable)
        leaf.reachable = Vector{Set{Leaf{T}}}()
    else
        empty!(leaf.reachable)
    end

    if isnothing(leaf.incoming)
        leaf.incoming = Set{Leaf{T}}()
    else
        empty!(leaf.incoming)
    end

    for a in m.action_space
        push!(leaf.reachable, Set{Leaf{T}}())
    end
end


function get_updates(tree::Tree, m::ShieldingModel)
    updates = ValueUpdate[]
    no_actions = actions_to_int([])
    global skipped = 0
    global recomputed = 0
    if m.reachability_caching ∈ [ one_way, dependency_graph]
        set_reachable!(tree, m) # Update reachability for dirty nodes
    end
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
- `animation_callback`: Function on the form animation_callback(tree::Tree). Use to create a step-by-step animation. Mind that this can be extremely slow.
"""
function update!(tree::Tree, m::ShieldingModel; animation_callback=nothing)
    updates = get_updates(tree, m)

    apply_updates!(updates; animation_callback)

    length(updates)
end