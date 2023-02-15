struct ShieldingModel
    simulation_function::Function
    action_space
    dimensionality
    samples_per_axis
    min_granularity
    max_recursion_depth
    max_iterations
    margin

    function ShieldingModel(simulation_function::Function, action_space, dimensionality, samples_per_axis; min_granularity=1E-5, max_recursion_depth=20, max_iterations=20, margin=0)
        new(simulation_function,  action_space,  dimensionality,  samples_per_axis,  min_granularity,  max_recursion_depth,  max_iterations, margin)
    end
end