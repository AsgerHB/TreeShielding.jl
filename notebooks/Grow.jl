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
begin
	@revise using TreeShielding
	using TreeShielding.RW
end

# ╔═╡ 137adf90-a162-11ed-358b-6fc69c09feba
md"""
# Growing the tree
This notebook demonstrates the `grow!` function. Scroll to the bottom to see it in action, or read from the beginning to get the full context of what it does.
"""

# ╔═╡ 6f3ab58d-545b-4b60-8f2a-0cb5d4fbd59e
md"""
## Preliminaries
"""

# ╔═╡ 5ac41bda-dffe-4fcb-962d-2222df7b33cf
md"""
### Colors
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

# ╔═╡ b738614d-9040-430e-94a3-9051a07765c5
call(f) = f()

# ╔═╡ deab42ea-ba6b-4bca-97f5-02217d532de7
dimensionality = 2

# ╔═╡ f3dd8d47-d582-4e76-ba7c-8975280eb273
md"""
### Plotting Convenience Functions
"""

# ╔═╡ 4a2cc218-1278-48a2-8e8e-2deabc664802
scatter_supporting_points!(s::SupportingPoints) = 
	scatter!(unzip(s), 
		m=(:+, 5, colors.WET_ASPHALT), msw=4, 
		label="supporting points")

# ╔═╡ a8b53549-5de6-43c8-983d-43e8ca1520da
scatter_outcomes!(outcomes) = scatter!(outcomes, m=(:c, 3, colors.ASBESTOS), msw=0, label="outcomes")

# ╔═╡ 4fe2ab4a-6bc3-40a1-9aed-b702a0fcdf69
function draw_support_points!(tree::Tree, 
	dimensionality, 
	simulation_function, 
	action_space,
	spa, 
	p, 
	action)
	
	bounds = get_bounds(get_leaf(tree, p), dimensionality)
	supporting_points = SupportingPoints(spa, bounds)
	scatter_supporting_points!(supporting_points)
	outcomes = map(p -> simulation_function(p, action), supporting_points)
	scatter_outcomes!(outcomes)

	points_safe = compute_safety(tree, 
		simulation_function, 
		action_space, 
		supporting_points)
	
	unsafe_points = [p for (p, safe) in points_safe if !safe]
	scatter!(unsafe_points, m=(:x, 5, colors.ALIZARIN), msw=3, label="unsafe")
end

# ╔═╡ f14a4efc-1063-4e0d-b968-6c5f46a8c384
md"""
## Example Function and safety constraint

This notebook uses the Random Walk example, which is included in the RW module.
"""

# ╔═╡ d043a35e-8092-4306-afbc-e076200e6240
any_action, no_action = 
	actions_to_int(Pace, instances(Pace)), actions_to_int(Pace, [])

# ╔═╡ ffb29885-827f-4dea-b127-0f6b5a2defa4
action_color_dict=Dict(
	any_action => colorant"#ffffff", 
	1 => colorant"#a1eaff", 
	no_action => colorant"#ff9178"
)

# ╔═╡ 7fd00150-0b98-4825-8064-3c805e077206
evaluate(rwmechanics, (_, _) -> RW.slow)

# ╔═╡ 3cee4706-ea98-47b4-aec1-59b27c1cfd0e
begin
	plot(aspectratio=:equal, size=(300, 300), xlabel="x", ylabel="t")
	xlims!(rwmechanics.x_min, rwmechanics.x_max + 0.1)
	ylims!(rwmechanics.t_min, rwmechanics.t_max + 0.1)
	draw_walk!(take_walk(rwmechanics, (_, _) -> rand([RW.slow, RW.fast]))...)
end

# ╔═╡ de7fe51c-0f75-49bb-bc6f-726a21bcd064
md"""
The function for taking a single step needs to be wrapped up, so that it only takes the arguments `point` and `action`.
"""

# ╔═╡ 07ed71cc-a931-4785-9707-86aad883df30
simulation_function(point, action) = RW.simulate(
	rwmechanics, 
	point[1], 
	point[2], 
	action,
	unlucky=true)

# ╔═╡ ef8dcaa1-4e61-450e-af1e-7cd54e7507f3
md"""
The goal of the game is to reach `x >= x_max` without reaching `t >= t_max`. 

