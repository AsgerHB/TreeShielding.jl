struct Bounds{N, T}
    lower::MVector{N, T}
    upper::MVector{N, T}

    function Bounds(lower::Vector{T}, upper::Vector{T}) where T
        l = length(lower)
        if l != length(upper)
            error("Inconsistent dimensionality")
        end
        return new{l, T}(MVector{l}(lower), MVector{l}(upper))
    end

    function Bounds(lower::NTuple{N, T}, upper::NTuple{N, T}) where {N, T}
        if length(lower) != length(upper)
            error("Inconsistent dimensionality")
        end
        return new{N, T}(MVector{N}(lower), MVector{N}(upper))
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

Base.show(io::IO, bounds::Bounds) = begin
	dimensionality = get_dim(bounds)
	intervals = [(bounds.lower[axis], bounds.upper[axis]) for axis in 1:dimensionality]

	intervals = [(@sprintf "]%-+0.05f; %-+0.05f]" a b) for (a, b) in intervals]
	result = join(intervals, " × ")
    println(io, result)
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

Base.hash(a::Bounds) = hash(a.lower) + hash(a.upper)

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

Base.copy(bounds::Bounds) = begin
    Bounds(copy(bounds.lower), copy(bounds.upper))
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