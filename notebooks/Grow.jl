### A Pluto.jl notebook ###
# v0.19.20

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

# ╔═╡ 404bae97-6794-4fa6-97bf-d09851900305
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
	TableOfContents()
end

# ╔═╡ 06791d29-7dbd-4487-8448-cc84a1631025
@revise using TreeShielding

# ╔═╡ 137adf90-a162-11ed-358b-6fc69c09feba
md"""
# Growing the tree
This notebook demonstrates the `grow!` function. Scroll to the bottom to see it in action, or read from the beginning to get the full context of what it does.
"""

# ╔═╡ 4b35159a-d14c-4449-8bfb-7a9703fa9b16
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

# ╔═╡ cf0d7908-2594-456d-88ff-61f8aab4d167
policy_colors = [colors.CLOUDS, colors.SUNFLOWER, colors.CONCRETE, colors.PETER_RIVER, colors.ASBESTOS, colors.ORANGE]

# ╔═╡ ff1db4e2-edc1-43d9-ad8e-3378363cd506
safe_unsafe = cgrad([colorant"#ff9178", colorant"#ffffff"], 2, categorical=true)

# ╔═╡ b738614d-9040-430e-94a3-9051a07765c5
call(f) = f()

# ╔═╡ deab42ea-ba6b-4bca-97f5-02217d532de7
dimensionality = 2

# ╔═╡ 86e9b7f7-f1f5-4ba2-95d6-5e528b1c0ce6
md"""
## Where to Split

Computing the threshold for splitting the state space, such that all unsafe supporting points are to one side. 

If such a threshold exists, that is. Otherwise it returns `nothing`.
"""

# ╔═╡ ccf04ab6-d3f9-4abf-ae66-0e5d9653adff
function get_splitting_point(points_safe, axis, margin)
	if !any([safe for (p, safe) in points_safe]) ||  
			!any([!safe for (p, safe) in points_safe])
		return nothing
	end
	
	# least upper bound
	lub_safe = max([p[axis] for (p, safe) in points_safe if safe]...)
	lub_unsafe = max([p[axis] for (p, safe) in points_safe if !safe]...)

	# greatest lower bound
	glb_safe = min([p[axis] for (p, safe) in points_safe if safe]...)
	glb_unsafe = min([p[axis] for (p, safe) in points_safe if !safe]...)
	
	if glb_unsafe > glb_safe
		return glb_unsafe - margin
	elseif lub_unsafe < lub_safe
		return lub_unsafe + margin
	else
		return nothing
	end
end

# ╔═╡ 68456825-7eba-445f-8939-e83c68498b23
md"""

arguments: 
- `points_safe` (Better name pending.) A list of points that contains (point,bool)-tuples indicating whether each point is safe.
- `axis` Which axis to split on.
- `margin` This value will be added to the returned threshold. Should ideally be half the distance between points.
"""

# ╔═╡ 2b618fae-ca7d-412b-8edb-93305ca25353
md"""
Check boxes to set whether points are safe: 

[ $(@bind p_1_3 CheckBox(default=true)) ]
[ $(@bind p_2_3 CheckBox(default=true)) ]
[ $(@bind p_3_3 CheckBox(default=true)) ]

[ $(@bind p_1_2 CheckBox(default=true)) ]
[ $(@bind p_2_2 CheckBox(default=true)) ]
[ $(@bind p_3_2 CheckBox(default=true)) ]

[ $(@bind p_1_1 CheckBox(default=true)) ]
[ $(@bind p_2_1 CheckBox(default=false)) ]
[ $(@bind p_3_1 CheckBox(default=false)) ]

"""

# ╔═╡ d8b0d276-6bbb-4dca-9a66-00f421316c87
points_safe = [
		((1, 1), p_1_1),
		((2, 1), p_2_1),
		((3, 1), p_3_1),
		((1, 2), p_1_2),
		((1, 3), p_1_3),
		((2, 2), p_2_2),
		((2, 3), p_2_3),
		((3, 2), p_3_2),
		((3, 3), p_3_3),
	]

