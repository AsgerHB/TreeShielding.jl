### A Pluto.jl notebook ###
# v0.19.22

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ 23a8f930-95ae-4820-bac0-82edd0bfbc8a
begin
	using Pkg
	Pkg.activate(".")
	Pkg.develop("TreeShielding")
	
	using Plots
	using PlutoLinks
	using PlutoUI
	using PlutoTest
	using Unzip
	using AbstractTrees
	using Printf
	using Setfield
	TableOfContents()
end

# ╔═╡ edf99af5-443f-4c23-b63d-51d5075b30b5
begin
	@revise using TreeShielding
	using TreeShielding.RW
end

# ╔═╡ 6a50c8f7-6367-4d59-a574-c8a29a785e88
md"""
# Growing the tree V2.0
This notebook attempts to implement some sort of multi-splitting
"""

# ╔═╡ 1550fddd-6b9d-4b16-9265-c12f44b0f1e4
md"""
## Preliminaries
"""

# ╔═╡ 00716b11-f49e-4790-9442-c4e24d05f369
md"""
### Colors
"""

# ╔═╡ c669d727-88fb-4ee8-9f50-7681d1b8df5a
begin
	colors = 
		(TURQUOISE = colorant"#1abc9c", 
		EMERALD = colorant"#2ecc71", 
		PETER_RIVER = colorant"#3498db", 
		AMETHYST = colorant"#9b59b6", 
		WET_ASPHALT = colorant"#34495e",
		
		GREEN_SEA   = colorant"#16a085", 
		NEPHRITIS   = colorant"#27ae60", 
		BELIZE_HOLE  = colorant"#2980b9", 
		WISTERIA     = colorant"#8e44ad", 
		MIDNIGHT_BLUE = colorant"#2c3e50", 
		
		SUNFLOWER = colorant"#f1c40f",
		CARROT   = colorant"#e67e22",
		ALIZARIN = colorant"#e74c3c",
		CLOUDS   = colorant"#ecf0f1",
		CONCRETE = colorant"#95a5a6",
		
		ORANGE = colorant"#f39c12",
		PUMPKIN = colorant"#d35400",
		POMEGRANATE = colorant"#c0392b",
		SILVER = colorant"#bdc3c7",
		ASBESTOS = colorant"#7f8c8d")
	[colors...]
end

# ╔═╡ ae6142f5-ace2-4211-9318-6f8257f2fdfa
call(f) = f()

# ╔═╡ b05c8d41-c62c-4780-90d6-7aa174645770
dimensionality = 2

# ╔═╡ 00d60986-0a1b-4b8e-87e7-dc8597dc35b0
md"""
## Example Function and safety constraint

This notebook uses the Random Walk example, which is included in the RW module.
"""

# ╔═╡ 55931748-f860-4ced-9fc9-3906368042ba
any_action, no_action = 
	actions_to_int(instances(Pace)), actions_to_int([])

# ╔═╡ 193ea2f4-548f-4dcf-b661-4bf1aca16b43
action_color_dict=Dict(
	any_action => colorant"#ffffff", 
	1 => colorant"#a1eaff", 
	no_action => colorant"#ff9178"
)

# ╔═╡ f7da5f6e-7b6f-4a4d-a500-798fb37cd856
evaluate(rwmechanics, (_, _) -> RW.slow)

# ╔═╡ 463ea187-2aba-49af-a089-29eb280939dd
begin
	plot(aspectratio=:equal, size=(300, 300), xlabel="x", ylabel="t")
	xlims!(rwmechanics.x_min, rwmechanics.x_max + 0.1)
	ylims!(rwmechanics.t_min, rwmechanics.t_max + 0.1)
	draw_walk!(take_walk(rwmechanics, (_, _) -> rand([RW.slow, RW.fast]))...)
end

# ╔═╡ 70c269f7-e47c-4405-8012-4f1c68cfb879
md"""
### The Random Factor

The actions are affected by a random factor $\pm \epsilon$ in each dimension. This is captured in the below bounds, which make up part of the model. This will be used as part of the reachability simulation.
"""

# ╔═╡ 0e22d8cc-bd9d-4ff1-a369-c8f1b73f65f1
ϵ = rwmechanics.ϵ

