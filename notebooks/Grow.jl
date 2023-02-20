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
	using Setfield
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
begin
	function draw_support_points!(tree::Tree, 
		dimensionality, 
		simulation_function, 
		action_space,
		spa, 
		p, 
		action)
		
		bounds = get_bounds(get_leaf(tree, p), dimensionality)

		draw_support_points!(tree::Tree, 
			dimensionality, 
			simulation_function, 
			action_space,
			spa, 
			bounds, 
			action)
	end
	
	function draw_support_points!(tree::Tree, 
	dimensionality, 
	simulation_function, 
	action_space,
	spa, 
	bounds::Bounds, 
	action)

	if action_space isa Type
		action_space = instances(action_space)
	end
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
end

# ╔═╡ f14a4efc-1063-4e0d-b968-6c5f46a8c384
md"""
## Example Function and safety constraint

This notebook uses the Random Walk example, which is included in the RW module.
"""

# ╔═╡ d043a35e-8092-4306-afbc-e076200e6240
any_action, no_action = 
	actions_to_int(instances(Pace)), actions_to_int([])

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

The kwarg `unlucky=true` will tell the function to pick the worst-case outcome, i.e. the one where the ball preserves the least amount of power on impact. 

!!! info "TODO"
	Model random outcomes as an additional dimension, removing the need for assumptions about a "worst-case" outcome.
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

Note that the set of unsafe states is modified for this notebook, to make the initial split more interesting.
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
	split!(get_leaf(initial_tree, x_max + 1, y_max), 2, y_max)
end

# ╔═╡ ee408360-8c64-4619-9810-6038738045dc
begin
	tree = set_safety!(deepcopy(initial_tree), 
		dimensionality, 
		is_safe, 
		any_action, 
		no_action)

	# Modification to make the split more interesting
	replace_subtree!(get_leaf(tree, 1.1, 1.1), Leaf(any_action))
end

# ╔═╡ e9c86cfa-e53f-4c1e-9102-14c821f4232a
draw(tree, draw_bounds, color_dict=action_color_dict, aspectratio=:equal)

# ╔═╡ f2e8855b-95b8-4fcf-bd47-85ec0fdb2a04
md"""
## The `ShieldingModel`

Everything is rolled up into a convenient little ball that is easy to toss around between functions. This ball is called `ShieldingModel`
"""

# ╔═╡ 86e9b7f7-f1f5-4ba2-95d6-5e528b1c0ce6
md"""
## Where to Split

Get ready to read some cursed code.
"""

# ╔═╡ 0840b06f-246a-4d62-bf07-2ab9a1cc1e26
md"""
### `get_safety_bounds`

$(@doc get_safety_bounds)
"""

# ╔═╡ 2d999c21-cbdd-4ca6-9866-6f763c91feba
md"""
### `get_dividing_bounds`

$(@doc get_dividing_bounds)
"""

# ╔═╡ 15b5d339-705e-4408-9629-2002117b8da7
md"""
### `get_threshold`

$(@doc get_threshold)
"""

# ╔═╡ a8a02260-61d8-4698-9b61-351adaf68f78
bounds = get_bounds(get_leaf(tree, 0.5, 0.5), dimensionality)

# ╔═╡ 648fb8ab-b156-4c75-b0e0-16c8c7f151ec
md"""
### `get_split`

$(@doc get_split)
"""

# ╔═╡ 9e807328-488f-4e86-ae53-71f39b2631a7
md"""
### `grow!`

$(@doc grow!)
"""

# ╔═╡ 76f13f2a-82cb-4037-a097-394fb080bf84
md"""
# One Split at a Time -- Try it out!
"""

# ╔═╡ 66af047f-a34f-484a-8608-8eaaed45b37d
@bind reset_button Button("Reset")

# ╔═╡ 447dc1e2-809a-4f71-b7f4-949ae2a0c4b6
begin
	reset_button
	reactive_tree = deepcopy(tree)