# ╔═╡ 43dbb196-adc8-4c9f-8c1a-333d563ebec6
# Testing out the get_split function
call() do
	p1 = scatter([p for (p, _) in points_safe], 
		m=(:+, 7, colors.WET_ASPHALT), msw=4, 
		label="supporting points", 
		legend=:outerright,
		ticks=1:3)

	unsafe = [p for (p, safe) in points_safe if !safe]
	scatter!(unsafe, 
		m=(:x, 7, colors.ALIZARIN), msw=3, 
		label="unsafe")

	margin = 0.5
	
	split1 = get_splitting_point(points_safe, 1, margin)
	if split1 !== nothing
		vline!([split1], label=nothing, lw=2, c=colors.WET_ASPHALT, ls=:dash)
	end
	split2 = get_splitting_point(points_safe, 2, margin)
	if split2 !== nothing
		hline!([split2], label=nothing, lw=2, c=colors.WET_ASPHALT, ls=:dash)
	end
	if split1 !== nothing || split2 !== nothing
		plot!([], label="split", lw=2, c=colors.WET_ASPHALT, ls=:dash)
	end
	p1
end

# ╔═╡ b5cfaea1-1420-4205-a1d5-4989347ad6c5
md"""
## Example-tree

This tree will be used in the future examples. It has a single fully bounded partition (in the sense that all the bounds are finite) and an unsafe partition (in the sense that no actions are allowed in it).
"""

# ╔═╡ 10c53e89-6e56-4897-9d41-bb7fe8dcb9ae
@enum Actions bar baz

# ╔═╡ ae19f184-d2ec-474b-abfd-2a8cd98ad191
any_action, no_action = actions_to_int(Actions, instances(Actions)), actions_to_int(Actions, [])

# ╔═╡ ffb29885-827f-4dea-b127-0f6b5a2defa4
action_color_dict=Dict(
	any_action => colorant"#ffffff", 
	1 => colorant"#a1eaff", 
	no_action => colorant"#ff9178"
)

# ╔═╡ 30c73092-a14c-4b83-bcac-8526c0a8780a
initial_tree = Node(1, 3,
	Node(2, 10,
		Leaf(no_action),
		Leaf(any_action)),
	# A nicely bounded partition
	Node(1, 4,
		Node(2, 5,
			Leaf(any_action),
			Node(2, 10,
				Leaf(any_action),
				Leaf(any_action))),
		Leaf(any_action)))

# ╔═╡ 90b9f332-5518-409d-8bd2-3089da927e0f
tree_draw_bounds = Bounds((0, 0), (5, 20))

# ╔═╡ 419cacdb-2503-4d39-827c-5b838b2a0b8a
md"""
### Making a Draw-function
"""

# ╔═╡ 0788966a-69bf-4f33-a8c3-6a25bc33e7a3
begin 
	rectangle(w, h, x, y) = Shape(x .+ [0,w,w,0], y .+ [0,0,h,h])
	
	function rectangle(bounds::Bounds) 
		l, u = bounds.lower, bounds.upper
		xl, yl = l
		xu, yu = u
		Shape(
			[xl, xl, xu, xu],
			[yl, yu, yu, yl])
	end
end

# ╔═╡ 36327251-e084-43b6-ae27-4787463b7fca
function draw′(tree::Tree, global_bounds::Bounds; color_dict=Dict())
	dimensionality = 2
	rectangles = []
	fillcolors = []
	for leaf in Leaves(tree)
		bounds = get_bounds(leaf, dimensionality) ∩ global_bounds
		push!(rectangles, rectangle(bounds))
		push!(fillcolors, get(color_dict, leaf.value, leaf.value))
	end
	fillcolors = permutedims(fillcolors)
	plot([rectangles...], label=nothing, fillcolor=fillcolors)
