"""
**Fields:**
 - `simulation_function` A function `f(state, random_variables, action)` which returns the resulting state.
 - `action_space` The possible actions to provide `simulation_function`. 
 - `dimensionality` Number of axes. 
 - `samples_per_axis` Determines how many samples are taken. Grows exponentially. See `SupportingPoints`.
 - `granularity` Splits are not made if the resulting size of the partition would be less than `granularity` on the given axis
 - `margin` This value will be added to a threshold after it is computed, as an extra margin for error.
 - `max_iterations` Max iterations when growing the tree. Mostly there as an emergency stop, and ideally should never be hit.
 - `splitting_tolerance` Desired precision while splitting. 
 - `verbose` Print detailed runtime information using the `@Info` macro. Not recommended for calls to `synthesize!` or `grow!`.
"""
struct ShieldingModel
    simulation_function::Function
    action_space
    dimensionality
    samples_per_axis
    random_variable_bounds::Bounds
    granularity
    max_iterations
    margin 
    splitting_tolerance 
    verbose::Bool

    function ShieldingModel(simulation_function::Function,
                action_space,
                dimensionality,
                samples_per_axis,
                random_variable_bounds::Bounds; 
                granularity=1E-5,
                max_iterations=20,
                margin=0,
                splitting_tolerance=0.01,
                verbose=false)

        
        ShieldingModel(simulation_function,
            action_space,
            dimensionality,
            samples_per_axis,
            random_variable_bounds::Bounds,
            granularity,
            max_iterations,
            margin,
            splitting_tolerance,
            verbose)
    end

    function ShieldingModel(simulation_function::Function,
            action_space,
            dimensionality,
            samples_per_axis,
            random_variable_bounds::Bounds,
            granularity,
            max_iterations,
            margin,
            splitting_tolerance,
            verbose)

        if action_space isa Type
            action_space = instances(action_space)
        end

        if margin > granularity
            @warn "Margin should not be greater than minimum granularity.\nThis can cause infinite growth." margin granularity
        end

        if splitting_tolerance > granularity
            @warn "Splitting Tolerance should not be greater than minimum granularity.\nThis can cause necessary splits to be skipped." splitting_tolerance granularity
        end
        
        new(simulation_function,
            action_space,
            dimensionality,
            samples_per_axis,
            random_variable_bounds::Bounds,
            granularity,
            max_iterations,
            margin,
            splitting_tolerance,
            verbose)
    end
end