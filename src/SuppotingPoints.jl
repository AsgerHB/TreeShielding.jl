struct SupportingPoints
    per_axis::Number
    bounds::Bounds
end

Base.length(s::SupportingPoints) = begin
    if s.bounds.upper == s.bounds.lower
        return 1
    end
    return s.per_axis^get_dim(s.bounds)
end

Base.iterate(s::SupportingPoints) = begin
    if s.per_axis - 1 < 0
        throw(ArgumentError("Samples per axis must be at least 1."))
    end
    dimensionality = get_dim(s.bounds)

    lower, upper = s.bounds.lower, s.bounds.upper

    if upper == lower
        return lower, :terminate
    end
    
    spacings = [upper[i] - lower[i] for i in 1:dimensionality]
    spacings = [spacing/(s.per_axis - 1) for spacing in spacings]
    
    # The iterator state  is (spacings, indices).
    # First sample always in the lower-left corner. 
    return lower, (spacings, zeros(Int, dimensionality))
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