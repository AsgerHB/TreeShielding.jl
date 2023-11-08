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

# ╔═╡ 41dcecdf-1584-439f-a30b-45f4f69f6c4c
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

# ╔═╡ e51630be-8ede-49ea-ae13-545ce360b7fd
@revise using TreeShielding

# ╔═╡ 101b3a4a-523c-474c-88f0-dbafaf2f2813
md"""
# Prune

Attempts to trim redundant nodes after the tree has been grown.
"""

# ╔═╡ 79718adb-1457-43cc-bec4-33caf7eee144
md"""
## Preliminaries
"""

# ╔═╡ 790eb504-5569-49d4-b39b-cd3daa96503f
call(f) = f()

# ╔═╡ bc46cf8e-6f5c-48ac-9788-40a8f5552219
dimensionality = 2

# ╔═╡ 8e13bd07-ec70-416e-a00a-ef519519188c
md"""
### Colors
"""

# ╔═╡ eddf42d5-0525-49e7-a058-87c6d240b732
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

# ╔═╡ 2165913f-036f-4709-919b-40009b8faa5f
md"""
### Plotting Convenience Functions
"""

# ╔═╡ 267f97aa-b429-4962-ab13-19cba39a6bbf
scatter_supporting_points!(s::SupportingPoints) = 
	scatter!(unzip(s), 
		m=(:+, 5, colors.WET_ASPHALT), msw=4, 
		label="supporting points")

# ╔═╡ 00a6e9c2-a9c6-41ed-ae2a-701e3baf7038
scatter_outcomes!(outcomes) = scatter!(outcomes, m=(:c, 3, colors.ASBESTOS), msw=0, label="outcomes")

# ╔═╡ 1f0c3fbd-27ef-44c3-b1da-6abb083daddb
md"""
## Example Function and safety constraint
"""

# ╔═╡ 581a14d5-6833-41db-adf7-17dd213ab8a7
@enum Action bar baz

# ╔═╡ 3b40135b-1a9a-4e53-8aec-60955f046414
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

# ╔═╡ 0d7aca9f-460a-437e-89f8-07727adce731
any_action, no_action = actions_to_int(instances(Action)), actions_to_int([])

# ╔═╡ 5cd0afd8-a518-4625-b91d-71ffa82ac3b0
action_color_dict=Dict(
	any_action => colorant"#FFFFFF", 
	actions_to_int([fast]) => colorant"#9C59D1", 
	actions_to_int([slow]) => colorant"#FCF434", 
	no_action => colorant"#2C2C2C"
)

# ╔═╡ b34799c3-61fa-49da-87c8-8f7cd171bc6e
foo(s, a::Action) = (a == bar ? 
	Tuple(s .+ [-0.9, 3]) : 
	Tuple(s .+ [-1.2, 2.5]))

# ╔═╡ 9e1fe3dc-e74c-466a-9f01-a3f858bdf5e6
outer_bounds = Bounds((0,0), (5,20))

# ╔═╡ 2c6240d4-afe0-4702-8a4d-70cdf1ca149f
outer_bounds_plus_margin = Bounds(
	outer_bounds.lower .- [1, 5], 
	outer_bounds.upper .+ [1, 5])

# ╔═╡ c5dc60a4-bd26-4d8f-9ca0-7a22f205c133
x_min, y_min = 1, 10

# ╔═╡ 4e8923c3-7e52-435e-9871-c9eae4fb812b
begin
	is_safe(point) = point[1] >= x_min || point[2] >= y_min
	is_safe(bounds::Bounds) = is_safe((bounds.lower[1], bounds.lower[2]))
end

# ╔═╡ aed5e5b0-9a21-4869-a711-64b8b0f7e8bb
md"""
## Building the Initial Tree

Building a tree with a properly bounded state space, and some divisions that align with the safety constraints.
"""

# ╔═╡ 0216683a-9096-49a9-bfbb-d34c450fcdea
begin
	initial_tree = tree_from_bounds(outer_bounds, any_action, any_action)
	split!(get_leaf(initial_tree, (x_min - 1, y_min - 1)), 2, y_min)
	split!(get_leaf(initial_tree, (x_min - 1, y_min - 1)), 1, x_min)
	split!(get_leaf(initial_tree, (x_min - 1, outer_bounds.lower[2] - 1)), 1, x_min)
	split!(get_leaf(initial_tree, (outer_bounds.lower[1] - 1, y_min - 1)), 2, y_min)
end

# ╔═╡ ab9c3f65-20de-4480-acf2-88a5a292a6d3
draw(initial_tree, outer_bounds_plus_margin, color_dict=action_color_dict)

# ╔═╡ c45d1663-8937-4bbe-aabb-73d65f50c33e
md"""
# Grow, Update, Prune --  Try it Out!

This is based on the Update notebook, which in turn is based on the Grow notebook.
"""

# ╔═╡ 8084191a-b3e6-43e1-a168-f386113e0c06
@bind reset_button Button("Reset")

# ╔═╡ 00621cfa-fd2b-4d9e-8e00-c72fa834fb34
begin
	reactive_tree = deepcopy(initial_tree)
	set_safety!(reactive_tree, dimensionality, is_safe, any_action, no_action)
	debounce1, debounce2, debounce3 = Ref(1), Ref(1), Ref(1)
	reset_button
end

# ╔═╡ 3ba30506-cc6d-44c3-97c1-8d92463af659
md"""
Try changing the number of samples per axis, to see how this affects the growth of the tree.

`spa =` $(@bind spa NumberField(1:10, default=3))

And likewise try to adjust the minimum granularity. Defined as the number of leading zeros to the one.

`granularity_decimals` $(@bind granularity_decimals NumberField(0:15))
"""

