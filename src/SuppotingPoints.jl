struct SupportingPoints
    per_axis::Number
    bounds::Bounds
end


function get_spacing_sizes(s::SupportingPoints, dimensionality)
    upper, lower = s.bounds.upper, s.bounds.lower
    spacings = [upper[i] - lower[i] for i in 1:dimensionality]
    spacings = [spacing/(s.per_axis - 1) for spacing in spacings]
end

Base.length(s::SupportingPoints) = begin
    if s.bounds.upper == s.bounds.lower
        return 1
    end
    return s.per_axis^get_dim(s.bounds)
end

Base.size(s::SupportingPoints) = begin
    [s.per_axis for _ in 1:get_dim(s.bounds)]
end

Base.iterate(s::SupportingPoints) = begin
    if s.per_axis - 1 < 0
        throw(ArgumentError("Samples per axis must be at least 1."))
    end
    dimensionality = get_dim(s.bounds)

    lower, upper = s.bounds.lower, s.bounds.upper

    if upper == lower
        return Tuple(lower), :terminate
    end
    
    spacings = get_spacing_sizes(s, dimensionality)
    
    # The iterator state  is (spacings, indices).
    # First sample always in the lower-left corner. 
    return Tuple(lower), (spacings, zeros(Int, dimensionality))
end

Base.iterate(s::SupportingPoints, terminate::Symbol) = begin
    if  terminate != :terminate
        error("Call error.")
    end
    return nothing
end

Base.iterate(s::SupportingPoints, state) = begin
    
    dimensionality = get_dim(s.bounds)
    spacings, indices = state
    indices = copy(indices)

    for dim in 1:dimensionality
        indices[dim] += 1
        if indices[dim] <= s.per_axis - 1
            break
        else
            if dim < dimensionality
                indices[dim] = 0
                # Proceed to incrementing next row
            else
                return nothing
            end
        end
    end

    sample = Tuple(i*spacings[dim] + s.bounds.lower[dim] 
                    for (dim, i) in enumerate(indices))
    
    sample, (spacings, indices)
end

function all_supporting_points(bounds::Bounds, m::ShieldingModel)
    return Iterators.product(
        SupportingPoints(m.samples_per_axis, bounds),
        SupportingPoints(m.samples_per_axis, m.random_variable_bounds)
    )
end