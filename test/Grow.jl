
"""
    test_get_threshold(;samples_per_axis=9,
    min_granularity=0.00001,
    max_recursion_depth=2,
    margin=0.01)

Using the random walk problem, tests that the `get_threshold` function will return a threshold,
such that all supporting points to one side of the threshold are safe. 
"""
function test_get_threshold(;samples_per_axis=9,
    min_granularity=0.00001,
    max_recursion_depth=2,
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

    action_space = Pace

    point = (0.5, 0.5) # The middle of the playfield.
    
    ### Act ##
    axis, threshold = get_threshold(tree,
        dimensionality,
        get_bounds(get_leaf(tree, point), dimensionality),
        simulation_function, 
        action_space, 
        samples_per_axis, 
        min_granularity;
        verbose=false,
        max_recursion_depth,
        margin)

    ### Assert ##
    bounds = get_bounds(get_leaf(tree, point), dimensionality)

    bounds_above, bounds_below = deepcopy(bounds), deepcopy(bounds)
    
    bounds_above.lower[axis] = threshold
    bounds_below.upper[axis] = threshold

    supporting_points = SupportingPoints(spa_when_testing, bounds_above)
    safety_above = compute_safety(tree, simulation_function, action_space, supporting_points)
    
    supporting_points = SupportingPoints(spa_when_testing, bounds_below)
    safety_below = compute_safety(tree, simulation_function, action_space, supporting_points)

    @test all([safe for (_, safe) in safety_above]) || all([safe for (_, safe) in safety_below])
end


@testset "Grow.jl" begin
    @testset "get_threshold" begin
        test_get_threshold(
            samples_per_axis=9,
            min_granularity=0.00001,
            max_recursion_depth=5,
            margin=0.01)
        
        test_get_threshold(
            samples_per_axis = 9,
            min_granularity = 0.00001,
            max_recursion_depth = 5,
            margin = 0.00001)#
        
        test_get_threshold(
            samples_per_axis = 3,#
            min_granularity = 0.00001,
            max_recursion_depth = 5,
            margin = 0.01)
        
        test_get_threshold(
            samples_per_axis = 9,
            min_granularity = 0.01,#
            max_recursion_depth = 5,
            margin = 0.01)
        
        test_get_threshold(
            samples_per_axis = 9,
            min_granularity = 0.00001,
            max_recursion_depth = 20, #
            margin = 0.01)
        
    end
end