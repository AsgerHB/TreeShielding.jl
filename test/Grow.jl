
"""
    test_get_threshold(;samples_per_axis=9,
    min_granularity=0.00001,
    margin=0.01)

Using the random walk problem, tests that the `get_threshold` function will return a threshold,
such that all supporting points to one side of the threshold are safe. 
"""
function test_get_threshold(;samples_per_axis=9,
    min_granularity=0.00001,
    margin=0.01)

    spa_when_testing = 20 

    ### Setting up the Random walk problem ###
    dimensionality = 2

    simulation_function(point, action) = simulate(
        rwmechanics,
        point[1], 
        point[2], 
        action,
        unlucky=true)

    any_action, no_action = 
	    actions_to_int(instances(Pace)), actions_to_int([])

    tree = tree_from_bounds(Bounds(
        (rwmechanics.x_min, rwmechanics.t_min), 
        (rwmechanics.x_max, rwmechanics.t_max)), 
        any_action, 
        any_action)
	
	x_min, y_min = rwmechanics.x_min, rwmechanics.t_min
	x_max, y_max = rwmechanics.x_max, rwmechanics.t_max
	split!(get_leaf(tree, x_min - 1, y_max), 2, y_max)
	split!(get_leaf(tree, x_max + 1, y_max), 2, y_max)

	is_safe(point) = point[2] <= rwmechanics.t_max
	is_safe(bounds::Bounds) = is_safe((bounds.lower[1], bounds.upper[2]))

	set_safety!(tree, 
		dimensionality, 
		is_safe, 
		any_action, 
		no_action)

    action_space = instances(Pace)

    point = (0.5, 0.5) # The middle of the playfield.

    m = ShieldingModel(simulation_function, 
        action_space, 
        dimensionality,
        samples_per_axis;
        min_granularity,
        margin)

        
        
    ### Act ##
    bounds = get_bounds(get_leaf(tree, point), dimensionality)
    axis = 2
    direction = safe_below_threshold
    threshold = get_threshold(tree, bounds, axis, RW.fast, direction, m)

    ### Assert ##

    bounds_above, bounds_below = deepcopy(bounds), deepcopy(bounds)
    
    bounds_above.lower[axis] = threshold
    bounds_below.upper[axis] = threshold
    
    supporting_points = SupportingPoints(spa_when_testing, bounds_below)
    safety_below = compute_safety(tree, supporting_points, m)

    @test all([safe for (_, safe) in safety_below])
end


@testset "Grow.jl" begin
    @testset "RW get_threshold" begin
        test_get_threshold(
            samples_per_axis=9,
            min_granularity=0.0000,
            margin=0.01)
        
        test_get_threshold(
            samples_per_axis = 9,
            min_granularity = 0.0000,
            margin = 0.00001)#
        
        test_get_threshold(
            samples_per_axis = 3,#
            min_granularity = 0.0000,
            margin = 0.01)
        
        test_get_threshold(
            samples_per_axis = 9,
            min_granularity = 0.01,#
            margin = 0.01)
        
        test_get_threshold(
            samples_per_axis = 9,
            min_granularity = 0.00001,
            margin = 0.01)
    end

    @enum Actions greeble grooble # This is not just me being silly :3 Julia doesn't like having two enums with the same names.

    @testset "get_split, axis-aligned linear" begin
        safe, unsafe = 1, -1
        
        is_safe(p) = p != unsafe
        
        dimensionality = 1
        
        no_action, any_action = actions_to_int([]), actions_to_int([greeble grooble])

        # Function to make simulation_functions
        # greeble is unsafe if p[1] is below the threshold. grooble will always be less safe than greeble.
        unsafe_at_threshold(t) = (p, a) -> a == greeble ? (p[1] < t ? unsafe : safe) : (p[1] < t*2 ? unsafe : safe)

        tree = Node(1, -0.99,
            Leaf(no_action),
            Node(1, 100,
                Leaf(any_action),
                Leaf(any_action))
            )

        leaf = get_leaf(tree, 0.5) # Safe leaf with bounds [-0.99, 100[
        
        
        samples_per_axis = 8
        splitting_tolerance = 1E-5
        model(expected) = ShieldingModel(unsafe_at_threshold(expected), 
            Actions, 
            dimensionality,
            samples_per_axis;
            min_granularity = 1E-10,
            splitting_tolerance,
            margin = 0
        )

        try_getting_split(expected) =  get_split(tree, leaf, model(expected))

        expected = 0.10

        axis, result = try_getting_split(expected)

        @test result ≈ expected     atol=splitting_tolerance
        @test axis == 1
        

        expected = 0.3

        axis, result = try_getting_split(expected)

        @test result ≈ expected     atol=splitting_tolerance
        @test axis == 1
        

        expected = 0.9

        axis, result = try_getting_split(expected)

        @test result ≈ expected     atol=splitting_tolerance
        @test axis == 1
        

        expected = 50.

        axis, result = try_getting_split(expected)

        @test result ≈ expected     atol=splitting_tolerance
        @test axis == 1
        

        expected = 99.

        axis, result = try_getting_split(expected)

        @test result ≈ expected     atol=splitting_tolerance
        @test axis == 1
            
    end

    @testset "get_split, linear" begin
        safe, unsafe = (1, 1), (-1, -1)
        
        is_safe(p) = p != unsafe
        
        dimensionality = 2
        
        no_action, any_action = actions_to_int([]), actions_to_int([greeble grooble])

        # Function to make simulation_functions
        # greeble is always unsafe if p[1] is below the threshold.  Otherwise it is safe depending on the values of p[2]
        # grooble will always be less safe than greeble.
        function unsafe_at_threshold(t) 
            (p, a) -> if a == greeble 
                (p[1] < (t - p[2]) ? unsafe : safe)
            elseif a == grooble
                (p[1] < (t - 2*p[2]) ? unsafe : safe)
            else 
                error("Not a valid action: $a")
            end
        end

        tree = tree_from_bounds(Bounds((-0.99, 0), (100, 100)))

        unsafe_leaf = get_leaf(tree, unsafe)
        unsafe_leaf.value = no_action # Unsafe leaf is unsafe.

        leaf = get_leaf(tree, safe) # Safe leaf with bounds ( [-0.99, 100[,  [0, 100[ )

        samples_per_axis = 8
        splitting_tolerance = 1E-5
        model(expected) = ShieldingModel(unsafe_at_threshold(expected), 
            Actions, 
            dimensionality,
            samples_per_axis;
            min_granularity = 1E-10,
            splitting_tolerance,
            margin = 0
        )

        try_getting_split(expected) =  get_split(tree, leaf, model(expected))

        expected = 0.10

        axis, result = try_getting_split(expected)

        @test result ≈ expected     atol=splitting_tolerance
        @test axis == 1
        

        expected = 0.3

        axis, result = try_getting_split(expected)

        @test result ≈ expected     atol=splitting_tolerance
        @test axis == 1
        

        expected = 0.9

        axis, result = try_getting_split(expected)

        @test result ≈ expected     atol=splitting_tolerance
        @test axis == 1
        

        expected = 50.

        axis, result = try_getting_split(expected)

        @test result ≈ expected     atol=splitting_tolerance
        @test axis == 1
        

        expected = 99.

        axis, result = try_getting_split(expected)

        @test result ≈ expected     atol=splitting_tolerance
        @test axis == 1
            
    end
end