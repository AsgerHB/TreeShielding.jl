
"""
    test_get_threshold(;samples_per_axis=9,
    granularity=0,
    splitting_tolerance=0.01)

Using the random walk problem, tests that the `get_threshold` function will return a threshold,
such that all supporting points to one side of the threshold are safe. 
"""
function test_get_threshold(;samples_per_axis=9,
    granularity=0,
    splitting_tolerance=0.01)

    spa_when_testing = 20 

    ### Setting up the Random walk problem ###
    dimensionality = 2

    simulation_function(point, random_outcomes, action) = simulate(
        rwmechanics,
        point[1], 
        point[2], 
        action,
        random_outcomes)

    ϵ = rwmechanics.ϵ
    random_variable_bounds = Bounds((-ϵ, -ϵ), (ϵ, ϵ))

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

    
    m = ShieldingModel(;simulation_function, 
        action_space=Pace, 
        dimensionality,
        samples_per_axis,
        random_variable_bounds,
        splitting_tolerance,
        granularity)

        
        
    ### Act ##
    point = (0.5, 0.5) # The middle of the playfield.
    bounds = get_bounds(get_leaf(tree, point), dimensionality)
    axis = 2
    direction = TreeShielding.safe_below_threshold
    threshold = TreeShielding.get_threshold(tree, bounds, axis, RW.fast, direction, m)

    ### Assert ##

    bounds_above, bounds_below = deepcopy(bounds), deepcopy(bounds)
    
    bounds_above.lower[axis] = threshold
    bounds_below.upper[axis] = threshold
    
    safety_below = compute_safety(tree, bounds_below, m)

    @test all([safe for (_, safe) in safety_below])
end


@testset "Grow.jl" begin
    @testset "RW get_threshold" begin
        test_get_threshold(
            samples_per_axis=9,
            granularity=0,
            splitting_tolerance=0.01)
        
        test_get_threshold(
            samples_per_axis = 9,
            granularity = 0.001,
            splitting_tolerance=0.0005)#
        
        test_get_threshold(
            samples_per_axis = 3,#
            granularity = 0.00001,
            splitting_tolerance=0.000005)
        
        test_get_threshold(
            samples_per_axis = 9,
            granularity = 0.01,#
            splitting_tolerance=0.005)
        
    end

    @enum Actions::Int greeble grooble # This is not just me being silly :3 Julia doesn't like having two enums with the same names.

    @testset "get_split_by_binary_search, axis-aligned linear" begin
        safe, unsafe = 1, -1
        
        is_safe(p) = p != unsafe
        
        dimensionality = 1
        
        no_action, any_action = actions_to_int([]), actions_to_int([greeble grooble])

        # Function to make simulation_functions
        # greeble is unsafe if p[1] is below the threshold. grooble will always be less safe than greeble.
        unsafe_at_threshold(t) = (p, _, a) -> a == greeble ? (p[1] < t ? unsafe : safe) : (p[1] < t*2 ? unsafe : safe)


        # 1D state-space. Anything below -0.99 is unsafe.
        #     unsafe    -0.99    safe       
        #  ---------------|------------------>
        tree = Node(1, -0.99,
            Leaf(no_action),
            Node(1, 100,
                Leaf(any_action),
                Leaf(any_action))
            )

        leaf = get_leaf(tree, 0.5) # Safe leaf with bounds [-0.99, 100[
        
        
        samples_per_axis = 8
        random_variable_bounds = Bounds([], [])
        splitting_tolerance = 1E-5

        
        model(expected) = ShieldingModel(;simulation_function=unsafe_at_threshold(expected), 
            action_space=Actions,
            dimensionality,
            samples_per_axis,
            random_variable_bounds,
            granularity = 0,
            splitting_tolerance)

        try_getting_split(expected) =  TreeShielding.get_split_by_binary_search(tree, leaf, model(expected))

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

    @testset "get_split_by_binary_search, linear" begin
        safe, unsafe = (1, 1), (-1, -1)
        
        is_safe(p) = p != unsafe
        
        dimensionality = 2
        
        no_action, any_action = actions_to_int([]), actions_to_int([greeble grooble])

        # Function to make simulation_functions
        # greeble is always unsafe if p[1] is below the threshold.  Otherwise it is safe depending on the values of p[2]
        # grooble will always be less safe than greeble.
        function unsafe_at_threshold(t) 
            (p, _, a) -> if a == greeble 
                (p[1] < (t - p[2]) ? unsafe : safe)
            elseif a == grooble
                (p[1] < (t - 2*p[2]) ? unsafe : safe)
            else 
                error("Not a valid action: $a")
            end
        end

        tree = tree_from_bounds(Bounds((-0.99, 0.), (100., 100.)))

        unsafe_leaf = get_leaf(tree, unsafe)
        unsafe_leaf.value = no_action # Unsafe leaf is unsafe.

        leaf = get_leaf(tree, safe) # Safe leaf with bounds ( [-0.99, 100[,  [0, 100[ )

        samples_per_axis = 8
        random_variable_bounds = Bounds([], [])
        splitting_tolerance = 1E-5
        model(expected) = ShieldingModel(;simulation_function=unsafe_at_threshold(expected), 
            action_space=Actions, 
            dimensionality,
            samples_per_axis,
            random_variable_bounds,
            granularity = 0,
            splitting_tolerance)

        try_getting_split(expected) =  TreeShielding.get_split_by_binary_search(tree, leaf, model(expected))

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