# ╔═╡ d88cd139-6a31-4d9d-b1c5-f6828c16d441
random_variable_bounds = Bounds((-ϵ,  -ϵ), (ϵ, ϵ))

# ╔═╡ 4ba1c107-8db5-4273-95f6-77b66b25b2c3
rwmechanics

# ╔═╡ 9ea39d19-4238-4e6e-abb9-968bdcaa8851
md"""
### The Simulation Function

The function for taking a single step needs to be wrapped up, so that it has the signature `(point::AbstractVector, action, random_variables::AbstractVector) -> updated_point`. 
"""

# ╔═╡ 40068b9c-3faf-4091-9786-fbfab9973485
simulation_function(point, random_variables, action) = RW.simulate(
	rwmechanics, 
	point[1], 
	point[2], 
	action,
	random_variables)

# ╔═╡ d8904f0d-028f-4c65-bacc-c06fb7f80976
md"""
The goal of the game is to reach `x >= x_max` without reaching `t >= t_max`. 

This corresponds to the below safety property. It is defined both for a single `(x, t)` point, as well as for a set of points given by `Bounds`.
"""

# ╔═╡ 1f92d031-9e32-4ad4-a2d2-105de6e99ea7
t_min = 0.3

# ╔═╡ 1c537f46-4f50-4009-87de-ffed4ca586e3
md"""
## Building the Initial Tree

Building a tree with a properly bounded state space, and some divisions that align with the safety constraints.

Note that the set of unsafe states is modified for this notebook, to make the initial split more interesting.
"""

# ╔═╡ c2df2986-7ef0-48fa-b816-7ad4dd317b97
outer_bounds = Bounds(
	[rwmechanics.x_min, rwmechanics.t_min], 
	[rwmechanics.x_max, rwmechanics.t_max])

# ╔═╡ 47ff5769-9f8e-486c-981f-f5bad2a449ce
draw_bounds = Bounds(
	outer_bounds.lower .- [0.5, 0.5],
	outer_bounds.upper .+ [0.5, 0.5]
)

# ╔═╡ fbffa476-2fb1-46b3-b591-ecc7d6cc17d3
begin
	initial_tree = tree_from_bounds(outer_bounds, any_action, any_action)
	
	x_min, y_min = rwmechanics.x_min, rwmechanics.t_min
	x_max, y_max = rwmechanics.x_max, rwmechanics.t_max
	split!(get_leaf(initial_tree, x_min - 1, y_max), 2, y_max)
	split!(get_leaf(initial_tree, x_max + 1, y_max), 2, y_max)
	split!(get_leaf(initial_tree, x_max + 1, y_max - 0.1), 2, t_min)
end

# ╔═╡ 2f48eb7a-f6e2-438b-8048-c3b3089a121e
begin
	is_safe(point) = point[2] <= rwmechanics.t_max && 
								(point[2] >= t_min || point[1] <= x_max)
	
	is_safe(bounds::Bounds) = is_safe((bounds.lower[1], bounds.upper[2])) &&
                              is_safe((bounds.upper[1], bounds.upper[2])) &&
                              is_safe((bounds.upper[1], bounds.lower[2])) &&
                              is_safe((bounds.lower[1], bounds.lower[2]))
end

# ╔═╡ 4bdbdc23-53b5-44f0-9d15-cb287bbba27f
get_bounds(get_leaf(initial_tree, (1.1, 0.3)), 2)

# ╔═╡ ec9a089b-8a9c-4ded-bdcb-c387cccbfab7
begin
	tree = set_safety!(deepcopy(initial_tree), 
		dimensionality, 
		is_safe, 
		any_action, 
		no_action)

	# Modification to make the split more interesting
	replace_subtree!(get_leaf(tree, 1.1, 1.1), Leaf(any_action))
end

# ╔═╡ c90215b5-fda7-49e4-83d5-789b9e3b7084
draw(tree, draw_bounds, color_dict=action_color_dict, aspectratio=:equal)

# ╔═╡ b96cef2c-612b-4097-89b5-2ddec13216b3
md"""
## The `ShieldingModel`

Everything is rolled up into a convenient little ball that is easy to toss around between functions. This ball is called `ShieldingModel`
"""

