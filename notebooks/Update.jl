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

# ╔═╡ 7464eb8a-0884-44df-89ed-dc68a11ce75c
md"""
### Example Simulation Function

Pretty simple stuff. Remember to come back and play with the values once you've read how it's used.
"""

# ╔═╡ 1ee465dd-a771-45a1-bf10-2b04b49f2fe1
@enum Action bar baz

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
	# A nicely bounded partition
	Node(1, 4,
		Node(2, 5,
			Leaf(any_action),
			Node(2, 10,
				Leaf(any_action),
				Leaf(any_action))),
		Leaf(any_action)))

# ╔═╡ b3fce214-5f2f-498e-adfe-49e88093a15f
md"""
## Where the magic happens
"""

# ╔═╡ a25aaf3d-c59d-4764-b097-15f64289965f
function get_new_value(tree::Tree, 
						leaf::Leaf, 
						dimensionality,
						simulation_function,
						action_space,
						samples_per_axis)
	
	
end

# ╔═╡ 7166d36b-3362-47e9-9ac1-71d18bfde851
@bind spa NumberField(1:10, default=3)

# ╔═╡ 4dbdc137-8d15-4eac-8a47-aa54f008690e
scatter_supporting_points!(s::SupportingPoints) = 
	scatter!(unzip(s), 
		m=(:+, 5, colors.WET_ASPHALT), msw=4, 
		label="supporting points")

# ╔═╡ d4c05cf8-2c2e-4699-aa5c-3a18ba466b70
scatter_outcomes!(outcomes) = scatter!(outcomes, m=(:c, 3, colors.ASBESTOS), msw=0, label="outcomes")

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

	points_safe = compute_safety(initial_tree, 
		simulation_function, 
		Action, 
		supporting_points)
	
	unsafe_points = [p for (p, safe) in points_safe if !safe]
	scatter!(unsafe_points, m=(:x, 5, colors.ALIZARIN), msw=3, label="unsafe")
end

# ╔═╡ 1036c6d5-dd1d-45c4-a28b-e8218190efca
md"""
# Making a Proper Grid

Okay, I need to initialize a parittioning tree in a way that the state space is bounded and nicely segmented.
"""

# ╔═╡ e8f125f8-9127-492c-95c8-ac5d31307e2a
tree_draw_bounds = Bounds((0, 0), (5, 20))

# ╔═╡ 8737d5ad-5553-46cc-9975-eb908f487575
draw(initial_tree, tree_draw_bounds, color_dict=action_color_dict)

# ╔═╡ 84eacf71-81c3-4006-aba8-ccc2f9f76170
tree = begin
	l, u = tree_draw_bounds.lower, tree_draw_bounds.upper
	out_of_bounds = -1
	inside_bounds = 1

	tree = Node(1, l[1], 
		Leaf(out_of_bounds),
		Node(2, l[2],
			Leaf(out_of_bounds),
			Node(1, u[1],
				Node(2, u[2],
					Leaf(inside_bounds),
					Leaf(out_of_bounds),
				),
				Leaf(out_of_bounds),
			),
		), 
	)
	split!(get_leaf(tree, (-1, 10)), 2, 10)
	tree
end

# ╔═╡ 4f72c557-3c56-4977-b10c-e65c62ad89cb
begin
	tree_draw_bounds′ = Bounds(
		tree_draw_bounds.lower .- [1, 5], 
		tree_draw_bounds.upper .+ [1, 5])
	
	draw(tree, tree_draw_bounds′)
end

# ╔═╡ d50ec04b-e609-443c-b3b2-83694311ebe2
function even_split!(leaf::Leaf, dimensionality, axis)
	bounds = get_bounds(leaf, dimensionality)
	middle = (bounds.upper[axis] - bounds.lower[axis])/2 + bounds.lower[axis]
	split!(leaf, axis, middle)
end

# ╔═╡ 8316d660-507c-4c61-abc0-b4cfd5c822cb
@bind number_of_splits NumberField(1:6)

# ╔═╡ 9511605d-f59e-471e-92f3-cb6a44a9e12e
grid = call() do
	tree = deepcopy(tree)

	for _ in 1:number_of_splits
		for axis in 1:dimensionality
			for leaf in Leaves(tree)
				if !bounded(get_bounds(leaf, dimensionality))
					continue
				end
				even_split!(leaf, dimensionality, axis)
			end
		end
	end
	tree
end

# ╔═╡ a1b54625-d099-4800-852b-88527e9e11bd
draw(grid, tree_draw_bounds′, color_dict=action_color_dict)

# ╔═╡ 5cf2bb64-223c-4b38-9690-30a69efb5797
unique([leaf.value for leaf in Leaves(grid)])

# ╔═╡ ae5a0813-6bd9-43d5-85c7-3af3ff2f3bf6
safe(b::Bounds) = b.lower[1] > 1 || b.lower[2] > 5

# ╔═╡ 2fabab2f-3022-45bc-bfb3-11294f12c651
function set_safety!(tree, dimensionality, safe_function, safe_value, unsafe_value)
	for leaf in Leaves(tree)
		if safe_function(get_bounds(leaf, dimensionality))
			leaf.value = safe_value
		else
			leaf.value = unsafe_value
		end
	end
	tree
end

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