This corresponds to the below safety property. It is defined both for a single `(x, t)` point, as well as for a set of points given by `Bounds`.
"""

# ╔═╡ 1cb52b21-8d14-4e2e-ad63-788a56d6bcd2
begin
	is_safe(point) = point[2] <= rwmechanics.t_max
	is_safe(bounds::Bounds) = is_safe((bounds.lower[1], bounds.upper[2]))
end

# ╔═╡ 9f9aed0a-66c3-4628-8e7f-cc59374383c9
md"""
## Building the Initial Tree

Building a tree with a properly bounded state space, and some divisions that align with the safety constraints.

A **bump** is introduced to make the splitting more interesting to look at.
"""

# ╔═╡ a136ec18-5e84-489b-a13a-ff4ffbb1870d
outer_bounds = Bounds(
	(rwmechanics.x_min, rwmechanics.t_min), 
	(rwmechanics.x_max, rwmechanics.t_max))

# ╔═╡ 0b6ba501-bc18-4239-b99e-6365b6f5deac
draw_bounds = Bounds(
	outer_bounds.lower .- [0.5, 0.5],
	outer_bounds.upper .+ [0.5, 0.5]
)

# ╔═╡ b2bc01c9-f501-4c75-8fc4-56dad5cd5c38
begin
	initial_tree = tree_from_bounds(outer_bounds, any_action, any_action)
	
	x_min, y_min = rwmechanics.x_min, rwmechanics.t_min
	x_max, y_max = rwmechanics.x_max, rwmechanics.t_max
	split!(get_leaf(initial_tree, x_min - 1, y_max), 2, y_max)
	split!(get_leaf(initial_tree, x_max + 1, y_max), 2, y_max - 0.3) # The **bump**
end

# ╔═╡ af5236ad-e88e-486d-ab43-e4d1a85a7333
draw(initial_tree, draw_bounds, color_dict=action_color_dict, aspectratio=:equal)

# ╔═╡ ee408360-8c64-4619-9810-6038738045dc
tree = set_safety!(deepcopy(initial_tree), 
		dimensionality, 
		is_safe, 
		any_action, 
		no_action)

# ╔═╡ e9c86cfa-e53f-4c1e-9102-14c821f4232a
draw(tree, draw_bounds, color_dict=action_color_dict, aspectratio=:equal)

# ╔═╡ 86e9b7f7-f1f5-4ba2-95d6-5e528b1c0ce6
md"""
## Where to Split

The following function has the answer:
"""

# ╔═╡ ccf04ab6-d3f9-4abf-ae66-0e5d9653adff
@doc get_splitting_point

# ╔═╡ 2b618fae-ca7d-412b-8edb-93305ca25353
md"""
### Try it Out!

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

# ╔═╡ fe163130-24c3-4c7e-b7a0-4e162ac26b5d
md"""
## Computing Safety

Using a simulation function, we can compute which points in a set of points might reach an unsafe state.
"""

# ╔═╡ 0dccf16d-c9ae-4d69-b6b2-3118502ef9c4
@doc compute_safety

# ╔═╡ 02baf662-4ace-47ad-bd76-72e259a4861a
md"""
Try setting a different number of samples per axis: 

`spa =` $(@bind spa NumberField(1:10, default=3))
"""

# ╔═╡ e3c9c499-d55d-4e4b-a239-c3ccc721f0c3
call() do
	bounds = get_bounds(get_leaf(initial_tree, 0.5, 0.5), dimensionality)
	supporting_points = SupportingPoints(spa, bounds)
	points_safe = compute_safety(initial_tree, simulation_function, Pace, supporting_points)
end

# ╔═╡ 2b2421b7-34a5-4de0-b191-b0f9f4a914a3
call() do
	bounds = get_bounds(get_leaf(tree, 0.5, 0.5), dimensionality)
	p1 = draw(tree, draw_bounds, color_dict=action_color_dict,legend=:outerright)
	supporting_points = SupportingPoints(spa, bounds)
	scatter_supporting_points!(supporting_points)
end

# ╔═╡ 6da5b379-ee87-42d1-8f48-5c465d4c4078
md"""
## Splitting the Tree

Trying to apply this split to actual supporting points in a tree.
"""