# ╔═╡ 34dbeedd-379e-4e22-91d7-c271a796a57b
md"""
### Parameters -- Try it Out!
!!! info "Tip"
	This cell controls multiple figures. Move it around to gain a better view.

Try setting a different number of samples per axis: 

`samples_per_axis =` $(@bind samples_per_axis NumberField(3:30, default=9))

`granularity =` $(@bind granularity NumberField(0:1E-15:1, default=1E-5))

`margin =` $(@bind margin NumberField(0:0.001:1, default=0.00))

`splitting_tolerance =` $(@bind splitting_tolerance NumberField(0:1E-10:1, default=1E-5))
"""

# ╔═╡ 364a95c2-de8a-468a-86eb-db18a5489c9d
m = ShieldingModel(simulation_function, Pace, dimensionality, samples_per_axis, random_variable_bounds; granularity, margin, splitting_tolerance)

# ╔═╡ 52015eb7-b4d8-4a08-98b4-c6e006179452
md"""
## Where to Split

Get ready to read some cursed code.
"""

# ╔═╡ dcab1452-9c39-4912-b6d9-0e013c2240d4
md"""
x: $(@bind x NumberField(0:0.02:rwmechanics.x_max))
t: $(@bind t NumberField(0:0.02:rwmechanics.t_max))
"""

# ╔═╡ e2c7decc-ec60-4eae-88c3-491ca06673ea
bounds = get_bounds(get_leaf(tree, 0.5, 0.5), m.dimensionality)

# ╔═╡ 16d39b87-8d2d-4a54-8eb1-ee727671e299
let
	draw(tree, draw_bounds, color_dict=action_color_dict, 
		aspectratio=:equal,
		legend=:outertop,
		size=(500,500))
	leaf_count = length(Leaves(tree) |> collect)

	scatter_allowed_actions!(tree, bounds, m)
	plot!([], l=nothing, label="leaves: $leaf_count")
	
end

# ╔═╡ e16be618-813f-4888-a247-e8f54d950de6
"""
	get_safety_judgements(a, bounds::Bounds, m::ShieldingModel)

 - `a` Action to make judgements about,
 - `bounds` Bounds to investigate.
 - `m` Supporting points are created based on this `ShieldingModel`.
Returns tuple `safe, points`.
- `points` contain a matrix of supporting points.
- `safe` is a matrix indicating whether `a` is safe in the corresponding supporting point in the `points` matrix.
"""
function get_safety_judgements(a, bounds::Bounds, m::ShieldingModel)
	supporting_points = SupportingPoints(m.samples_per_axis, bounds)
	array_dim = size(supporting_points)
	safe = Array{Bool}(undef, array_dim...)
	points = Array{Tuple{Float64, Float64}}(undef, array_dim...)
	
	indices = [1 for _ in 1:m.dimensionality]
	for p in supporting_points
		action_safe = true
		for r in SupportingPoints(m.samples_per_axis, m.random_variable_bounds)
                p′ = m.simulation_function(p, r, a)
				action_safe = action_safe && 
				get_value(get_leaf(tree, p′)) != no_action
		end
		safe[indices...] = action_safe
		points[indices...] = p
		for i in 1:m.dimensionality
			indices[i] += 1
			if indices[i] <= supporting_points.per_axis
				break
			end
			indices[i] = 1
		end
	end
	safe, points
end;

# ╔═╡ 15a3178c-499c-4443-9e28-3ab6106c2234
safety_judegement, corresponding_points = get_safety_judgements(slow, bounds, m)

# ╔═╡ 31b36e5b-c818-44a7-968f-38b6c9e79f9d
function plot_safety!(safe; params...)
	safe_color = colorant"#9eea94"
	unsafe_color = colorant"#ff9a9a"
	heatmap!(transpose(safe), c=cgrad([unsafe_color, safe_color]), legend=:outerright, cbar=nothing)
	plot!([], [], seriestype=:shape, line=0, color=unsafe_color, label="unsafe")
	plot!([], [], seriestype=:shape, line=0, color=safe_color, label="safe")
	
	hline!([i for i in 1:size(safe)[1]], label=nothing, color=colors.ASBESTOS)
	vline!([i for i in 1:size(safe)[2]], label=nothing, color=colors.ASBESTOS)
	plot!(;params...)