# ╔═╡ 548f07ac-1faa-44bb-8ad4-8450a234338f
@bind grow_button Button("Grow")

# ╔═╡ e38cb368-06e4-407f-a05f-93360719a72c
@bind update_button Button("Update")

# ╔═╡ fe91e5d0-f60d-4a5c-81b3-2b9381c575b8
update_button,
if debounce2[] == 1
	debounce2[] += 1
	reactivity2 = "ready"
else
	update!(reactive_tree, dimensionality, foo, Action, spa)
	reactivity2 = "updated"
end

# ╔═╡ 06872fe1-52f9-43e4-9873-34276f23098d
granularity = 10.0^(-granularity_decimals)

# ╔═╡ 15e7f68f-4bae-4301-86e7-79f757a42a13
grow_button,
if debounce1[] == 1
	debounce1[] += 1
	reactivity1 = "ready"
else
	grow!(reactive_tree, dimensionality, foo, Action, spa, granularity, max_iterations=6)
	reactivity1 = "grown"
end

# ╔═╡ cd26f5e9-1726-4633-85de-83cfc0e53fde
md"""
`show_supporting_points:`
$(@bind show_supporting_points CheckBox())

`a =` $(@bind a Select(instances(Action) |> collect))

Position: 
$(@bind partition_x 
	NumberField(outer_bounds.lower[1]:0.1:outer_bounds.upper[1]))
$(@bind partition_y 
	NumberField(outer_bounds.lower[2]:1:outer_bounds.upper[2]))
"""

# ╔═╡ 95847db1-6a80-4889-b20a-61d67fa2e46b
@bind prune_button Button("Prune")

# ╔═╡ e114cf4a-db93-453c-8716-56f545ac6726
prune_button,
if debounce3[] == 1
	debounce3[] += 1
	reactivity3 = "ready"
else
	prune!(reactive_tree)
	reactivity3 = "pruned"
end

# ╔═╡ f8d1cefd-2921-47b8-94d8-57078c849541
begin
	reactivity1, reactivity2, reactivity3
	p1 = draw(reactive_tree, outer_bounds_plus_margin, color_dict=action_color_dict)

	if show_supporting_points
		p = (partition_x, partition_y)
		draw_support_points!(reactive_tree, dimensionality, foo, spa, p, a)
		scatter!(p, m=(4, :rtriangle, :white), msw=1, label=nothing)
	end
	p1
end

# ╔═╡ 22d40c65-2fcd-4e1a-bd9b-7785896b3bdd
unique([leaf.value for leaf in Leaves(reactive_tree)])

# ╔═╡ Cell order:
# ╟─101b3a4a-523c-474c-88f0-dbafaf2f2813
# ╟─79718adb-1457-43cc-bec4-33caf7eee144
# ╠═41dcecdf-1584-439f-a30b-45f4f69f6c4c
# ╠═e51630be-8ede-49ea-ae13-545ce360b7fd
# ╠═790eb504-5569-49d4-b39b-cd3daa96503f
# ╠═bc46cf8e-6f5c-48ac-9788-40a8f5552219
# ╟─8e13bd07-ec70-416e-a00a-ef519519188c
# ╟─eddf42d5-0525-49e7-a058-87c6d240b732
# ╟─5cd0afd8-a518-4625-b91d-71ffa82ac3b0
# ╟─2165913f-036f-4709-919b-40009b8faa5f
# ╟─267f97aa-b429-4962-ab13-19cba39a6bbf
# ╟─00a6e9c2-a9c6-41ed-ae2a-701e3baf7038
# ╟─3b40135b-1a9a-4e53-8aec-60955f046414
# ╟─1f0c3fbd-27ef-44c3-b1da-6abb083daddb
# ╠═581a14d5-6833-41db-adf7-17dd213ab8a7
# ╠═0d7aca9f-460a-437e-89f8-07727adce731
# ╠═b34799c3-61fa-49da-87c8-8f7cd171bc6e
# ╠═9e1fe3dc-e74c-466a-9f01-a3f858bdf5e6
# ╠═2c6240d4-afe0-4702-8a4d-70cdf1ca149f
# ╠═c5dc60a4-bd26-4d8f-9ca0-7a22f205c133
# ╠═4e8923c3-7e52-435e-9871-c9eae4fb812b
# ╟─aed5e5b0-9a21-4869-a711-64b8b0f7e8bb
# ╠═0216683a-9096-49a9-bfbb-d34c450fcdea
# ╠═ab9c3f65-20de-4480-acf2-88a5a292a6d3
# ╟─c45d1663-8937-4bbe-aabb-73d65f50c33e
# ╟─8084191a-b3e6-43e1-a168-f386113e0c06
# ╟─00621cfa-fd2b-4d9e-8e00-c72fa834fb34
# ╟─3ba30506-cc6d-44c3-97c1-8d92463af659
# ╟─548f07ac-1faa-44bb-8ad4-8450a234338f
# ╟─15e7f68f-4bae-4301-86e7-79f757a42a13
# ╟─e38cb368-06e4-407f-a05f-93360719a72c
# ╟─fe91e5d0-f60d-4a5c-81b3-2b9381c575b8
# ╠═06872fe1-52f9-43e4-9873-34276f23098d
# ╟─cd26f5e9-1726-4633-85de-83cfc0e53fde
# ╠═95847db1-6a80-4889-b20a-61d67fa2e46b
# ╟─e114cf4a-db93-453c-8716-56f545ac6726
# ╠═f8d1cefd-2921-47b8-94d8-57078c849541
# ╠═22d40c65-2fcd-4e1a-bd9b-7785896b3bdd
