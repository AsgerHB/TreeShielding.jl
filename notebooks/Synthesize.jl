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
	using Setfield
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

# ╔═╡ c011233c-476d-4dcc-862c-151e49f75faf
md"""
### The Random Factor

The actions are affected by a random factor $\pm \epsilon$ in each dimension. This is captured in the below bounds, which make up part of the model. This will be used as part of the reachability simulation.
"""

# ╔═╡ bb4516e9-1f18-4b5f-a29f-06fc4449de07
ϵ = rwmechanics.ϵ

# ╔═╡ 55ef89de-76c4-48c7-953b-44e2034409c6
random_variable_bounds = Bounds((-ϵ,  -ϵ), (ϵ, ϵ))

# ╔═╡ 7d07f8c2-3bde-4506-b7d3-f2b4a6b7aba9
md"""
### The Simulation Function

The function for taking a single step needs to be wrapped up, so that it has the signature `(point::AbstractVector, action, random_variables::AbstractVector) -> updated_point`. 
"""

# ╔═╡ f698931f-0f24-4f82-8a09-f521bb1b4d2d
simulation_function(point, random_variables, action) = RW.simulate(
	rwmechanics, 
	point[1], 
	point[2], 
	action,
	random_variables)

# ╔═╡ c235f874-a7dc-4090-9733-7a92263b6d32
md"""
The goal of the game is to reach `x >= x_max` without reaching `t >= t_max`. 

As an additional constraint, the player must not be too early. Arriving before `t == earliest` is also a safety violation.

This corresponds to the below safety property. It is defined both for a single `(x, t)` point, as well as for a set of points given by `Bounds`.
"""

# ╔═╡ 4f33f9a0-9a7a-426b-8022-43a87bb3d188
earliest = 0.3

# ╔═╡ 957a7a75-0ac0-4c2e-9359-f9ad915e88be
begin
	is_safe(point) = point[2] <= rwmechanics.t_max && 
					(point[1] <= rwmechanics.x_max || point[2] >= earliest)
	
	is_safe(bounds::Bounds) = is_safe((bounds.lower[1], bounds.upper[2])) &&
                              is_safe((bounds.upper[1], bounds.upper[2])) &&
                              is_safe((bounds.upper[1], bounds.lower[2])) &&
                              is_safe((bounds.lower[1], bounds.lower[2]))
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
	split!(get_leaf(initial_tree, x_min - 0.1, y_max), 2, y_max)
	split!(get_leaf(initial_tree, x_max + 0.1, y_max), 2, y_max)
	split!(get_leaf(initial_tree, x_max + 0.1, y_max - 0.1), 2, earliest)
	split!(get_leaf(initial_tree, x_max - 0.1, y_max - 0.1), 2, (x_max - x_min)/2)
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

# ╔═╡ 503b61c8-e437-42ab-a7d0-de4d47030d50
md"""
### Parameters -- Try it Out!
!!! info "Tip"
	This cell controls multiple figures. Move it around to gain a better view.

Try setting a different number of samples per axis: 

`samples_per_axis =` $(@bind samples_per_axis NumberField(3:30, default=5))

`min_granularity =` $(@bind min_granularity NumberField(0:1E-15:1, default=1E-5))

`margin =` $(@bind margin NumberField(0:0.001:1, default=0.00))

`splitting_tolerance =` $(@bind splitting_tolerance NumberField(0:1E-10:1, default=1E-5))
"""

# ╔═╡ a52e9520-f4df-4e88-bb39-e516f37335ea
m = ShieldingModel(simulation_function, Pace, dimensionality, samples_per_axis, random_variable_bounds; min_granularity, margin, splitting_tolerance)

# ╔═╡ e3ba9c22-6e2c-4d90-9823-93f871c036b4
get_bounds(get_leaf(initial_tree, x_max + 1, y_max/2), m.dimensionality)

# ╔═╡ 1e96d57c-3dfe-4bd3-89b8-09d2157b6472
call() do
	bounds = get_bounds(get_leaf(initial_tree, x_max/2, y_max/2), m.dimensionality)
	@test is_safe(bounds)
	@test is_safe((bounds.lower[1], bounds.upper[2]))
	@test is_safe((bounds.upper[1], bounds.upper[2]))
	@test is_safe((bounds.upper[1], bounds.lower[2]))
	@test is_safe((bounds.lower[1], bounds.lower[2]))