end

# ╔═╡ 3f4f2a52-1580-41e1-a954-842c15bf6a3e
plot(); plot_safety!(safety_judegement)

# ╔═╡ bff9cdd0-85dc-4afb-936b-c4623fa2c9ad
@recipe function rectangle(bounds::Bounds, pad=0.01) 
	l, u = bounds.lower, bounds.upper
	xl, yl = l .- pad
	xu, yu = u .+ pad
	Shape(
		[xl, xl, xu, xu],
		[yl, yu, yu, yl])
end

# ╔═╡ 384c936f-b585-4799-a930-b1bd33d9763a
# Looks like column-first indexing
small = Bool[ 
	0  1  1;
	1  1  1;
	1  1  0;
];

# ╔═╡ 1778479c-bd0c-444e-937e-a13242435cb4
# Looks like column-first indexing
medium = Bool[ 
	1  1  1  1  1  1  1  0  0;
	1  1  1  1  1  1  1  0  0;
	1  1  1  1  1  1  1  0  0;
	0  1  1  1  1  1  1  0  0;
	1  1  1  1  1  1  1  0  0;
	1  1  1  1  1  1  1  0  0;
	1  1  1  1  1  1  1  0  0;
	0  0  1  1  1  1  1  0  0;
	0  0  1  1  1  1  1  1  1;
];

# ╔═╡ da57aa64-055b-46aa-9e0c-7ad8d7e23bcf
@bind safe Select([medium => "medium", small => "small", safety_judegement => "safety_judegement"])

# ╔═╡ 3650e23b-0997-4391-bb02-dda6824fc2ab
plot(); plot_safety!(safe, size=(200, 230), legend=:outertop)

# ╔═╡ 82d43955-fcde-4615-be4a-d237f54ef38c
safe[1, 7], safe[1, 8]

# ╔═╡ e1e2843e-2793-42b0-b869-34d94867ca9a
initial_bounds = Bounds([2, 2], [2, 2])

# ╔═╡ e424844d-0c5d-4a8f-b983-4c91b6a51699
function area(bounds::Bounds{T})::T where T
	dim = get_dim(bounds)
	lengths = Vector{T}(undef, dim)
	for i in 1:dim
		lengths[i] = bounds.upper[i] - bounds.lower[i] 
	end
	prod(lengths)
end

# ╔═╡ 704c518a-e94a-4cca-bf8e-e4ab7b0a67af
function greatest_area(boundss::Bounds{T}...)::Bounds{T} where T
	greatest = boundss[1]
	greatest_area = typemin(T)
	for b in boundss
		area_result = area(b)
		if area_result > greatest_area
			greatest_area = area_result
			greatest = b
		end
	end
	greatest
end

# ╔═╡ 243045eb-1258-4c6e-9e4f-be9cd58c39c0
greatest_area(Bounds([1, 1], [2, 3]), Bounds([1, 2], [1, 8]))

# ╔═╡ 4c0120f7-36fe-4232-873d-68cd3e1d5231
area(Bounds([-1, 1], [2, 4]))

# ╔═╡ 3875ddf7-025e-44c8-8280-589e4caf32af
"""
	all_values(bounds::Bounds)

Similar to SupportingPoints, but for integer-valued bounds.
Returns a list containing all integer-valued points within `bounds`
"""
function all_values(bounds::Bounds)::Vector{NTuple}
	indices = collect(bounds.lower)
	dim = get_dim(bounds)
	result = NTuple{dim, Int64}[]
	while indices[end] <= bounds.upper[end]
		push!(result, Tuple(indices))
		for i in 1:dim
			indices[i] += 1
			if indices[i] <= bounds.upper[i]
				break
			end
			if i < dim
				indices[i] = 1
			end
		end
	end
	result
end;

# ╔═╡ 0501eeb1-abec-4d6b-8359-005cc4831ec5
function all_safe(safe, bounds::Bounds)
	all(safe[indices...] for indices in all_values(bounds))
