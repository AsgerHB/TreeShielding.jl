"""
    function tree_from_bounds(bounds::Bounds, [out_of_bounds=-1, inside_bounds=1])

Create a tree consisting of a single bounded partition with value `inside_bounds` and four unbounded partitions with the value `out_of_bounds`. 
"""
function tree_from_bounds(bounds::Bounds, out_of_bounds=-1, inside_bounds=1)
	l, u = bounds.lower, bounds.upper

	tree = Node(1, l[1], 
            Leaf(out_of_bounds),
            Node(2, l[2],
                Leaf(out_of_bounds),
                Node(1, u[1],
                    Node(2, u[2],
                        Leaf(inside_bounds),
                        Leaf(out_of_bounds),
                    ),
                    Leaf(out_of_bounds),
                ),
            ), 
        )
	tree
end

"""
    function even_split!(leaf::Leaf, dimensionality, axis)

Turn a leaf into a node evenly split along the given axis.
"""
function even_split!(leaf::Leaf, dimensionality, axis)
	bounds = get_bounds(leaf, dimensionality)
	middle = (bounds.upper[axis] - bounds.lower[axis])/2 + bounds.lower[axis]
	split!(leaf, axis, middle)
end

"""
    function gridify!(tree::Tree, dimensionality, number_of_splits)

Splits all properly bounded partitions into sub-partitions of equal size along all axes.

This is repeated for `number_of_splits`, with exponential growth in the number of leaves as a result.
"""
function gridify!(tree::Tree, dimensionality, number_of_splits)
    if number_of_splits > 10
        error("Reconsider doing this. You will run out of memory.")
    end

    for _ in 1:number_of_splits
		for axis in 1:dimensionality
			for leaf in Leaves(tree)
				if !bounded(get_bounds(leaf, dimensionality))
					continue
				end
				even_split!(leaf, dimensionality, axis)
			end
		end
	end
	tree
end