end;

# ╔═╡ 1817421e-50b0-47b2-859d-e87aaf3064b0
begin
	reset_button
	@bind refill_queue_button CounterButton("Refill Queue")
end

# ╔═╡ 7fd058fa-20c2-4b7a-b32d-0a1f806b48ac
begin
	refill_queue_button
	reactive_queue = collect(Leaves(reactive_tree))
end;

# ╔═╡ 569efbf8-14da-47a3-b990-88cf223d4b82
["Leaf($(leaf.value))" for leaf in reactive_queue]

# ╔═╡ 1fd077e6-1f9e-45bf-8b04-17e1e58afe80
(@isdefined proposed_split2) ? proposed_split2 : nothing

# ╔═╡ 87e24687-5fc2-485a-ba01-41c10c10d395
md"""
### Parameters -- Try it Out!
!!! info "Tip"
	This cell controls multiple figures. Move it around to gain a better view.

Try setting a different number of samples per axis: 

`samples_per_axis =` $(@bind samples_per_axis NumberField(3:30, default=3))

And configure min granularity. The value is set as the number of leading zeros to the first digit.

`min_granularity_leading_zeros =` $(@bind min_granularity_leading_zeros NumberField(0:20, default=2))

`margin =` $(@bind margin NumberField(0:0.001:1, default=0.02))

`splitting_tolerance =` $(@bind splitting_tolerance NumberField(0:1E-10:1, default=1E-5))

And the recursion depth:

`max_recursion_depth =` $(@bind max_recursion_depth NumberField(0:9, default=3))
"""

# ╔═╡ 9fa8dd4a-3ffc-4c19-858e-e6188e73175e
min_granularity = 10.0^(-min_granularity_leading_zeros)

# ╔═╡ 3c613061-1cd9-4b72-b419-6387c25da513
m = ShieldingModel(simulation_function, Pace, dimensionality, samples_per_axis; min_granularity, max_recursion_depth, margin, splitting_tolerance)

# ╔═╡ 50495f8a-e38f-4fdd-8c75-ca84fd9360c5
bounds_safe, bounds_unsafe = 
	get_safety_bounds(tree, bounds, m)

# ╔═╡ 3e8defcb-c420-46a8-8abc-78ab228abef6
@bind axis NumberField(1:m.dimensionality)

# ╔═╡ 3e6a861b-cbb9-4972-adee-46996faf68f3
geq_safe, threshold = get_threshold(tree, bounds, 1, m)

# ╔═╡ bae11a44-67d8-4b6b-8d10-85b58e7fae63
call() do
	tree = deepcopy(tree)
	leaf = get_leaf(tree, 0.5, 0.5)
	
	split!(leaf, axis, threshold)
	
	draw(tree, draw_bounds, color_dict=action_color_dict, 
		aspectratio=:equal,
		legend=:outertop,
		size=(500,500))
	leaf_count = length(Leaves(tree) |> collect)
	plot!([], l=nothing, label="leaves: $leaf_count")
end

# ╔═╡ 53cf3fc9-788c-4700-8b07-fe9118432c84
proposed_split = get_split(tree, get_leaf(tree, 0.5, 0.5), m)

# ╔═╡ 46f3eefe-15c7-4bae-acdb-54e485e4b5b7
call() do
	tree = deepcopy(tree)
	
	# Here. #
	grow!(tree, m)
	
	draw(tree, draw_bounds, color_dict=action_color_dict, 
		aspectratio=:equal,
		legend=:outertop,
		size=(500,500))
	leaf_count = length(Leaves(tree) |> collect)
	plot!([], l=nothing, label="leaves: $leaf_count")
end

