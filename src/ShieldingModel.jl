struct ShieldingModel
    simulation_function::Function
    action_space
    dimensionality
    samples_per_axis
    min_granularity
    max_recursion_depth
    max_iterations
    margin 
    splitting_tolerance 
    verbose::Bool

    function ShieldingModel(simulation_function::Function,
            action_space,
            dimensionality,
            samples_per_axis; 
            min_granularity=1E-5,
            max_recursion_depth=20,
            max_iterations=20,
            margin=0,
            splitting_tolerance=0.01,
            verbose=false)

        if action_space isa Type
            action_space = instances(action_space)
        end
        
        new(simulation_function,
            action_space,
            dimensionality,
            samples_per_axis,
            min_granularity,
            max_recursion_depth,
            max_iterations,
            margin,
            splitting_tolerance,
            verbose)
    end

    function ShieldingModel(simulation_function::Function,
            action_space,
            dimensionality,
            samples_per_axis,
            min_granularity,
            max_recursion_depth,
            max_iterations,
            margin,
            splitting_tolerance,
            verbose)

        if action_space isa Type
            action_space = instances(action_space)
        end
        
        new(simulation_function,
            action_space,
            dimensionality,
            samples_per_axis,
            min_granularity,
            max_recursion_depth,
            max_iterations,
            margin,
            splitting_tolerance,
            verbose)
    end
end