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

# ╔═╡ 483b9a1d-9277-4039-8e8c-bf26ddcb78fa
begin
	using Pkg
	Pkg.activate(".")
	Pkg.develop("TreeShielding")
	
	using Plots
	using Unzip
	using PlutoUI
	using PlutoTest
	using PlutoLinks
	using AbstractTrees
	TableOfContents()
end

# ╔═╡ 58f00fcf-cd5c-46ca-a347-0e27f30db51a
@revise using TreeShielding

# ╔═╡ 44462c54-bff7-4f6a-9f61-842146f3b446
md"""
# Updating the Set of Safe Actions
"""

# ╔═╡ 9016cdce-bcf7-431d-919b-ff3391c951b6
md"""
## Preliminaries
"""

# ╔═╡ ce0ec3fb-4afc-4911-bff2-06c699f15f73
call(f) = f()

# ╔═╡ 80b79e69-c4cf-487e-aef5-9eeaab83b0a0
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

# ╔═╡ d32f6407-a3c6-47d1-95e5-0c80bef46363
dimensionality = 2

# ╔═╡ 6e017911-a33f-4aa7-82b2-4feba4150a28
md"""
### Plotting Convenience Functions
"""

# ╔═╡ 4dbdc137-8d15-4eac-8a47-aa54f008690e
scatter_supporting_points!(s::SupportingPoints) = 
	scatter!(unzip(s), 
		m=(:+, 5, colors.WET_ASPHALT), msw=4, 
		label="supporting points")

# ╔═╡ d4c05cf8-2c2e-4699-aa5c-3a18ba466b70
scatter_outcomes!(outcomes) = scatter!(outcomes, m=(:c, 3, colors.ASBESTOS), msw=0, label="outcomes")

# ╔═╡ 7464eb8a-0884-44df-89ed-dc68a11ce75c
md"""
### Example Simulation Function

Pretty simple stuff. Remember to come back and play with the values once you've read how it's used.
"""

# ╔═╡ 1ee465dd-a771-45a1-bf10-2b04b49f2fe1
@enum Action bar baz

# ╔═╡ bebdb738-3f37-44b1-808c-366ca17712ef
function draw_support_points!(tree::Tree, 
	dimensionality, 
	simulation_function, 
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
		Action, 
		supporting_points)
	
	unsafe_points = [p for (p, safe) in points_safe if !safe]
	scatter!(unsafe_points, m=(:x, 5, colors.ALIZARIN), msw=3, label="unsafe")
end

# ╔═╡ 1c03b208-1476-4d40-abff-044ce20d1ba0
foo(s, a::Action) = (a == bar ? 
	Tuple(s .+ [-0.9, 3]) : 
	Tuple(s .+ [-1.2, 2.5]))

# ╔═╡ a5b9da4a-4926-48dc-b1de-3371d3c5c830
any_action, no_action = actions_to_int(Action, instances(Action)), actions_to_int(Action, [])

# ╔═╡ 6eee73e9-8ad5-414d-a224-044c051316f3
action_color_dict=Dict(
	any_action => colorant"#ffffff", 
	1 => colorant"#a1eaaa", 
	2 => colorant"#a1eaff", 
	no_action => colorant"#ff9178"
)

# ╔═╡ f39969cb-640d-4008-bc72-17edabde0951
md"""
### Example-tree

This tree will be used in the future examples. It has a single fully bounded partition (in the sense that all the bounds are finite) and an unsafe partition (in the sense that no actions are allowed in it).
"""

# ╔═╡ ec08559e-ce18-4888-a50c-df97bc012705
initial_tree = Node(1, 3,
	Node(2, 10,
		Leaf(no_action),
		Leaf(any_action)),
	# A properly bounded partition
	Node(1, 4,
		Node(2, 5,
			Leaf(any_action),
			Node(2, 10,
				Leaf(any_action),
				Leaf(any_action))),
		Leaf(any_action)))

# ╔═╡ e8f125f8-9127-492c-95c8-ac5d31307e2a
# Bounds to draw the tree around
tree_draw_bounds = Bounds((0, 0), (5, 20))