end

# ╔═╡ 0bd0fcf9-e65f-4443-952d-df54d423a344
draw′(initial_tree, tree_draw_bounds, color_dict=action_color_dict)

# ╔═╡ d5e35fb6-470b-4f30-a54d-cf82283068e8
md"""
## Example Simulation Function

Pretty simple stuff. Remember to come back and play with the values once you've read how it's used.
"""

# ╔═╡ b5244181-a6fc-4537-9046-3a2bc8a050b1
foo(s) = Tuple(s .+ [-0.9, 3])

# ╔═╡ fe163130-24c3-4c7e-b7a0-4e162ac26b5d
md"""
## Computing Safety

Using a simulation function, we can compute which points in a set of points might reach an unsafe state.
"""

# ╔═╡ 0dccf16d-c9ae-4d69-b6b2-3118502ef9c4
function compute_safety(tree, simulation_function, points)
	result = []
	for p in points
		p′ = simulation_function(p)
		safe = get_value(tree, p′) != no_action
		push!(result, (p, safe))
	end
	result
end

# ╔═╡ 02baf662-4ace-47ad-bd76-72e259a4861a
md"""
Try setting a different number of samples per axis: 

`spa =` $(@bind spa NumberField(1:10, default=3))
"""

# ╔═╡ e3c9c499-d55d-4e4b-a239-c3ccc721f0c3
call() do
	bounds = get_bounds(get_leaf(initial_tree, 3, 5), dimensionality)
	supporting_points = SupportingPoints(spa, bounds)
	points_safe = compute_safety(initial_tree, foo, supporting_points)
end

# ╔═╡ 6da5b379-ee87-42d1-8f48-5c465d4c4078
md"""
## Splitting the Tree

Trying to apply this split to actual supporting points in a tree.
"""

# ╔═╡ 047262de-4584-4037-80da-0ee148f8e8a5
scatter_supporting_points!(s::SupportingPoints) = 
	scatter!(unzip(s), 
		m=(:+, 5, colors.WET_ASPHALT), msw=4, 
		label="supporting points")

# ╔═╡ 2b2421b7-34a5-4de0-b191-b0f9f4a914a3
call() do
	bounds = get_bounds(get_leaf(initial_tree, 3, 5), dimensionality)
	p1 = draw′(initial_tree, tree_draw_bounds, color_dict=action_color_dict)
	supporting_points = SupportingPoints(spa, bounds)
	scatter_supporting_points!(supporting_points)
	foo_points = map(foo, supporting_points)
	scatter!(foo_points, m=(:c, 3, colors.ASBESTOS), msw=0, label="outcomes")

	points_safe = compute_safety(initial_tree, foo, supporting_points)
	unsafe_points = [p for (p, safe) in points_safe if !safe]
	scatter!(unsafe_points, m=(:x, 5, colors.ALIZARIN), msw=3, label="unsafe")
end

# ╔═╡ 09a48bc2-9e8d-462c-abad-23d8ce60e058
call() do
	bounds = get_bounds(get_leaf(initial_tree, 3, 5), dimensionality)
	p1 = draw′(initial_tree, tree_draw_bounds, color_dict=action_color_dict)
	supporting_points = SupportingPoints(spa, bounds)
	scatter_supporting_points!(supporting_points)
	foo_points = map(foo, supporting_points)
	scatter!(foo_points, m=(:c, 3, colors.ASBESTOS), msw=0, label="outcomes")

	points_safe = compute_safety(initial_tree, foo, supporting_points)
	unsafe_points = [p for (p, safe) in points_safe if !safe]
	scatter!(unsafe_points, m=(:x, 5, colors.ALIZARIN), msw=3, label="unsafe")


	spacings = get_spacing_sizes(supporting_points, dimensionality)
	
	margin1 = spacings[1]/2
	split1 = get_splitting_point(points_safe, 1, margin1)
	if split1 !== nothing
		vline!([split1], label=nothing, lw=2, c=colors.WET_ASPHALT, ls=:dash)
	end
	margin2 = spacings[2]/2
	split2 = get_splitting_point(points_safe, 2, margin2)
	if split2 !== nothing
		hline!([split2], label=nothing, lw=2, c=colors.WET_ASPHALT, ls=:dash)
	end
	if split1 !== nothing || split2 !== nothing
		plot!([], label="split", lw=2, c=colors.WET_ASPHALT, ls=:dash)
	end
	p1
