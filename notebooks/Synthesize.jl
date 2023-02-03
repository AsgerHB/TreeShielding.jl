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

# ╔═╡ e6dac829-d832-4bf7-be2a-a0f3f3d5cdeb
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

# ╔═╡ 40e5b7be-7438-48cc-b275-a73d7e42c5a2
begin
	@revise using TreeShielding
	using TreeShielding.RW
end

# ╔═╡ 49cebaac-b284-487d-9569-018c7410bec9
md"""
# Synthesize

Putting everything together. Check out the notebooks Grow, Update and Prune for detailed visualisations of how each step works.
"""

# ╔═╡ 6543e28a-28c3-48ac-b596-4d10144c7999
call(f) = f()

# ╔═╡ 578da1ea-3e25-4baf-a10d-9c2f8d5c842f
dimensionality = 2

# ╔═╡ 9ce0412c-5023-4ce6-a6a7-5710cff08977
md"""
### Colors
"""

# ╔═╡ aac97ac0-dde3-4b4f-b32f-0feb87c91497
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

# ╔═╡ 3a2f71b6-d01b-469f-a5c8-afbc9e0f5a2c
md"""
### Plotting Convenience Functions
"""

# ╔═╡ ec1099e2-4d49-440b-b70f-03cf92ce0b80
scatter_supporting_points!(s::SupportingPoints) = 
	scatter!(unzip(s), 
		m=(:+, 5, colors.WET_ASPHALT), msw=4, 
		label="supporting points")

# ╔═╡ 775c46f2-c207-4de0-ae6e-f108f6d162de
scatter_outcomes!(outcomes) = scatter!(outcomes, m=(:c, 3, colors.ASBESTOS), msw=0, label="outcomes")

# ╔═╡ a5b84dc9-deab-4809-8937-885916e2556c
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

# ╔═╡ 7ecd8370-4546-45e1-bfcc-9fd6bbb22663
md"""
## Example Function and safety constraint

This notebook uses the Random Walk example, which is included in the RW module.
"""

# ╔═╡ 80c812df-9b1c-4fd8-9100-b58fdfc24ff9
any_action, no_action = 
	actions_to_int(instances(Pace)), actions_to_int([])

# ╔═╡ d49c1419-7380-4527-af3a-65aca35dfcf3
action_color_dict=Dict(
	any_action => colorant"#ffffff", 
	1 => colorant"#a1eaaa", 
	2 => colorant"#a1eaff", 
	no_action => colorant"#ff9178"
)

# ╔═╡ 7cd5e7bb-36d1-4aea-8384-969d98eaec1a
evaluate(rwmechanics, (_, _) -> RW.slow)

# ╔═╡ fb29bd97-0a65-4142-83d0-fcfe60360080
begin
	plot(aspectratio=:equal)
	xlims!(rwmechanics.x_min, rwmechanics.x_max + 0.1)
	ylims!(rwmechanics.t_min, rwmechanics.t_max + 0.1)
	draw_walk!(take_walk(rwmechanics, (_, _) -> rand([RW.slow, RW.fast]))...)
end

# ╔═╡ b7410cc3-d5b7-497b-88c8-1f525c646b3e
md"""
The function for taking a single step needs to be wrapped up, so that it only takes the arguments `point` and `action`.
"""

# ╔═╡ f698931f-0f24-4f82-8a09-f521bb1b4d2d
simulation_function(point, action) = RW.simulate(
	rwmechanics, 
	point[1], 
	point[2], 
	action,
	unlucky=true)

# ╔═╡ c235f874-a7dc-4090-9733-7a92263b6d32
md"""
The goal of the game is to reach `x >= x_max` without reaching `t >= t_max`. 

This corresponds to the below safety property. It is defined both for a single `(x, t)` point, as well as for a set of points given by `Bounds`.
"""

# ╔═╡ 957a7a75-0ac0-4c2e-9359-f9ad915e88be
begin
	is_safe(point) = point[2] <= rwmechanics.t_max
	is_safe(bounds::Bounds) = is_safe((bounds.lower[1], bounds.upper[2]))
end

# ╔═╡ 98cd05d4-07ee-4574-a157-8e3270091c15
md"""
## Building the Initial Tree

Building a tree with a properly bounded state space, and some divisions that align with the safety constraints.
"""

# ╔═╡ 36ffecc0-b0f3-47ee-91aa-83c31a117405
outer_bounds = Bounds(
	(rwmechanics.x_min, rwmechanics.t_min), 
	(rwmechanics.x_max, rwmechanics.t_max))