# ╔═╡ e7609f1e-3d94-4e53-9620-dd62995cfc50
call() do
	leaf = get_leaf(tree, 0.5, 0.5)
	bounds = get_bounds(leaf, dimensionality)
	p1 = draw(tree, draw_bounds, color_dict=action_color_dict,legend=:outerright)
	plot!(size=(800,600))
	draw_support_points!(tree, dimensionality, simulation_function, Pace, samples_per_axis, (0.5, 0.5), RW.fast)

	plot!(TreeShielding.rectangle(bounds_safe), 
		label="safe", 
		fill=nothing, 
		lw=4,
		lc=colors.NEPHRITIS)
	plot!(TreeShielding.rectangle(bounds_unsafe), 
		label="unsafe", 
		fill=nothing, 
		lw=6,
		lc=colors.ALIZARIN)
end

# ╔═╡ c8d182d8-537f-43d7-ab5f-1374219964e8
call() do
	axis = 1
	leaf = get_leaf(tree, 0.5, 0.5)
	bounds = get_bounds(leaf, dimensionality)
	p1 = draw(tree, draw_bounds, color_dict=action_color_dict,legend=:outerright)
	plot!(size=(800,600))
	draw_support_points!(tree, dimensionality, simulation_function, Pace, samples_per_axis, (0.5, 0.5), RW.fast)

	
	dividing_bounds = bounds
	for i in 0:max_recursion_depth
		
		safe_above, dividing_bounds = 
			get_dividing_bounds(tree, dividing_bounds, axis, m)
	
		plot!(TreeShielding.rectangle(dividing_bounds), lw=0, alpha=0.3, label="$i recursions")
	end
	p1
end

# ╔═╡ da493978-1444-4ec3-be36-4aa1c59170b5
offset = get_spacing_sizes(SupportingPoints(samples_per_axis, bounds), dimensionality)

# ╔═╡ c53e43e9-dc81-4b74-b6bd-41f13791f488
call() do
	leaf = get_leaf(tree, 0.5, 0.5)
	bounds = get_bounds(leaf, dimensionality)
	p1 = draw(tree, draw_bounds, color_dict=action_color_dict,legend=:outerright)
	plot!(size=(800,600))
	draw_support_points!(tree, dimensionality, simulation_function, Pace, samples_per_axis, (0.5, 0.5), RW.fast)

	if threshold === nothing 
		return p1
	end
	dividing_bounds = bounds
	for i in 0:max_recursion_depth
		safe_above, dividing_bounds = get_dividing_bounds(tree, dividing_bounds, axis, m)
	
		plot!(TreeShielding.rectangle(dividing_bounds), lw=0, alpha=0.3, label="$i recursions")
	end
	if axis == 1
		vline!([threshold], 
			line=(:dot, 5), 
			label="threshold", 
			color=colors.WET_ASPHALT)
	else
		hline!([threshold], 
			line=(:dot, 5), 
			label="threshold", 
			color=colors.WET_ASPHALT)
	end
end

# ╔═╡ e21201c8-b043-4214-b8bc-9e7cc2dced6f
begin
	reset_button
	@bind try_splitting_button CounterButton("Try Splitting")
end

# ╔═╡ 42d2f87e-ce8b-4928-9d00-b0aa70a18cb5
begin
	reset_button, try_splitting_button
	if length(reactive_queue) == 0
		[push!(reactive_queue, leaf) for leaf in collect(Leaves(reactive_tree))]
	end
	reactive_leaf = pop!(reactive_queue)
	if length(reactive_queue) == 0
		[push!(reactive_queue, leaf) for leaf in collect(Leaves(reactive_tree))]
	end
	"Next: Leaf($(reactive_queue[end].value))"
end

# ╔═╡ 0a14602c-aa5e-460f-9ab3-9edd18234b5a
get_safety_bounds(reactive_tree, get_bounds(reactive_leaf, m.dimensionality), m)

# ╔═╡ 8cc5f9f3-263c-459f-ae78-f2c0e8487e86
if try_splitting_button > 0 && reactive_leaf !== nothing
	call() do
		axis, threshold = get_split(reactive_tree, reactive_leaf, (@set m.verbose = true))
		if threshold != nothing
			split!(reactive_leaf, axis, threshold)
		end
		axis, threshold
	end