end

# ╔═╡ c1607955-389c-43e5-bade-c19f1d5c69e7
function get_safe_extensions(safe, bounds::Bounds)
	result = Bounds[]
	dim::Int64 = get_dim(bounds)
	for i in 1:dim
		# Extend upwards
		bounds′ = Bounds(bounds.lower, collect(bounds.upper))
		bounds′.upper[i] += 1
		
		if (bounds′.lower[i] <= bounds′.upper[i] && 
				bounds′.upper[i] <= size(safe)[i] && 
				all_safe(safe, bounds′))
			
			push!(result, bounds′)
		end

		# Extend downwards
		bounds″ = Bounds(collect(bounds.lower), bounds.upper)
		bounds″.lower[i] -= 1
		
		if (bounds″.lower[i] <= bounds″.upper[i] && 
				bounds″.lower[i] > 0 && 
				all_safe(safe, bounds″))
			
			push!(result, bounds″)
		end
	end
	result
end

# ╔═╡ 8cccb57e-501d-4cfc-94c1-ea4e260f637a
get_safe_extensions(safe, Bounds([1, 2], [2, 2]))

# ╔═╡ db8482d5-5998-4f6c-aa2c-5936d81804cc
let 
	#rectangle with added margin

	plot()
	plot_safety!(safe)
	all = get_safe_extensions(safe, initial_bounds)
	for b in all
		plot!(b, 0.1, line=1, alpha=0.5, label="extension")
	end
	plot!(initial_bounds, 0.1, line=1, alpha=1, label="initial", color=colors.PETER_RIVER)
end

# ╔═╡ 9dcc62cd-7246-4875-8006-b62a5f9b8adc
all_safe(safe, Bounds([1, 6], [2, 6]))

# ╔═╡ f43944e5-1098-4dd2-a89a-5b7a620e5de5
"""
	best_bounds(safe, boundss...)

Returns the tuple `bounds, points`. 
- `points` are the greatest number of points contained within some bounds from params `boundss`, such that they are all safe according to `safe`. Or zero, if the `boundss` all contain unsafe points. 
- `bounds` are the bound which has the greatest number of safe points, or undefined if `points` is zero.
"""
function best_bounds(safe, boundss::Bounds{T}...)::Tuple{Bounds{T}, Int64} where T
	best = nothing
	points = 0
	for b in boundss
		all_values_result = all_values(b)
		if any(!safe[indices...] for indices in all_values_result)
			continue
		end
		if length(all_values_result) > points
			best = b
			points = length(all_values_result)
		end
	end
	best, points
end;

# ╔═╡ 8f3ed4f8-a261-4c05-ac46-0252a3ddd131
best_bounds(safe, Bounds([1, 1], [2, 3]), Bounds([1, 2], [1, 8]))

# ╔═╡ 193b9608-74f9-49da-ba6c-930a38d8d7b3
"""
	greatest_safe_bounds(safe, bounds::Bounds)

Returns the greatest safe bounds that include the given `bounds`.
"""
function greatest_safe_bounds(safe, 
	bounds::Bounds{T}, 
	# Dictionary to support Dynamic Programming
	dpd::Dict{Bounds{T}, Bounds{T}}=Dict{Bounds{T},Bounds{T}}()
)::Bounds{T} where T

	if haskey(dpd, bounds)
		return dpd[bounds]
	end
	
	extensions = get_safe_extensions(safe, bounds)

	# Recursion
	best = greatest_area(bounds, 
		[greatest_safe_bounds(safe, b, dpd) for b in extensions]...)

	dpd[bounds] = best
	return best
end;

# ╔═╡ 3d47fd67-a543-4658-906d-1e5b010db03d
safe; dpd = Dict{Bounds{Int},Bounds{Int}}()

# ╔═╡ 81b642ea-d8de-4640-b192-617592a65574
greatest_safe_result = @time greatest_safe_bounds(safe, initial_bounds, dpd)