# ╔═╡ 3e46f4e4-7711-4e7f-915c-17db6ab18a42
draw_bounds = Bounds(
	outer_bounds.lower .- [0.1, 0.1],
	outer_bounds.upper .+ [0.1, 0.1]
)

# ╔═╡ 35da0d89-1799-43c9-ba07-f48e7803e395
begin
	initial_tree = tree_from_bounds(outer_bounds, any_action, any_action)
	
	x_min, y_min = rwmechanics.x_min, rwmechanics.t_min
	x_max, y_max = rwmechanics.x_max, rwmechanics.t_max
	split!(get_leaf(initial_tree, x_min - 1, y_max), 2, y_max)
	split!(get_leaf(initial_tree, x_max + 1, y_max), 2, y_max)
end

# ╔═╡ 7c4dba76-5ce9-4db7-b5d5-421c5ef981d3
draw(initial_tree, draw_bounds, color_dict=action_color_dict, aspectratio=:equal)

# ╔═╡ 777f87fd-f497-49f8-9deb-e708c990cdd1
tree = set_safety!(deepcopy(initial_tree), 
		dimensionality, 
		is_safe, 
		any_action, 
		no_action)

# ╔═╡ 3b86ac41-4d87-4498-a1ca-c8c327ceb347
draw(tree, draw_bounds, color_dict=action_color_dict, aspectratio=:equal)

# ╔═╡ 3bf43a31-1739-4b94-944c-0226cc3851cb
md"""
# Synthesis --  Try it Out!

Change the inputs and click the buttons to see how the parameters affect synthesis, one step at a time.
"""

# ╔═╡ e21002c4-f772-4c55-9014-6551b41d7ef4
@bind reset_button Button("Reset")

# ╔═╡ 5cfd2617-c1d8-4228-b7ca-cde9c3d68a4c
begin
	reactive_tree = deepcopy(initial_tree)
	set_safety!(reactive_tree, dimensionality, is_safe, any_action, no_action)
	debounce1, debounce2, debounce3 = Ref(1), Ref(1), Ref(1)
	reset_button
end

# ╔═╡ de03955c-7064-401f-b20b-14302273da8b
md"""
Try changing the number of samples per axis, to see how this affects the growth of the tree.

`spa =` $(@bind spa NumberField(1:20, default=5))

And likewise try to adjust the minimum granularity. Defined as the number of leading zeros to the one.

`min_granularity_decimals` $(@bind min_granularity_decimals NumberField(1:15, 3))

`max_grow_iterations` $(@bind max_grow_iterations NumberField(1:20, default=20))
"""

# ╔═╡ d020392b-ede6-4517-8e56-5ddcb1f33fea
min_granularity = 10.0^(-min_granularity_decimals)

# ╔═╡ c8248f9e-6fc2-49c4-9e69-b8387628f0fd
@bind grow_button Button("Grow")

# ╔═╡ 0583d3aa-719c-42dd-817a-6651edc90297
grow_button,
if debounce1[] == 1
	debounce1[] += 1
	reactivity1 = "ready"
else
	
	grown = grow!(reactive_tree, 
		dimensionality, 
		simulation_function, 
		Pace, 
		spa, 
		min_granularity, 
		max_iterations=max_grow_iterations)

	@info "Grown to $grown leaves"
	reactivity1 = "grown"
end

# ╔═╡ b5ee1e74-bd9a-47ab-8a3d-99d7b495766d
@bind update_button Button("Update")

# ╔═╡ dd16f45d-b348-46bc-b874-babcca2c52ba
update_button,
if debounce2[] == 1
	debounce2[] += 1
	reactivity2 = "ready"
else
	updates = update!(reactive_tree, dimensionality, simulation_function, Pace, spa)
	@info "Updated $updates leaves"
	reactivity2 = "updated"
end

# ╔═╡ c8424961-5363-41bc-beb2-a0f54a289b5a
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

# ╔═╡ c39a5cbf-37b2-4712-a935-ac0ed4a41988
@bind prune_button Button("Prune")

# ╔═╡ 0fb4f059-135c-4713-be81-94e3acecc2ed
prune_button,
if debounce3[] == 1
	debounce3[] += 1
	reactivity3 = "ready"
else
	pruned_to = prune!(reactive_tree)
	@info "Pruned to $pruned_to leaves"
	reactivity3 = "pruned"
end