# ╔═╡ 8737d5ad-5553-46cc-9975-eb908f487575
draw(initial_tree, tree_draw_bounds, color_dict=action_color_dict)

# ╔═╡ b3fce214-5f2f-498e-adfe-49e88093a15f
md"""
## Using `update!` Alone
"""

# ╔═╡ 3a8901ff-86a8-4c27-bfe0-436cc8c961f1
@doc update!

# ╔═╡ 7166d36b-3362-47e9-9ac1-71d18bfde851
@bind spa NumberField(1:10, default=3)

# ╔═╡ f87acab6-0e93-4c85-a040-8ace5e7c4286
md"""
Clearly, there are no safe actions for the only properly bounded partition.
"""

# ╔═╡ 17942d42-a1dd-4643-97a6-833c06c3a332
call() do
	
	draw(initial_tree, tree_draw_bounds, color_dict=action_color_dict)

	p = (3, 5)
	draw_support_points!(initial_tree, dimensionality, foo, spa, p, bar)
end

# ╔═╡ d1ec6edc-e46d-4a11-9383-b078a7e78bb2
begin
	updated_tree = deepcopy(initial_tree)
	update!(updated_tree, dimensionality, foo, Action, spa)
end

# ╔═╡ eed68ed1-a733-4b17-957e-f31db727c35e
draw(updated_tree, tree_draw_bounds, color_dict=action_color_dict)

# ╔═╡ 307938ff-0457-4378-8206-2e52549fe0eb
md"""
Now! Let's try calling both `grow!` **and** `update!`. Can you see where I'm going with this?
"""

# ╔═╡ 05cc0a27-0c06-4f35-a812-4a1dac270cff
call() do
	tree = deepcopy(initial_tree)
	grow!(tree, dimensionality, foo, Action, spa, 0.01) # TODO: Why doesn't it grow the same way as in the other notebook??
	update!(tree, dimensionality, foo, Action, spa)
	draw(tree, tree_draw_bounds, color_dict=action_color_dict)
end

# ╔═╡ 1036c6d5-dd1d-45c4-a28b-e8218190efca
md"""
# Making a Proper Grid

To test it further, I need to initialize a parittioning tree in a way that the state space is bounded and nicely segmented.

I use `tree_from_bounds` and `gridify!` for this.
"""

# ╔═╡ e1b17edb-bdb5-4716-a3b2-6f165f2d3d7c
@doc tree_from_bounds

# ╔═╡ 44ffb190-664d-4e5d-ab87-053c7830bc32
@doc tree_from_bounds

# ╔═╡ 84eacf71-81c3-4006-aba8-ccc2f9f76170
bounded_tree = tree_from_bounds(tree_draw_bounds)

# ╔═╡ 969d20b5-da5c-4e8e-84c4-de769be0a12c
md"""
**Hack:** here I'm using `tree_draw_bounds` as the bounds of my tree as well. And I declare `tree_draw_bounds′` to use for showing the partitions outside these bounds.
"""

# ╔═╡ 6ae8af2c-fa0a-429d-ac7f-2d8d4d728921
tree_draw_bounds′ = Bounds(
	tree_draw_bounds.lower .- [1, 5], 
	tree_draw_bounds.upper .+ [1, 5])

# ╔═╡ 4f72c557-3c56-4977-b10c-e65c62ad89cb
draw(bounded_tree, tree_draw_bounds′)

# ╔═╡ bd048d87-152b-4b0f-8733-7473b8f957d0
md"""
And then for the actual `tree`, additional splits are made to align with the safety property.
"""

# ╔═╡ 8a6fecc7-06a6-4820-b8df-edec43d0e194
begin
	tree = deepcopy(bounded_tree)
	split!(get_leaf(tree, (-1, 10)), 2, 10)
	split!(get_leaf(tree, (0, 10)), 2, 10)
	split!(get_leaf(tree, (1, 0)), 1, 1)
end

# ╔═╡ 01c26f63-9ac7-4469-900b-269e5038c540
draw(tree, tree_draw_bounds′)

# ╔═╡ 5be56769-8713-4be3-a58f-d1054ce29e74
@doc gridify!

# ╔═╡ 8316d660-507c-4c61-abc0-b4cfd5c822cb
@bind number_of_splits NumberField(0:5, default=0)