end

# ╔═╡ d9887d6e-26da-4104-a89d-27ceb58a755a
call() do
	bounds = get_bounds(get_leaf(initial_tree, 3, 5), dimensionality)
	points_safe = compute_safety(initial_tree, foo, SupportingPoints(3, bounds))
end

# ╔═╡ c98a1165-9c3d-40df-8dee-e6e11a4ed2b5
md"""
## The `try_splitting!` Function

Makes calls to `get_splitting_point` for each axis, and performs the first split which can be made. The split can be made if 

 - The leaf is properly bounded. That is, its bounds are finite on all axes.
 - `get_splitting_point` returns something other than `nothing`, i.e. there exists a thereshold such that all points are safe on one side of it.
 - The threshold would not create a bound whose size is smaller than `min_granularity`.

Returns `true` if a split is made, and `false` otherwise.
"""

# ╔═╡ d9fa8430-c474-4990-97b2-11ba77b85c7d
function try_splitting!(leaf::Leaf, 
		dimensionality, 
		simulation_function, 
		samples_per_axis,
		min_granularity)
	
	root = getroot(leaf)
	bounds = get_bounds(leaf, dimensionality)
	
	if !bounded(bounds)
		return false
	end
	
	supporting_points = SupportingPoints(samples_per_axis, bounds)
	points_safe = compute_safety(root, simulation_function, supporting_points)
	spacings = get_spacing_sizes(supporting_points, dimensionality)
	
	for axis in (1:dimensionality)
		margin = spacings[axis]/2
		threshold = get_splitting_point(points_safe, axis, margin)
		
		if threshold == nothing 
			continue
		end

		lower, upper = bounds.lower[axis], bounds.upper[axis]
		if  abs(threshold - lower) < min_granularity ||
			abs(threshold - upper) < min_granularity
			continue
		end
		
		split!(leaf, axis, threshold)
		return true
	end

	return false
end

# ╔═╡ e69c7e85-b184-45b4-a3c5-ce1dc88010a1
md"""
### Try it Out! 
"""

# ╔═╡ 843b96e7-3b4b-4389-b736-f16142133e2d
md"""
Set the number of zeros preceeding the one in `min_granularity`

`min_granularity_zeros:` 

$(@bind min_granularity_zeros Slider(0:15, default=10))
"""

# ╔═╡ b4efde7a-eaac-4070-b332-29c3f76c43a9
min_granularity = 10.0^(-min_granularity_zeros)

# ╔═╡ b37b67cf-09e3-4c3a-865f-9a8a79d43c68
md"""
The `reactive_tree` will be initialized as a copy of `initial_tree`. I'm using the `reactive` prefix to signify that this variable will be mutated by running the same cells multiple times. 

This can be easily done with buttons, such as:

 $(@bind reset_tree Button("Reset Tree"))
"""

# ╔═╡ 41be8c5c-5cb9-4123-a902-9d673a5f29a9
begin
	reset_tree
	reactive_tree = deepcopy(initial_tree)
end

# ╔═╡ 2a74f21d-0de7-4169-a767-ec0d4b0b1adb
md"""
All leaves are put into a queue...

$(@bind refill_queue Button("Refill Queue"))
"""

# ╔═╡ e50b8e26-80ca-4571-9e7a-105221523df4
begin
	refill_queue

	reactive_queue = collect(Leaves(reactive_tree))
