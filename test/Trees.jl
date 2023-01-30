@testset "Trees.jl" begin
    call(f) = f()
    
    bigtree =  
		Node(1, 20, 
			Node(1, 5,
				Node(2, 15,
					Leaf(-3),
					Node(2, 21,
						Leaf(0),
						Leaf(-4))),
				Leaf(-2)),
			
			Node(2, 10,
				Leaf(-5),
				Node(2, 17,
					Leaf(-7),
					Leaf(-6))),)
	

    @test get_value(bigtree, (2, 20)) == 0

    @test get_value(bigtree, (10, 10)) == -2

    call() do
        tree = Node(1, 0.5, 
            Leaf(-1),
            Leaf(-2))
        
        replace_subtree!(tree.geq, Leaf(0))
        @test get_value(tree, [0.99]) == 0
    end

    call() do
        tree = Node(1, 0.5, 
            Leaf(-1),
            Leaf(-2))
        
        split!(tree.geq, 1, 0.75, -3, 0)
        @test get_value(tree, [0.99]) == 0
    end

    call() do
        tree = Node(1, 0,
            Leaf(1),
            Leaf(2))
        l, u = -6, 0
        split!(get_leaf(tree, l + 1, u - 1), 1, u, 3, 4)
        split!(get_leaf(tree, l + 1, u - 1), 2, u, 5, 6)
        split!(get_leaf(tree, l + 1, u - 1), 1, l, 7, 8)
        split!(get_leaf(tree, l + 1, u - 1), 2, l, 9, 10)
        
        #draw(tree, Bounds((-10, -10), (10, 10)))
        #scatter!([l + 1], [u - 1], m=(:+, 5, colors.WET_ASPHALT), msw=3)
        
        @test Bounds([l, l], [u, u]) == get_bounds(get_leaf(tree, -5, -5))
    end
end