# ╔═╡ 09a48bc2-9e8d-462c-abad-23d8ce60e058
call() do
	leaf = get_leaf(tree, 0.5, 0.5)
	bounds = get_bounds(leaf, dimensionality)
	p1 = draw(tree, draw_bounds, color_dict=action_color_dict)
	supporting_points = SupportingPoints(spa, bounds)

	draw_support_points!(tree, dimensionality, simulation_function, Pace, spa, (0.5, 0.5), RW.fast)


	points_safe = compute_safety(tree, 
		simulation_function, 
		Pace, 
		SupportingPoints(spa, bounds))
	
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
	
	plot!(legend=:outerright)
end

# ╔═╡ c98a1165-9c3d-40df-8dee-e6e11a4ed2b5
md"""
## The `try_splitting!` Function
"""

# ╔═╡ d9fa8430-c474-4990-97b2-11ba77b85c7d
@doc try_splitting!

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
	reactive_tree = deepcopy(tree)
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
		leaf_to_split = nothing
		md"Time to refill the queue!"
	end
end

# ╔═╡ b4f6c703-b6ea-4ffa-998e-e6eba4e309b9
leaf_to_split; ["Leaf($(leaf.value))" for leaf in reactive_queue]

# ╔═╡ 35af8e23-cdc7-498c-8bc8-c17b3e339597
md"""
A split was performed: 👇
"""

# ╔═╡ 48b66592-c82f-4626-8b63-475ef761ef96
if leaf_to_split !== nothing
	try_splitting!(leaf_to_split, 
					dimensionality, 
					simulation_function, 
					Pace,
					spa,
					min_granularity)
else
	md"Time to refill queue!"
end

# ╔═╡ fdb7f7d2-6923-43ca-8364-5e4cb42ef8f0
md"""
`show_supporting_points:`
$(@bind show_supporting_points CheckBox(default=true))

`a =` $(@bind a Select(instances(Pace) |> collect, default=RW.fast))

Position: 
$(@bind partition_x 
	NumberField(outer_bounds.lower[1]:0.01:outer_bounds.upper[1], default=0.9))
$(@bind partition_y 
	NumberField(outer_bounds.lower[2]:0.01:outer_bounds.upper[2], default=0.9))
"""

# ╔═╡ c388ec0a-b850-49ad-b74f-e0744c367942
begin
	do_next_split
	draw(reactive_tree, draw_bounds, color_dict=action_color_dict)
	
	if show_supporting_points
		p = (partition_x, partition_y)
		draw_support_points!(reactive_tree, dimensionality, simulation_function, Pace, spa, p, a)
		scatter!(p, m=(4, :rtriangle, :white), msw=1, label=nothing, )
	end
	plot!(legend=:outerright)
end

# ╔═╡ 0a30810f-ed03-4237-8362-a502c4470320
md"""
## Putting everything together in `grow!`

Clicking around on those buttons was a lot of fun, but how about coding up a function to do this automatically? 

This last function `grow!` will perform splits until no changes are made.
"""

# ╔═╡ d1630c4c-c185-4f6c-9f25-45f63a2640ce
@doc grow!

# ╔═╡ f76bca8f-70d7-46be-a98e-1acc1a4958d8
md"""
Try messing with the number of iterations vs the `min_granularity`.
"""

# ╔═╡ f69efe68-2d16-4c86-9f83-6d64ad09a783
@bind max_iterations NumberField(0:100, default=5)

# ╔═╡ 52fb4f65-9974-4b95-9090-e0a50a487b22
call() do
	tree = deepcopy(tree)
	grow!(tree, dimensionality, simulation_function, Pace, spa, min_granularity; max_iterations)
	
	draw(tree, draw_bounds, color_dict=action_color_dict)
	scatter!([], m=(0, :white), msw=0, label="tree-size: $(length(PreOrderDFS(tree) |> collect))", legend=:outerright)
end