# ╔═╡ f919c1a4-9a9a-4a6f-873c-91b7dd9dfe40
let
	plot(legend=:outerright,
		ticks=1:9)
	
	plot_safety!(safe)
	
	plot!(greatest_safe_result, .1,
		line=1,
		alpha=0.8,
		label="greatest safe",
		color=colors.NEPHRITIS)	
	
	plot!(initial_bounds, .1, 
		line=1,
		color=colors.PETER_RIVER,
		alpha=1,
		label="initial")
end

# ╔═╡ 597f7ab1-468e-4898-b5ff-130aea6bb7a3
"""
 	all_initial_bounds(safe)

Returns a list (TODO: could be an iterator) of all 0-by-0 bounds covering safe points. This can be used to call `greatest_safe_result` on each in turn to find the truly greatest regardless of initial bounds.

Yea I hope I will write some overall explanation when I'm done with this.
"""
function all_initial_bounds(safe)
	result = Vector{Bounds{Int64}}(undef, count(safe))
	dim = length(size(safe))
	i = 1
	for (indices, v) in pairs(safe)
		(!v) && continue
		indices = Tuple(indices)
		@assert i <= length(result)
		result[i] = Bounds(indices, indices)
		i += 1
	end	
	result
end;

# ╔═╡ 6be0301b-c2b9-43a0-9f27-99fa2a8ac63b
all_initial = all_initial_bounds(safe)

# ╔═╡ 0c85a9c0-8090-44fb-9fd0-ec15286c63c2
let
	plot(size=(300, 300))
	plot_safety!(safe)
	for b in all_initial
		plot!(b, 0.1, legend=nothing, color=colors.PETER_RIVER)
	end
	plot!()
end

# ╔═╡ 545984e2-e444-4495-bb46-f201db26670b
function to_statespace(
	bounds::Bounds{Int64}, 
	points::Matrix{NTuple{N, T}}
)::Bounds{T} where {N, T}
	
	Bounds(points[bounds.lower...], points[bounds.upper...])
end

# ╔═╡ 3297e971-d849-42c4-917a-dfd8ca1c37b7
to_statespace(greatest_safe_result, corresponding_points)

# ╔═╡ 6f0c554b-8592-435e-b6bc-789e8a989c6a
function find_splitting_bounds(action, 
	bounds::Bounds{T}, 
	m::ShieldingModel
) where T
	
	# Get the safety judgement
	safe, points = get_safety_judgements(action, bounds, m)

	# Find the greatest safe bounds, no matter where you start searching from
	best = nothing
	best_area = typemin(Int64)
	dpd = Dict{Bounds{Int64},Bounds{Int64}}()
	for b in all_initial_bounds(safe)
		b′ = greatest_safe_bounds(safe, b, dpd)
		area_b′ = area(b′)
		if area_b′ > best_area
			best = b′
			best_area = area_b′
		end
	end

	# Return converted back into state-space bounds
	to_statespace(best, points)
end

# ╔═╡ e0508b3e-aec1-42f2-89d6-52dd7b727791
find_splitting_bounds(slow, bounds, m)

# ╔═╡ 1a8c579c-df0d-400a-9adb-befa2827b577
splitting_bounds = @time find_splitting_bounds(fast, bounds, m)

# ╔═╡ 4685a23b-ecf2-4211-b6c3-c90f96d418bf
let
	draw(tree, draw_bounds, color_dict=action_color_dict, 
		aspectratio=:equal,
		legend=:outertop,
		size=(500,500))
	leaf_count = length(Leaves(tree) |> collect)

	scatter_allowed_actions!(tree, bounds, m)
	plot!([], l=nothing, label="leaves: $leaf_count")
		
	plot!(splitting_bounds, 
		label="splitting_bounds", 
		color=colors.NEPHRITIS, 
		alpha=0.7)
end

# ╔═╡ 0fc53ad2-e4e2-4a04-9745-6adc7eaf1267
"""
Split leaf by bounds.
Pluto gets sad if I try to override a function from another module.
"""
function split!!(leaf::Leaf, bounds::Bounds, inner=nothing, outer=nothing)::Tree
	inner = something(inner, leaf.value)
	outer = something(outer, leaf.value)
	dim = get_dim(bounds)
	bounds_leaf = get_bounds(leaf, m.dimensionality)
	new_subtree = leaf
	for i in 1:dim
		if bounds.lower[i] > bounds_leaf.lower[i]
			new_subtree = split!(leaf, i, bounds.lower[i], outer, inner)
			leaf = new_subtree.geq
		end
		
		if bounds.upper[i] < bounds_leaf.upper[i]
			new_subtree = split!(leaf, i, bounds.upper[i], inner, outer)
			leaf = new_subtree.lt
		end
	end
	return new_subtree