# ╔═╡ 42e58f2a-4694-48ed-b4fe-cef23eca7c8b
function update_actions!(tree::Tree, 
						dimensionality,
						simulation_function, 
						action_space, 
						samples_per_axis)

	updates = []
	no_actions = actions_to_int(action_space, [])
	for leaf in Leaves(tree)
		if leaf.value == no_actions
			continue # bad leaves stay bad
		end

		if !bounded(get_bounds(leaf, dimensionality))
			continue # I don't actually know what to do here.
		end
		
		allowed = Set(instances(action_space))
		for p in SupportingPoints(samples_per_axis, get_bounds(leaf, dimensionality))
			for a in instances(action_space)
				p′ = simulation_function(p, a)
				if get_value(tree, p′) == no_actions
					delete!(allowed, a)
				end
			end
		end
		new_value = actions_to_int(action_space, allowed)
		if leaf.value != new_value
			push!(updates, (leaf, new_value))
		end
	end

	for (leaf, new_value) in updates
		leaf.value = new_value
	end
end

# ╔═╡ 17942d42-a1dd-4643-97a6-833c06c3a332
call() do
	tree = deepcopy(initial_tree)
	update_actions!(tree, dimensionality, foo, Action, spa)
	draw(tree, tree_draw_bounds, color_dict=action_color_dict)

	p = (3, 5)
	draw_support_points!(tree, dimensionality, foo, spa, p, bar)
end

# ╔═╡ 05cc0a27-0c06-4f35-a812-4a1dac270cff
call() do
	tree = deepcopy(initial_tree)
	grow!(tree, dimensionality, foo, Action, spa, 0.01) # TODO: Why doesn't it grow the same way as in the other notebook??
	update_actions!(tree, dimensionality, foo, Action, spa)
	draw(tree, tree_draw_bounds, color_dict=action_color_dict)
end

# ╔═╡ 3e9cbb29-096a-4466-86cb-a70df0b3bff1
update_button,
if debounce2[] == 1
	debounce2[] += 1
	reactivity2 = "ready"
else
	update_actions!(reactive_grid, dimensionality, foo, Action, spa)
	reactivity2 = "updated"
end

# ╔═╡ de2ae3c9-39c6-40e7-9db8-3a9c4dbdcdd2
begin
	reactivity1, reactivity2
	draw(reactive_grid, tree_draw_bounds′, color_dict=action_color_dict)

	p = (1, 9)
	action = bar
	draw_support_points!(reactive_grid, dimensionality, foo, spa, p, action)
end

# ╔═╡ Cell order:
# ╟─44462c54-bff7-4f6a-9f61-842146f3b446
# ╠═483b9a1d-9277-4039-8e8c-bf26ddcb78fa
# ╠═6eee73e9-8ad5-414d-a224-044c051316f3
# ╠═58f00fcf-cd5c-46ca-a347-0e27f30db51a
# ╠═ce0ec3fb-4afc-4911-bff2-06c699f15f73
# ╟─80b79e69-c4cf-487e-aef5-9eeaab83b0a0
# ╠═d32f6407-a3c6-47d1-95e5-0c80bef46363
# ╟─7464eb8a-0884-44df-89ed-dc68a11ce75c
# ╠═1c03b208-1476-4d40-abff-044ce20d1ba0
# ╠═1ee465dd-a771-45a1-bf10-2b04b49f2fe1
# ╠═a5b9da4a-4926-48dc-b1de-3371d3c5c830
# ╟─f39969cb-640d-4008-bc72-17edabde0951
# ╠═ec08559e-ce18-4888-a50c-df97bc012705
# ╠═8737d5ad-5553-46cc-9975-eb908f487575
# ╟─b3fce214-5f2f-498e-adfe-49e88093a15f
# ╠═a25aaf3d-c59d-4764-b097-15f64289965f
# ╠═7166d36b-3362-47e9-9ac1-71d18bfde851
# ╠═4dbdc137-8d15-4eac-8a47-aa54f008690e
# ╠═d4c05cf8-2c2e-4699-aa5c-3a18ba466b70
# ╠═17942d42-a1dd-4643-97a6-833c06c3a332
# ╠═bebdb738-3f37-44b1-808c-366ca17712ef
# ╠═05cc0a27-0c06-4f35-a812-4a1dac270cff
# ╟─1036c6d5-dd1d-45c4-a28b-e8218190efca
# ╠═84eacf71-81c3-4006-aba8-ccc2f9f76170
# ╠═4f72c557-3c56-4977-b10c-e65c62ad89cb
# ╠═e8f125f8-9127-492c-95c8-ac5d31307e2a
# ╠═d50ec04b-e609-443c-b3b2-83694311ebe2
# ╠═8316d660-507c-4c61-abc0-b4cfd5c822cb
# ╠═9511605d-f59e-471e-92f3-cb6a44a9e12e
# ╠═a1b54625-d099-4800-852b-88527e9e11bd
# ╠═5cf2bb64-223c-4b38-9690-30a69efb5797
# ╠═ae5a0813-6bd9-43d5-85c7-3af3ff2f3bf6
# ╠═2fabab2f-3022-45bc-bfb3-11294f12c651
# ╟─b3ec8858-371d-4d30-8916-0ddddc460069
# ╟─7597a12d-168f-48ab-8470-771a304b22b0
# ╟─c099af8b-b3a0-4c69-93cf-ed4a03d5aac3
# ╟─c97a05c6-8c19-4d89-bece-118e97bc4d56
# ╟─196964ec-7381-4068-83fd-8592d0f12ca6
# ╟─3e9cbb29-096a-4466-86cb-a70df0b3bff1
# ╠═42e58f2a-4694-48ed-b4fe-cef23eca7c8b
# ╠═de2ae3c9-39c6-40e7-9db8-3a9c4dbdcdd2