# ╔═╡ Cell order:
# ╟─137adf90-a162-11ed-358b-6fc69c09feba
# ╠═404bae97-6794-4fa6-97bf-d09851900305
# ╠═06791d29-7dbd-4487-8448-cc84a1631025
# ╟─6f3ab58d-545b-4b60-8f2a-0cb5d4fbd59e
# ╟─5ac41bda-dffe-4fcb-962d-2222df7b33cf
# ╟─4b35159a-d14c-4449-8bfb-7a9703fa9b16
# ╟─ffb29885-827f-4dea-b127-0f6b5a2defa4
# ╠═b738614d-9040-430e-94a3-9051a07765c5
# ╠═deab42ea-ba6b-4bca-97f5-02217d532de7
# ╟─f3dd8d47-d582-4e76-ba7c-8975280eb273
# ╟─4a2cc218-1278-48a2-8e8e-2deabc664802
# ╟─a8b53549-5de6-43c8-983d-43e8ca1520da
# ╟─4fe2ab4a-6bc3-40a1-9aed-b702a0fcdf69
# ╟─f14a4efc-1063-4e0d-b968-6c5f46a8c384
# ╠═d043a35e-8092-4306-afbc-e076200e6240
# ╠═7fd00150-0b98-4825-8064-3c805e077206
# ╠═3cee4706-ea98-47b4-aec1-59b27c1cfd0e
# ╟─de7fe51c-0f75-49bb-bc6f-726a21bcd064
# ╠═07ed71cc-a931-4785-9707-86aad883df30
# ╟─ef8dcaa1-4e61-450e-af1e-7cd54e7507f3
# ╠═1cb52b21-8d14-4e2e-ad63-788a56d6bcd2
# ╟─9f9aed0a-66c3-4628-8e7f-cc59374383c9
# ╠═a136ec18-5e84-489b-a13a-ff4ffbb1870d
# ╠═0b6ba501-bc18-4239-b99e-6365b6f5deac
# ╠═b2bc01c9-f501-4c75-8fc4-56dad5cd5c38
# ╠═af5236ad-e88e-486d-ab43-e4d1a85a7333
# ╠═ee408360-8c64-4619-9810-6038738045dc
# ╠═e9c86cfa-e53f-4c1e-9102-14c821f4232a
# ╟─86e9b7f7-f1f5-4ba2-95d6-5e528b1c0ce6
# ╠═ccf04ab6-d3f9-4abf-ae66-0e5d9653adff
# ╟─2b618fae-ca7d-412b-8edb-93305ca25353
# ╟─d8b0d276-6bbb-4dca-9a66-00f421316c87
# ╠═43dbb196-adc8-4c9f-8c1a-333d563ebec6
# ╟─fe163130-24c3-4c7e-b7a0-4e162ac26b5d
# ╠═0dccf16d-c9ae-4d69-b6b2-3118502ef9c4
# ╠═e3c9c499-d55d-4e4b-a239-c3ccc721f0c3
# ╟─02baf662-4ace-47ad-bd76-72e259a4861a
# ╠═2b2421b7-34a5-4de0-b191-b0f9f4a914a3
# ╟─6da5b379-ee87-42d1-8f48-5c465d4c4078
# ╠═09a48bc2-9e8d-462c-abad-23d8ce60e058
# ╟─c98a1165-9c3d-40df-8dee-e6e11a4ed2b5
# ╠═d9fa8430-c474-4990-97b2-11ba77b85c7d
# ╟─e69c7e85-b184-45b4-a3c5-ce1dc88010a1
# ╟─843b96e7-3b4b-4389-b736-f16142133e2d
# ╠═b4efde7a-eaac-4070-b332-29c3f76c43a9
# ╟─b37b67cf-09e3-4c3a-865f-9a8a79d43c68
# ╠═41be8c5c-5cb9-4123-a902-9d673a5f29a9
# ╟─2a74f21d-0de7-4169-a767-ec0d4b0b1adb
# ╠═e50b8e26-80ca-4571-9e7a-105221523df4
# ╟─b4f6c703-b6ea-4ffa-998e-e6eba4e309b9
# ╟─17d3107b-6437-4518-b32b-fdd87ad9c3a2
# ╠═568bee1c-ae0b-4892-b7ea-496002cde79d
# ╟─35af8e23-cdc7-498c-8bc8-c17b3e339597
# ╠═48b66592-c82f-4626-8b63-475ef761ef96
# ╟─fdb7f7d2-6923-43ca-8364-5e4cb42ef8f0
# ╠═c388ec0a-b850-49ad-b74f-e0744c367942
# ╟─0a30810f-ed03-4237-8362-a502c4470320
# ╠═d1630c4c-c185-4f6c-9f25-45f63a2640ce
# ╟─f76bca8f-70d7-46be-a98e-1acc1a4958d8
# ╠═f69efe68-2d16-4c86-9f83-6d64ad09a783
# ╠═52fb4f65-9974-4b95-9090-e0a50a487b22