# ╔═╡ 9511605d-f59e-471e-92f3-cb6a44a9e12e
grid = gridify!(deepcopy(tree), dimensionality, number_of_splits)

# ╔═╡ a1b54625-d099-4800-852b-88527e9e11bd
draw(grid, tree_draw_bounds′, color_dict=action_color_dict)

# ╔═╡ 5cf2bb64-223c-4b38-9690-30a69efb5797
unique([leaf.value for leaf in Leaves(grid)])

# ╔═╡ 01eebf08-61cf-4471-aec6-8879ec053292
md"""
## Function to initialize the grid with safe values
"""

# ╔═╡ ae5a0813-6bd9-43d5-85c7-3af3ff2f3bf6
safe(b::Bounds) = b.lower[1] >= 1 || b.lower[2] >= 10

# ╔═╡ 2fabab2f-3022-45bc-bfb3-11294f12c651


# ╔═╡ 0faf0f89-d49b-4de6-b909-edcaee6290b8
draw(set_safety!(deepcopy(grid), dimensionality, safe, any_action, no_action), tree_draw_bounds′, color_dict=action_color_dict)

# ╔═╡ 65d106f5-5638-426d-bd3a-0322c45b4ab2
md"""
# Grow, Then Update --  Try it Out!

clicky clicky buttons
"""

# ╔═╡ b3ec8858-371d-4d30-8916-0ddddc460069
@bind reset_button Button("Reset")

# ╔═╡ 7597a12d-168f-48ab-8470-771a304b22b0
begin
	reactive_grid = deepcopy(grid)
	set_safety!(reactive_grid, dimensionality, safe, any_action, no_action)
	debounce1, debounce2 = Ref(1), Ref(1)
	reset_button
end

# ╔═╡ c099af8b-b3a0-4c69-93cf-ed4a03d5aac3
@bind grow_button Button("Grow")

# ╔═╡ c97a05c6-8c19-4d89-bece-118e97bc4d56
grow_button,
if debounce1[] == 1
	debounce1[] += 1
	reactivity1 = "ready"
else
	grow!(reactive_grid, dimensionality, foo, Action, spa, 0.1, max_iterations=30)
	reactivity1 = "grown"
end

# ╔═╡ 196964ec-7381-4068-83fd-8592d0f12ca6
@bind update_button Button("Update")

# ╔═╡ 3e9cbb29-096a-4466-86cb-a70df0b3bff1
update_button,
if debounce2[] == 1
	debounce2[] += 1
	reactivity2 = "ready"
else
	update!(reactive_grid, dimensionality, foo, Action, spa)
	reactivity2 = "updated"
end

# ╔═╡ 457d4517-7409-41c2-b3b5-50aa685f9f66
md"""
`show_supporting_points:`
$(@bind show_supporting_points CheckBox())

`a =` $(@bind a Select(instances(Action) |> collect))

Position: 
$(@bind partition_x 
	NumberField(tree_draw_bounds.lower[1]:0.1:tree_draw_bounds.upper[1]))
$(@bind partition_y 
	NumberField(tree_draw_bounds.lower[2]:1:tree_draw_bounds.upper[2]))
"""

# ╔═╡ de2ae3c9-39c6-40e7-9db8-3a9c4dbdcdd2
begin
	reactivity1, reactivity2
	p1 = draw(reactive_grid, tree_draw_bounds′, color_dict=action_color_dict)

	if show_supporting_points
		p = (partition_x, partition_y)
		draw_support_points!(reactive_grid, dimensionality, foo, spa, p, a)
		scatter!(p, m=(4, :rtriangle, :white), msw=1, label=nothing)
	end
	p1
end