end;

# ╔═╡ 13cbb1d6-8f49-4bfb-956c-17c5a85a16d6
let
	tree = deepcopy(tree)
	leaf = get_leaf(tree, (0.5, 0.5))
	bounds = Bounds([0.4, 0.4], [0.5, 0.5])
	split!!(leaf, bounds)
	draw(tree, draw_bounds, size=(500, 500))
end

# ╔═╡ 1841566d-9068-422a-84b2-ec5b6bbaa653
md"""
# Putting it all together real quick
"""

# ╔═╡ 13179fba-74ce-4643-b1e0-544869d3a095
@bind iterations NumberField(0:100, default=1)

# ╔═╡ d644638e-e589-48e0-b511-c0d0d1ceb798
let
	tree = deepcopy(tree)
	unsafe = actions_to_int([])
	for i in 1:iterations
		changes = 1
		loop_break = 100
		while changes != 0
			changes = 0
			for leaf in Leaves(tree)
				leaf.value == unsafe && continue
				bounds = get_bounds(leaf, m.dimensionality)
				!bounded(bounds) && continue
				splitting_bounds = find_splitting_bounds(fast, bounds, m)
				area(splitting_bounds) == 0 && continue
				@info i splitting_bounds
				splitting_bounds == bounds && continue
				split!!(leaf, splitting_bounds)
				changes += 1
			end
			loop_break -= 1
			loop_break < 0 && break
		end
		update!(tree, m)
	end
	draw(tree, draw_bounds, size=(500, 500))
	bounds = get_bounds(get_leaf(tree, 0.5, 0.5), m.dimensionality)
	scatter_allowed_actions!(tree, bounds, m)
end