end;

# ╔═╡ 7f394991-4673-4f32-8c4f-09225822ae95
call() do
	reset_button, try_splitting_button
	
	draw(reactive_tree, draw_bounds, color_dict=action_color_dict, 
		aspectratio=:equal,
		legend=:outerright,
		size=(550, 500))

	if length(reactive_queue) > 0
		bounds = get_bounds(reactive_queue[end], dimensionality)
		plot!(TreeShielding.rectangle(bounds ∩ draw_bounds), 
			label="next in queue",
			linewidth=4,
			linecolor=colors.PETER_RIVER,
			color=colors.CONCRETE,
			fillalpha=0.3)

		draw_support_points!(tree::Tree, 
			dimensionality, 
			simulation_function, 
			m.action_space,
			m.samples_per_axis, 
			bounds, 
			RW.fast)
	end

	leaf_count = Leaves(reactive_tree) |> collect |> length
	plot!([], line=nothing, label="$leaf_count leaves")
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
# ╠═ee408360-8c64-4619-9810-6038738045dc
# ╠═e9c86cfa-e53f-4c1e-9102-14c821f4232a
# ╟─f2e8855b-95b8-4fcf-bd47-85ec0fdb2a04
# ╠═3c613061-1cd9-4b72-b419-6387c25da513
# ╟─86e9b7f7-f1f5-4ba2-95d6-5e528b1c0ce6
# ╠═9fa8dd4a-3ffc-4c19-858e-e6188e73175e
# ╟─0840b06f-246a-4d62-bf07-2ab9a1cc1e26
# ╠═50495f8a-e38f-4fdd-8c75-ca84fd9360c5
# ╟─e7609f1e-3d94-4e53-9620-dd62995cfc50
# ╟─2d999c21-cbdd-4ca6-9866-6f763c91feba
# ╟─c8d182d8-537f-43d7-ab5f-1374219964e8
# ╟─15b5d339-705e-4408-9629-2002117b8da7
# ╠═a8a02260-61d8-4698-9b61-351adaf68f78
# ╠═da493978-1444-4ec3-be36-4aa1c59170b5
# ╠═3e8defcb-c420-46a8-8abc-78ab228abef6
# ╠═3e6a861b-cbb9-4972-adee-46996faf68f3
# ╟─c53e43e9-dc81-4b74-b6bd-41f13791f488
# ╟─648fb8ab-b156-4c75-b0e0-16c8c7f151ec
# ╠═53cf3fc9-788c-4700-8b07-fe9118432c84
# ╠═bae11a44-67d8-4b6b-8d10-85b58e7fae63
# ╟─9e807328-488f-4e86-ae53-71f39b2631a7
# ╟─46f3eefe-15c7-4bae-acdb-54e485e4b5b7
# ╟─76f13f2a-82cb-4037-a097-394fb080bf84
# ╟─66af047f-a34f-484a-8608-8eaaed45b37d
# ╟─447dc1e2-809a-4f71-b7f4-949ae2a0c4b6
# ╟─1817421e-50b0-47b2-859d-e87aaf3064b0
# ╟─569efbf8-14da-47a3-b990-88cf223d4b82
# ╟─7fd058fa-20c2-4b7a-b32d-0a1f806b48ac
# ╟─42d2f87e-ce8b-4928-9d00-b0aa70a18cb5
# ╟─8cc5f9f3-263c-459f-ae78-f2c0e8487e86
# ╟─1fd077e6-1f9e-45bf-8b04-17e1e58afe80
# ╠═0a14602c-aa5e-460f-9ab3-9edd18234b5a
# ╟─87e24687-5fc2-485a-ba01-41c10c10d395
# ╟─e21201c8-b043-4214-b8bc-9e7cc2dced6f
# ╟─7f394991-4673-4f32-8c4f-09225822ae95
