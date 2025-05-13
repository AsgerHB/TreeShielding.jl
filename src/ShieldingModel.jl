@enum ReachabilityCaching::Int no_caching one_way dependency_graph
@enum ReduceMethod::Int no_reduction naïve caap_reduction
@enum GrowMethod::Int caap_split plus minus smart_minus binary_search binary_search_minus_fallback

"""
**Fields:**
 - `simulation_function` A function `f(state, random_variables, action)` which returns the resulting state.
 - `action_space` The possible actions to provide `simulation_function`. 
 - `dimensionality` Number of axes. 
 - `samples_per_axis` Determines how many samples are taken. Grows exponentially. See `SupportingPoints`.
 - `granularity` Splits are not made if the resulting size of the partition would be less than `granularity` on the given axis
 - `max_iterations` Max iterations when growing the tree. Mostly there as an emergency stop, and ideally should never be hit.
 - `splitting_tolerance` Desired precision while splitting. Specific to the `binary_search` splitting method.
 - `verbose` Print detailed runtime information using the @Info macro. Not recommended for calls to synthesize! or grow!.
 - `reachability_caching` Method for chaching and recomputing reachability.
 - `reduce_method` Method for reducing tree after update.
 - `grow_method` Method for splitting partitions when growing.
"""
struct ShieldingModel
    simulation_function::Function
    action_space::Vector
    dimensionality::Int64
    samples_per_axis::Int64
    random_variable_bounds::Bounds
    granularity::Float64
    max_iterations::Int64
    splitting_tolerance::Float64
    verbose::Bool
    reachability_caching::ReachabilityCaching
    reduce_method::ReduceMethod
    grow_method::GrowMethod

    function ShieldingModel(;simulation_function::Function,
                action_space::Union{Vector,Type},
                dimensionality,
                samples_per_axis,
                random_variable_bounds::Bounds=Bounds([], []),
                granularity=1,
                max_iterations=20,
                splitting_tolerance=0.01,
                verbose=false,
                reachability_caching::ReachabilityCaching=no_caching,
                reduce_method::ReduceMethod=no_reduction,
                grow_method::GrowMethod=binary_search
                )


        if action_space isa Type
            action_space = [a for a in instances(action_space)]
        else
            action_space = action_space
        end

        if splitting_tolerance > granularity && granularity != 0
            @warn "Splitting Tolerance should not be greater than minimum granularity.\nThis can cause necessary splits to be skipped." splitting_tolerance granularity
        end

        new(simulation_function,
            action_space,
            dimensionality,
            samples_per_axis,
            random_variable_bounds,
            granularity,
            max_iterations,
            splitting_tolerance,
            verbose,
            reachability_caching,
            reduce_method,
            grow_method)
    end
end