# ╔═╡ Cell order:
# ╟─6a50c8f7-6367-4d59-a574-c8a29a785e88
# ╠═23a8f930-95ae-4820-bac0-82edd0bfbc8a
# ╠═edf99af5-443f-4c23-b63d-51d5075b30b5
# ╠═1550fddd-6b9d-4b16-9265-c12f44b0f1e4
# ╠═00716b11-f49e-4790-9442-c4e24d05f369
# ╠═c669d727-88fb-4ee8-9f50-7681d1b8df5a
# ╠═193ea2f4-548f-4dcf-b661-4bf1aca16b43
# ╠═ae6142f5-ace2-4211-9318-6f8257f2fdfa
# ╠═b05c8d41-c62c-4780-90d6-7aa174645770
# ╟─00d60986-0a1b-4b8e-87e7-dc8597dc35b0
# ╠═55931748-f860-4ced-9fc9-3906368042ba
# ╠═f7da5f6e-7b6f-4a4d-a500-798fb37cd856
# ╟─463ea187-2aba-49af-a089-29eb280939dd
# ╟─70c269f7-e47c-4405-8012-4f1c68cfb879
# ╠═0e22d8cc-bd9d-4ff1-a369-c8f1b73f65f1
# ╠═d88cd139-6a31-4d9d-b1c5-f6828c16d441
# ╠═4ba1c107-8db5-4273-95f6-77b66b25b2c3
# ╟─9ea39d19-4238-4e6e-abb9-968bdcaa8851
# ╠═40068b9c-3faf-4091-9786-fbfab9973485
# ╟─d8904f0d-028f-4c65-bacc-c06fb7f80976
# ╠═1f92d031-9e32-4ad4-a2d2-105de6e99ea7
# ╠═2f48eb7a-f6e2-438b-8048-c3b3089a121e
# ╟─1c537f46-4f50-4009-87de-ffed4ca586e3
# ╠═c2df2986-7ef0-48fa-b816-7ad4dd317b97
# ╠═47ff5769-9f8e-486c-981f-f5bad2a449ce
# ╠═fbffa476-2fb1-46b3-b591-ecc7d6cc17d3
# ╠═4bdbdc23-53b5-44f0-9d15-cb287bbba27f
# ╠═ec9a089b-8a9c-4ded-bdcb-c387cccbfab7
# ╠═c90215b5-fda7-49e4-83d5-789b9e3b7084
# ╟─b96cef2c-612b-4097-89b5-2ddec13216b3
# ╠═364a95c2-de8a-468a-86eb-db18a5489c9d
# ╟─34dbeedd-379e-4e22-91d7-c271a796a57b
# ╟─52015eb7-b4d8-4a08-98b4-c6e006179452
# ╟─dcab1452-9c39-4912-b6d9-0e013c2240d4
# ╠═e2c7decc-ec60-4eae-88c3-491ca06673ea
# ╠═e0508b3e-aec1-42f2-89d6-52dd7b727791
# ╠═16d39b87-8d2d-4a54-8eb1-ee727671e299
# ╠═e16be618-813f-4888-a247-e8f54d950de6
# ╠═15a3178c-499c-4443-9e28-3ab6106c2234
# ╠═3f4f2a52-1580-41e1-a954-842c15bf6a3e
# ╠═31b36e5b-c818-44a7-968f-38b6c9e79f9d
# ╠═bff9cdd0-85dc-4afb-936b-c4623fa2c9ad
# ╠═384c936f-b585-4799-a930-b1bd33d9763a
# ╠═da57aa64-055b-46aa-9e0c-7ad8d7e23bcf
# ╠═1778479c-bd0c-444e-937e-a13242435cb4
# ╠═3650e23b-0997-4391-bb02-dda6824fc2ab
# ╠═82d43955-fcde-4615-be4a-d237f54ef38c
# ╠═e1e2843e-2793-42b0-b869-34d94867ca9a
# ╠═0501eeb1-abec-4d6b-8359-005cc4831ec5
# ╠═c1607955-389c-43e5-bade-c19f1d5c69e7
# ╠═8cccb57e-501d-4cfc-94c1-ea4e260f637a
# ╠═db8482d5-5998-4f6c-aa2c-5936d81804cc
# ╠═9dcc62cd-7246-4875-8006-b62a5f9b8adc
# ╠═f43944e5-1098-4dd2-a89a-5b7a620e5de5
# ╠═8f3ed4f8-a261-4c05-ac46-0252a3ddd131
# ╠═704c518a-e94a-4cca-bf8e-e4ab7b0a67af
# ╠═243045eb-1258-4c6e-9e4f-be9cd58c39c0
# ╠═e424844d-0c5d-4a8f-b983-4c91b6a51699
# ╠═4c0120f7-36fe-4232-873d-68cd3e1d5231
# ╠═3875ddf7-025e-44c8-8280-589e4caf32af
# ╠═193b9608-74f9-49da-ba6c-930a38d8d7b3
# ╠═3d47fd67-a543-4658-906d-1e5b010db03d
# ╠═81b642ea-d8de-4640-b192-617592a65574
# ╟─f919c1a4-9a9a-4a6f-873c-91b7dd9dfe40
# ╠═597f7ab1-468e-4898-b5ff-130aea6bb7a3
# ╠═6be0301b-c2b9-43a0-9f27-99fa2a8ac63b
# ╠═0c85a9c0-8090-44fb-9fd0-ec15286c63c2
# ╠═545984e2-e444-4495-bb46-f201db26670b
# ╠═3297e971-d849-42c4-917a-dfd8ca1c37b7
# ╠═6f0c554b-8592-435e-b6bc-789e8a989c6a
# ╠═1a8c579c-df0d-400a-9adb-befa2827b577
# ╠═4685a23b-ecf2-4211-b6c3-c90f96d418bf
# ╠═0fc53ad2-e4e2-4a04-9745-6adc7eaf1267
# ╠═13cbb1d6-8f49-4bfb-956c-17c5a85a16d6
# ╠═1841566d-9068-422a-84b2-ec5b6bbaa653
# ╠═d644638e-e589-48e0-b511-c0d0d1ceb798
# ╠═13179fba-74ce-4643-b1e0-544869d3a095