# ╔═╡ 8306fbf0-c537-4f92-9e18-c2b006d7499e
begin
	reactivity1, reactivity2, reactivity3
	p1 = draw(reactive_tree, draw_bounds, color_dict=action_color_dict)
	plot!(legend=:outerright)

	if show_supporting_points
		p = (partition_x, partition_y)
		draw_support_points!(reactive_tree, dimensionality, simulation_function, Pace, spa, p, a)
		scatter!(p, m=(4, :rtriangle, :white), msw=1, label=nothing, )
	end
	plot!(aspectratio=:equal)
end

# ╔═╡ 8af94312-e7f8-4b44-8190-ad0d2b5ce6d7
md"""
# The Full Loop

Automation is a wonderful thing.
"""

# ╔═╡ 039a6f5c-2934-4345-a381-56f8c3c33483
@doc synthesize!

# ╔═╡ 0e68f636-cf63-4df8-b9ca-c597701334a9
call() do

	spa = 15
	min_granularity = 0.0001
	
	tree = deepcopy(tree)
	
	synthesize!(tree, 
		dimensionality, 
		simulation_function, 
		Pace, 
		spa, 
		min_granularity,
		verbose=true)

	draw(tree, draw_bounds, 
		color_dict=action_color_dict, 
		aspectratio=:equal)
end

# ╔═╡ Cell order:
# ╟─49cebaac-b284-487d-9569-018c7410bec9
# ╠═e6dac829-d832-4bf7-be2a-a0f3f3d5cdeb
# ╠═6543e28a-28c3-48ac-b596-4d10144c7999
# ╠═40e5b7be-7438-48cc-b275-a73d7e42c5a2
# ╠═578da1ea-3e25-4baf-a10d-9c2f8d5c842f
# ╟─9ce0412c-5023-4ce6-a6a7-5710cff08977
# ╟─aac97ac0-dde3-4b4f-b32f-0feb87c91497
# ╟─d49c1419-7380-4527-af3a-65aca35dfcf3
# ╟─3a2f71b6-d01b-469f-a5c8-afbc9e0f5a2c
# ╟─ec1099e2-4d49-440b-b70f-03cf92ce0b80
# ╟─775c46f2-c207-4de0-ae6e-f108f6d162de
# ╟─a5b84dc9-deab-4809-8937-885916e2556c
# ╟─7ecd8370-4546-45e1-bfcc-9fd6bbb22663
# ╠═80c812df-9b1c-4fd8-9100-b58fdfc24ff9
# ╠═7cd5e7bb-36d1-4aea-8384-969d98eaec1a
# ╠═fb29bd97-0a65-4142-83d0-fcfe60360080
# ╟─b7410cc3-d5b7-497b-88c8-1f525c646b3e
# ╠═f698931f-0f24-4f82-8a09-f521bb1b4d2d
# ╟─c235f874-a7dc-4090-9733-7a92263b6d32
# ╠═957a7a75-0ac0-4c2e-9359-f9ad915e88be
# ╟─98cd05d4-07ee-4574-a157-8e3270091c15
# ╠═36ffecc0-b0f3-47ee-91aa-83c31a117405
# ╠═3e46f4e4-7711-4e7f-915c-17db6ab18a42
# ╠═35da0d89-1799-43c9-ba07-f48e7803e395
# ╠═7c4dba76-5ce9-4db7-b5d5-421c5ef981d3
# ╠═777f87fd-f497-49f8-9deb-e708c990cdd1
# ╠═3b86ac41-4d87-4498-a1ca-c8c327ceb347
# ╟─3bf43a31-1739-4b94-944c-0226cc3851cb
# ╟─e21002c4-f772-4c55-9014-6551b41d7ef4
# ╟─5cfd2617-c1d8-4228-b7ca-cde9c3d68a4c
# ╟─de03955c-7064-401f-b20b-14302273da8b
# ╟─d020392b-ede6-4517-8e56-5ddcb1f33fea
# ╟─c8248f9e-6fc2-49c4-9e69-b8387628f0fd
# ╟─0583d3aa-719c-42dd-817a-6651edc90297
# ╟─b5ee1e74-bd9a-47ab-8a3d-99d7b495766d
# ╟─dd16f45d-b348-46bc-b874-babcca2c52ba
# ╟─c8424961-5363-41bc-beb2-a0f54a289b5a
# ╟─c39a5cbf-37b2-4712-a935-ac0ed4a41988
# ╟─0fb4f059-135c-4713-be81-94e3acecc2ed
# ╠═8306fbf0-c537-4f92-9e18-c2b006d7499e
# ╟─8af94312-e7f8-4b44-8190-ad0d2b5ce6d7
# ╠═039a6f5c-2934-4345-a381-56f8c3c33483
# ╠═0e68f636-cf63-4df8-b9ca-c597701334a9