end

# ╔═╡ e21002c4-f772-4c55-9014-6551b41d7ef4
@bind reset_button Button("Reset")

# ╔═╡ 5cfd2617-c1d8-4228-b7ca-cde9c3d68a4c
begin
	reactive_tree = deepcopy(initial_tree)
	set_safety!(reactive_tree, dimensionality, is_safe, any_action, no_action)
	debounce1, debounce2, debounce3, debounce4 = Ref(1), Ref(1), Ref(1), Ref(1)
	reset_button
end

# ╔═╡ c8248f9e-6fc2-49c4-9e69-b8387628f0fd
@bind grow_button Button("Grow")

# ╔═╡ 0583d3aa-719c-42dd-817a-6651edc90297
grow_button,
if debounce1[] == 1
	debounce1[] += 1
	reactivity1 = "ready"
else
	
	grown = grow!(reactive_tree, m)

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
	updates = update!(reactive_tree, m)
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

# ╔═╡ 897c4e0a-2544-4e7a-b270-8212189f84c0
leaf = get_leaf(reactive_tree, partition_x, partition_y)

# ╔═╡ f29db2ed-6a47-451a-b7c9-9ddf8fb48fce
axis, threshold = get_split(reactive_tree, leaf, m)

# ╔═╡ 455c7e81-2875-48fe-95c2-2dd92ed3f013
bounds = get_bounds(leaf, m.dimensionality)

# ╔═╡ 8306fbf0-c537-4f92-9e18-c2b006d7499e
begin
	reactivity1, reactivity2, reactivity3
	p1 = draw(reactive_tree, draw_bounds, color_dict=action_color_dict)
	plot!(legend=:outerright)

	if show_supporting_points
		p = (partition_x, partition_y)
		scatter_allowed_actions!(reactive_tree, bounds, m)
		scatter!(p, m=(4, :rtriangle, :white), msw=1, label=nothing, )
	end
	plot!(aspectratio=:equal)
end

# ╔═╡ e76c943b-acbd-4e97-92b2-f035c574a66a
bounds_gt = call() do
	result = Bounds(bounds.lower |> copy, bounds.upper |> copy)
	result.lower[axis] = threshold
	result
end

# ╔═╡ 887add25-5e17-4688-9b87-239d1276f140
bounds_lt = call() do
	result = Bounds(bounds.lower |> copy, bounds.upper |> copy)
	result.upper[axis] = threshold
	result
end

# ╔═╡ 5ff44f02-8c19-404d-baf6-421566a5f322
TreeShielding.get_allowed_actions(reactive_tree, bounds_lt, m)

# ╔═╡ 271cf6fd-1c9e-4d8e-8f8e-c0b4b9fde9dd
TreeShielding.get_allowed_actions(reactive_tree, bounds_gt, m)

# ╔═╡ b167ada8-dc47-491c-b8f1-6b8dae176307
md"""
# Making the Strategy More Permissive

Alright, so that ends up with just a bunch of partitions where you are only allowed to go fast. This is a safe strategy to be sure, but not very permissive. The last step is to refine the safe partitions.

This is done by performing another `grow!` step, where we assume we can only go slow, followed by a normal update.
"""

# ╔═╡ 8c9d74e1-7ccb-4623-9169-69501e8af721
@bind make_permissive_button Button("Make More Permissive")

# ╔═╡ 955ef68a-5a87-43d2-96bb-5b31f2d8e92a
call() do
	if debounce4[] == 1
		debounce4[] += 1
		return
	end
	make_permissive_button
	
	tree = deepcopy(reactive_tree)
	grown = grow!(tree, (@set m.action_space = [slow]))
	
	@info "Grown to $grown leaves"

	updates = update!(tree, m)
	@info "Updated $updates leaves"
	
	pruned_to = prune!(reactive_tree)
	@info "Pruned to $pruned_to leaves"

	draw(tree, draw_bounds, color_dict=action_color_dict, aspectratio=:equal)
end

# ╔═╡ 8af94312-e7f8-4b44-8190-ad0d2b5ce6d7
md"""
# The Full Loop

Automation is a wonderful thing.
"""

# ╔═╡ 039a6f5c-2934-4345-a381-56f8c3c33483
@doc synthesize!

# ╔═╡ 6823a7d1-f404-46b1-9490-862aeba553a7
m; @bind synthesize_button CounterButton("Synthesize!")

