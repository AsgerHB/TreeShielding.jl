"""
**Fields:**
 - `dimensionality` Number of axes. 
 - `simulation_function` A function `f(state, action)` which returns the resulting state.
 - `action_space` The possible actions to provide `simulation_function`. 
 - `samples_per_axis` See `SupportingPoints`.
 - `min_granularity` Splits are not made if the resulting size of the partition would be less than `min_granularity` on the given axis
 - `max_recursion_depth` Amount of times to repeat the computation, refining the bound.
 - `margin` This value will be added to the threshold after it is computed, as an extra margin of error.
 - `max_iterations` Function automatically terminates after this number of iterations.
"""
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