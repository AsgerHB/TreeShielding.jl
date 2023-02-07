
struct Bounds
    lower
    upper

    function Bounds(lower, upper)
        if length(lower) != length(upper)
            error("Inconsistent dimensionality")
        end
        return new(lower, upper)
    end
end

function Bounds(lower::Dict, upper::Dict, dimensionality)
    lower′ = [-Inf for _ in 1:dimensionality]
    upper′ = [ Inf for _ in 1:dimensionality]

    for (k, v) in lower
        lower′[k] = v
    end
    for (k, v) in upper
        upper′[k] = v
    end
    Bounds(lower′, upper′)
end

function get_dim(bounds::Bounds)
    length(bounds.lower)
end


Base.in(a, b::Bounds) = begin
    dimensionality = length(b.lower)
    for i in 1:dimensionality
        if a[i] < b.lower[i] || a[i] >= b.upper[i]
            return false
        end
    end
    return true
end

Base.:(==)(a::Bounds, b::Bounds)  = begin
    for (x, y) in hcat(zip(a.lower, b.lower)..., zip(a.upper, b.upper)...)
        if x != y
            return false
        end
    end
    return true
end

Base.isapprox(a::Bounds, b::Bounds, params...) = begin
    for (x, y) in hcat(zip(a.lower, b.lower)..., zip(a.upper, b.upper)...)
        if !isapprox(x, y, params...)
            return false
        end
    end
    return true
end

Base.intersect(a::Bounds, b::Bounds) = begin
	if get_dim(a) != get_dim(b) 
		error("Inconsistent dimensionality")
	end
	dimensionality = get_dim(a)
	lower, upper = [], []
	for dim in 1:dimensionality
		push!(lower, max(a.lower[dim], b.lower[dim]))
		push!(upper, min(a.upper[dim], b.upper[dim]))
	end
	Bounds(lower, upper)
end

function bounded(bounds::Bounds)
	for b in bounds.lower
		if b == -Inf || b == Inf
			return false
		end
	end
	for b in bounds.upper
		if b == Inf || b == -Inf
			return false
		end
	end
	return true
end

function magnitude(bounds::Bounds)
    bounds.upper .- bounds.lower
end

function magnitude(bounds::Bounds, axis)
    bounds.upper[axis] - bounds.lower[axis]
end