# ╔═╡ 0e68f636-cf63-4df8-b9ca-c597701334a9
if synthesize_button > -1 # Set to 0 to prevent refresh on every update
	
	finished_tree = deepcopy(tree)
	
	synthesize!(finished_tree, m)

	draw(finished_tree, draw_bounds, 
		color_dict=action_color_dict, 
		aspectratio=:equal,
		size=(400,400),
		xlabel="x",
		ylabel="t")
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
# ╟─7ecd8370-4546-45e1-bfcc-9fd6bbb22663
# ╠═80c812df-9b1c-4fd8-9100-b58fdfc24ff9
# ╠═7cd5e7bb-36d1-4aea-8384-969d98eaec1a
# ╠═fb29bd97-0a65-4142-83d0-fcfe60360080
# ╟─c011233c-476d-4dcc-862c-151e49f75faf
# ╠═bb4516e9-1f18-4b5f-a29f-06fc4449de07
# ╠═55ef89de-76c4-48c7-953b-44e2034409c6
# ╟─7d07f8c2-3bde-4506-b7d3-f2b4a6b7aba9
# ╟─f698931f-0f24-4f82-8a09-f521bb1b4d2d
# ╟─c235f874-a7dc-4090-9733-7a92263b6d32
# ╠═4f33f9a0-9a7a-426b-8022-43a87bb3d188
# ╠═957a7a75-0ac0-4c2e-9359-f9ad915e88be
# ╟─98cd05d4-07ee-4574-a157-8e3270091c15
# ╠═36ffecc0-b0f3-47ee-91aa-83c31a117405
# ╠═3e46f4e4-7711-4e7f-915c-17db6ab18a42
# ╠═35da0d89-1799-43c9-ba07-f48e7803e395
# ╠═e3ba9c22-6e2c-4d90-9823-93f871c036b4
# ╠═1e96d57c-3dfe-4bd3-89b8-09d2157b6472
# ╠═7c4dba76-5ce9-4db7-b5d5-421c5ef981d3
# ╠═777f87fd-f497-49f8-9deb-e708c990cdd1
# ╠═3b86ac41-4d87-4498-a1ca-c8c327ceb347
# ╟─3bf43a31-1739-4b94-944c-0226cc3851cb
# ╟─503b61c8-e437-42ab-a7d0-de4d47030d50
# ╠═a52e9520-f4df-4e88-bb39-e516f37335ea
# ╟─e21002c4-f772-4c55-9014-6551b41d7ef4
# ╟─5cfd2617-c1d8-4228-b7ca-cde9c3d68a4c
# ╟─c8248f9e-6fc2-49c4-9e69-b8387628f0fd
# ╟─0583d3aa-719c-42dd-817a-6651edc90297
# ╟─b5ee1e74-bd9a-47ab-8a3d-99d7b495766d
# ╟─dd16f45d-b348-46bc-b874-babcca2c52ba
# ╟─c8424961-5363-41bc-beb2-a0f54a289b5a
# ╟─c39a5cbf-37b2-4712-a935-ac0ed4a41988
# ╟─0fb4f059-135c-4713-be81-94e3acecc2ed
# ╟─8306fbf0-c537-4f92-9e18-c2b006d7499e
# ╠═897c4e0a-2544-4e7a-b270-8212189f84c0
# ╠═f29db2ed-6a47-451a-b7c9-9ddf8fb48fce
# ╠═455c7e81-2875-48fe-95c2-2dd92ed3f013
# ╠═e76c943b-acbd-4e97-92b2-f035c574a66a
# ╠═887add25-5e17-4688-9b87-239d1276f140
# ╠═5ff44f02-8c19-404d-baf6-421566a5f322
# ╠═271cf6fd-1c9e-4d8e-8f8e-c0b4b9fde9dd
# ╟─b167ada8-dc47-491c-b8f1-6b8dae176307
# ╟─8c9d74e1-7ccb-4623-9169-69501e8af721
# ╠═955ef68a-5a87-43d2-96bb-5b31f2d8e92a
# ╟─8af94312-e7f8-4b44-8190-ad0d2b5ce6d7
# ╠═039a6f5c-2934-4345-a381-56f8c3c33483
# ╟─6823a7d1-f404-46b1-9490-862aeba553a7
# ╟─0e68f636-cf63-4df8-b9ca-c597701334a9