end

# ╔═╡ 17d3107b-6437-4518-b32b-fdd87ad9c3a2
md"""
...and using reactivity, we can call `try_splitting!` on each leaf in turn. 

$(@bind do_next_split Button("Do Next Split"))
"""

# ╔═╡ 568bee1c-ae0b-4892-b7ea-496002cde79d
begin
	do_next_split
	if length(reactive_queue) > 0
		leaf_to_split = pop!(reactive_queue)
	else
		md"Time to refill the queue!"
	end
end

# ╔═╡ 35af8e23-cdc7-498c-8bc8-c17b3e339597
md"""
Leaf was split:
"""

# ╔═╡ 48b66592-c82f-4626-8b63-475ef761ef96
try_splitting!(leaf_to_split, 
				dimensionality, 
				foo, 
				spa,
				min_granularity)

# ╔═╡ c388ec0a-b850-49ad-b74f-e0744c367942
begin
	do_next_split
	draw′(reactive_tree, tree_draw_bounds, color_dict=action_color_dict)
end

# ╔═╡ 0a30810f-ed03-4237-8362-a502c4470320
md"""
## Putting everything together in `grow!`

Clicking around on those buttons was a lot of fun, but how about coding up a function to do this automatically? 

Calling `split_all!` will perform splits until no changes are made.
"""

# ╔═╡ d1630c4c-c185-4f6c-9f25-45f63a2640ce
function grow!(tree::Tree, 
					dimensionality,
					simulation_function, 
					samples_per_axis,
					min_granularity;
					max_iterations=1000)
	

	changes = [true] # Array to keep up with wether any leaf was split
	while any(changes)
		if (max_iterations -= 1) < 0
			break
		end
		
		changes = [] 
		queue = collect(Leaves(tree))
		for leaf in queue
			changed = try_splitting!(leaf, 
				dimensionality, 
				simulation_function, 
				samples_per_axis,
				min_granularity)
			push!(changes, changed)
		end
	end
	tree
end

# ╔═╡ f76bca8f-70d7-46be-a98e-1acc1a4958d8
md"""
Try messing with the number of iterations vs the `min_granularity`.
"""

# ╔═╡ f69efe68-2d16-4c86-9f83-6d64ad09a783
@bind max_iterations NumberField(0:100, default=5)

# ╔═╡ 52fb4f65-9974-4b95-9090-e0a50a487b22
call() do
	tree = deepcopy(initial_tree)
	grow!(tree, dimensionality, foo, spa, min_granularity; max_iterations)
	
	draw′(tree, tree_draw_bounds, color_dict=action_color_dict)

	p = (3.6, 7.05)
	bounds = get_bounds(get_leaf(tree, p), dimensionality)
	scatter_supporting_points!(SupportingPoints(spa, bounds))
	foo_points = map(foo, SupportingPoints(3, bounds))
	scatter!(foo_points, m=(:c, 3, colors.CONCRETE), msw=0, label="outcomes")

	points_safe = compute_safety(tree, foo, SupportingPoints(spa, bounds))
	unsafe_points = [p for (p, safe) in points_safe if !safe]
	scatter!(unsafe_points, m=(:x, 5, colors.ALIZARIN), msw=3, label="unsafe")
	scatter!([], m=(0), msw=0, label="tree-size: $(length(PreOrderDFS(tree) |> collect))")
end

