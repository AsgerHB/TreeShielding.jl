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

function draw(policy::Function, bounds; 
    G = 0.1, 
    slice=[:,:], 
    params...)

    if 2 != count((==(Colon())), slice)
        throw(ArgumentError("The slice argument should be an array of indices and exactly two colons. Example: [:, 10, :]"))
    end
    
    x, y = findall((==(Colon())), slice)

    lower = (bounds.lower[x], bounds.lower[y])
    upper = (bounds.upper[x], bounds.upper[y])
    x_min, y_min = lower
    x_max, y_max = upper
    
    size_x, size_y = Int((x_max - x_min)/G), Int((y_max - y_min)/G)
    matrix = Matrix(undef, size_x, size_y)
    for i in 1:size_x
        for j in 1:size_y
            x, y = i*G + x_min, j*G + x_min
            matrix[i, j] = policy((x, y))
        end
    end

    x_tics = x_min:G:x_max
    y_tics = y_min:G:y_max
    
    heatmap(x_tics, y_tics, transpose(matrix),
            levels=10;
            params...)
end

function draw(tree::Tree, bounds;
        G = 0.1, 
        slice=[:,:],
        params...)
    
    get_value′(s) = get_value(tree, s)
    draw(get_value′, bounds; G, slice, params...)
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

function split!(node::Node, _...)
    error("Tried to split non-leaf node. This is not allowed.")
end

function get_bounds(tree::Tree, dimensionality; _lower=Dict(), _upper=Dict())
    parent = tree.parent

    # Base case
    if parent === nothing 
        return Bounds(_lower, _upper, dimensionality)
    end
    
    if parent isa Leaf
        error("Badly formed tree. Parent is a leaf, which shouldn't happen.")
    end
    if !(parent isa Node)
        error("Not implemented: Parent of type $(typeof(tree.parent))")
    end
    
    # Recursion
    if parent.lt === tree
        previous_bound = get(_upper, parent.axis, Inf)
        new_bound = parent.threshold
        _upper[parent.axis] = min(previous_bound, new_bound)
        return get_bounds(parent, dimensionality; _lower, _upper)
    elseif parent.geq === tree
        previous_bound = get(_lower, parent.axis, -Inf)
        new_bound = parent.threshold
        _lower[parent.axis] = max(previous_bound, new_bound)
        return get_bounds(parent, dimensionality; _lower, _upper)
    else
        error("Badly formed tree. Child not found in parent.")
    end
end