# ╔═╡ Cell order:
# ╟─44462c54-bff7-4f6a-9f61-842146f3b446
# ╟─9016cdce-bcf7-431d-919b-ff3391c951b6
# ╠═483b9a1d-9277-4039-8e8c-bf26ddcb78fa
# ╠═6eee73e9-8ad5-414d-a224-044c051316f3
# ╠═58f00fcf-cd5c-46ca-a347-0e27f30db51a
# ╠═ce0ec3fb-4afc-4911-bff2-06c699f15f73
# ╟─80b79e69-c4cf-487e-aef5-9eeaab83b0a0
# ╠═d32f6407-a3c6-47d1-95e5-0c80bef46363
# ╟─6e017911-a33f-4aa7-82b2-4feba4150a28
# ╟─4dbdc137-8d15-4eac-8a47-aa54f008690e
# ╟─d4c05cf8-2c2e-4699-aa5c-3a18ba466b70
# ╟─bebdb738-3f37-44b1-808c-366ca17712ef
# ╟─7464eb8a-0884-44df-89ed-dc68a11ce75c
# ╠═1c03b208-1476-4d40-abff-044ce20d1ba0
# ╠═1ee465dd-a771-45a1-bf10-2b04b49f2fe1
# ╠═a5b9da4a-4926-48dc-b1de-3371d3c5c830
# ╟─f39969cb-640d-4008-bc72-17edabde0951
# ╠═ec08559e-ce18-4888-a50c-df97bc012705
# ╠═e8f125f8-9127-492c-95c8-ac5d31307e2a
# ╠═8737d5ad-5553-46cc-9975-eb908f487575
# ╟─b3fce214-5f2f-498e-adfe-49e88093a15f
# ╠═3a8901ff-86a8-4c27-bfe0-436cc8c961f1
# ╠═7166d36b-3362-47e9-9ac1-71d18bfde851
# ╟─f87acab6-0e93-4c85-a040-8ace5e7c4286
# ╟─17942d42-a1dd-4643-97a6-833c06c3a332
# ╠═d1ec6edc-e46d-4a11-9383-b078a7e78bb2
# ╠═eed68ed1-a733-4b17-957e-f31db727c35e
# ╟─307938ff-0457-4378-8206-2e52549fe0eb
# ╠═05cc0a27-0c06-4f35-a812-4a1dac270cff
# ╟─1036c6d5-dd1d-45c4-a28b-e8218190efca
# ╠═e1b17edb-bdb5-4716-a3b2-6f165f2d3d7c
# ╠═44ffb190-664d-4e5d-ab87-053c7830bc32
# ╠═84eacf71-81c3-4006-aba8-ccc2f9f76170
# ╟─969d20b5-da5c-4e8e-84c4-de769be0a12c
# ╠═6ae8af2c-fa0a-429d-ac7f-2d8d4d728921
# ╠═4f72c557-3c56-4977-b10c-e65c62ad89cb
# ╟─bd048d87-152b-4b0f-8733-7473b8f957d0
# ╠═8a6fecc7-06a6-4820-b8df-edec43d0e194
# ╠═01c26f63-9ac7-4469-900b-269e5038c540
# ╠═5be56769-8713-4be3-a58f-d1054ce29e74
# ╠═8316d660-507c-4c61-abc0-b4cfd5c822cb
# ╠═9511605d-f59e-471e-92f3-cb6a44a9e12e
# ╠═a1b54625-d099-4800-852b-88527e9e11bd
# ╠═5cf2bb64-223c-4b38-9690-30a69efb5797
# ╟─01eebf08-61cf-4471-aec6-8879ec053292
# ╠═ae5a0813-6bd9-43d5-85c7-3af3ff2f3bf6
# ╠═2fabab2f-3022-45bc-bfb3-11294f12c651
# ╟─0faf0f89-d49b-4de6-b909-edcaee6290b8
# ╟─65d106f5-5638-426d-bd3a-0322c45b4ab2
# ╟─b3ec8858-371d-4d30-8916-0ddddc460069
# ╟─7597a12d-168f-48ab-8470-771a304b22b0
# ╟─c099af8b-b3a0-4c69-93cf-ed4a03d5aac3
# ╟─c97a05c6-8c19-4d89-bece-118e97bc4d56
# ╟─196964ec-7381-4068-83fd-8592d0f12ca6
# ╠═3e9cbb29-096a-4466-86cb-a70df0b3bff1
# ╟─457d4517-7409-41c2-b3b5-50aa685f9f66
# ╠═de2ae3c9-39c6-40e7-9db8-3a9c4dbdcdd2