# ╔═╡ Cell order:
# ╟─137adf90-a162-11ed-358b-6fc69c09feba
# ╠═404bae97-6794-4fa6-97bf-d09851900305
# ╠═06791d29-7dbd-4487-8448-cc84a1631025
# ╟─4b35159a-d14c-4449-8bfb-7a9703fa9b16
# ╠═cf0d7908-2594-456d-88ff-61f8aab4d167
# ╠═ffb29885-827f-4dea-b127-0f6b5a2defa4
# ╠═ff1db4e2-edc1-43d9-ad8e-3378363cd506
# ╠═b738614d-9040-430e-94a3-9051a07765c5
# ╠═deab42ea-ba6b-4bca-97f5-02217d532de7
# ╟─86e9b7f7-f1f5-4ba2-95d6-5e528b1c0ce6
# ╠═ccf04ab6-d3f9-4abf-ae66-0e5d9653adff
# ╟─68456825-7eba-445f-8939-e83c68498b23
# ╟─2b618fae-ca7d-412b-8edb-93305ca25353
# ╠═d8b0d276-6bbb-4dca-9a66-00f421316c87
# ╠═43dbb196-adc8-4c9f-8c1a-333d563ebec6
# ╟─b5cfaea1-1420-4205-a1d5-4989347ad6c5
# ╠═10c53e89-6e56-4897-9d41-bb7fe8dcb9ae
# ╠═ae19f184-d2ec-474b-abfd-2a8cd98ad191
# ╠═30c73092-a14c-4b83-bcac-8526c0a8780a
# ╠═90b9f332-5518-409d-8bd2-3089da927e0f
# ╟─419cacdb-2503-4d39-827c-5b838b2a0b8a
# ╠═0788966a-69bf-4f33-a8c3-6a25bc33e7a3
# ╠═36327251-e084-43b6-ae27-4787463b7fca
# ╠═0bd0fcf9-e65f-4443-952d-df54d423a344
# ╟─d5e35fb6-470b-4f30-a54d-cf82283068e8
# ╠═b5244181-a6fc-4537-9046-3a2bc8a050b1
# ╟─fe163130-24c3-4c7e-b7a0-4e162ac26b5d
# ╠═0dccf16d-c9ae-4d69-b6b2-3118502ef9c4
# ╠═e3c9c499-d55d-4e4b-a239-c3ccc721f0c3
# ╟─02baf662-4ace-47ad-bd76-72e259a4861a
# ╠═047262de-4584-4037-80da-0ee148f8e8a5
# ╠═2b2421b7-34a5-4de0-b191-b0f9f4a914a3
# ╟─6da5b379-ee87-42d1-8f48-5c465d4c4078
# ╠═09a48bc2-9e8d-462c-abad-23d8ce60e058
# ╠═d9887d6e-26da-4104-a89d-27ceb58a755a
# ╟─c98a1165-9c3d-40df-8dee-e6e11a4ed2b5
# ╠═d9fa8430-c474-4990-97b2-11ba77b85c7d
# ╟─e69c7e85-b184-45b4-a3c5-ce1dc88010a1
# ╟─843b96e7-3b4b-4389-b736-f16142133e2d
# ╠═b4efde7a-eaac-4070-b332-29c3f76c43a9
# ╟─b37b67cf-09e3-4c3a-865f-9a8a79d43c68
# ╠═41be8c5c-5cb9-4123-a902-9d673a5f29a9
# ╟─2a74f21d-0de7-4169-a767-ec0d4b0b1adb
# ╠═e50b8e26-80ca-4571-9e7a-105221523df4
# ╟─17d3107b-6437-4518-b32b-fdd87ad9c3a2
# ╠═568bee1c-ae0b-4892-b7ea-496002cde79d
# ╟─35af8e23-cdc7-498c-8bc8-c17b3e339597
# ╠═48b66592-c82f-4626-8b63-475ef761ef96
# ╠═c388ec0a-b850-49ad-b74f-e0744c367942
# ╟─0a30810f-ed03-4237-8362-a502c4470320
# ╠═d1630c4c-c185-4f6c-9f25-45f63a2640ce
# ╟─f76bca8f-70d7-46be-a98e-1acc1a4958d8
# ╠═f69efe68-2d16-4c86-9f83-6d64ad09a783
# ╠═52fb4f65-9974-4b95-9090-e0a50a487b22
