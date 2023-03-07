abstract type Tree
end

mutable struct Node <: Tree 
    axis
    threshold
    lt::Tree
    geq::Tree
    parent::Union{Nothing,Tree}
end

function Node(axis, threshold, lt, geq)
    this = Node(axis, threshold, lt, geq, nothing)
    if lt !== nothing
        lt.parent = this
    end 
    if geq !== nothing
        geq.parent = this
    end
    return this
end

mutable struct Leaf <: Tree
    value
    parent::Union{Nothing,Tree}
end

function Leaf(value)
    Leaf(value, nothing)
end

AbstractTrees.children(node::Node) = [node.lt, node.geq]
AbstractTrees.children(_::Leaf) = []
AbstractTrees.nodevalue(node::Node) = (node.axis, node.threshold)
AbstractTrees.nodevalue(leaf::Leaf) = leaf.value
AbstractTrees.parent(tree::Tree) = tree.parent
AbstractTrees.ParentLinks(::Type{<:Tree}) = AbstractTrees.StoredParents()

Base.:(==)(a::Node, b::Node) = begin
    a.axis == b.axis &&
    a.threshold == b.threshold &&
    a.lt == b.lt && 
    a.geq == b.geq
end

Base.:(==)(a::Leaf, b::Leaf) = begin
    a.value == b.value
end

function get_leaf(leaf::Leaf, _)
    leaf
end

function get_leaf(node::Node, state)
    if state[node.axis] < node.threshold
        return get_leaf(node.lt, state)
    else
        return get_leaf(node.geq, state)
    end
end

function get_leaf(node::Tree, state...)
    get_leaf(node, (state))
end

function get_value(tree::Tree, state)
    get_leaf(tree, state).value
end

function get_value(tree::Tree, state...)
    get_value(tree, (state))
end


function replace_subtree!(tree::Tree, new_tree::Tree)
	if tree.parent === nothing
		error("Cannot replace a root node")
	elseif tree.parent isa Leaf
		error("Badly formed tree. Parent is a leaf, which shouldn't happen.")
	end

	if tree.parent isa Node
		if tree.parent.lt === tree
			new_tree.parent = tree.parent
			return tree.parent.lt = new_tree
		elseif tree.parent.geq === tree
			new_tree.parent = tree.parent
			return tree.parent.geq = new_tree
		else
			error("Badly formed tree. Child not found in parent.")
		end
	end

	error("Not implemented: Parent of type $(typeof(tree.parent))")
end

function split!(leaf::Leaf, axis, threshold, lower=nothing, upper=nothing)
    # TODO: Check if threshold is valid
    lower = something(lower, leaf.value)
    upper = something(upper, leaf.value)

    new_tree = Node(axis, threshold, 
        Leaf(lower),
        Leaf(upper))

    return replace_subtree!(leaf, new_tree)
end

function get_bounds(tree::Tree, dimensionality; _lower=nothing, _upper=nothing)
    parent = tree.parent
    if _lower === nothing && _upper === nothing
        _lower = [-Inf for _ in 1:dimensionality]
        _upper = [Inf for _ in 1:dimensionality]
    end

    # Base case
    if parent === nothing 
        return Bounds(_lower, _upper)
    end
    
    if parent isa Leaf
        error("Badly formed tree. Parent is a leaf, which shouldn't happen.")
    end
    if !(parent isa Node)
        error("Not implemented: Parent of type $(typeof(tree.parent))")
    end
    
    # Recursion
    if parent.lt === tree
        previous_bound = _upper[parent.axis]
        new_bound = parent.threshold
        _upper[parent.axis] = min(previous_bound, new_bound)
        return get_bounds(parent, dimensionality; _lower, _upper)
    elseif parent.geq === tree
        previous_bound = _lower[parent.axis]
        new_bound = parent.threshold
        _lower[parent.axis] = max(previous_bound, new_bound)
        return get_bounds(parent, dimensionality; _lower, _upper)
    else
        error("Badly formed tree. Child not found in parent.")
    end
end