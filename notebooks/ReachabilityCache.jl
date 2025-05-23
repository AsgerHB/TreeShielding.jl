### A Pluto.jl notebook ###
# v0.20.8

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    #! format: off
    return quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
    #! format: on
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
	using Setfield
	using AbstractTrees
	TableOfContents()
end

# ╔═╡ e51630be-8ede-49ea-ae13-545ce360b7fd
@revise using TreeShielding

# ╔═╡ 173db6eb-5937-49c2-bcd2-554df231e2f7
using TreeShielding.environments.RandomWalk

# ╔═╡ 101b3a4a-523c-474c-88f0-dbafaf2f2813
md"""
# Reachability Cache

Notebook for debugging reachability cache. Plots arrows representing `incoming` and `reachable` from selected leaf.

Leaves with orphan leaves in their reachability cache will be highlighted in red.
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

# ╔═╡ 9eec4dbf-037d-4d4b-84ca-b9cb89d14bd1
any_action, no_action = actions_to_int([fast, slow]), actions_to_int([])

# ╔═╡ 5cd0afd8-a518-4625-b91d-71ffa82ac3b0
action_color_dict=Dict(
	any_action => colorant"#FFFFFF", 
	actions_to_int([fast]) => colorant"#9C59D1", 
	actions_to_int([slow]) => colorant"#FCF434", 
	no_action => colorant"#2C2C2C"
)

# ╔═╡ aed5e5b0-9a21-4869-a711-64b8b0f7e8bb
md"""
## Building the Initial Tree

Building a tree with a properly bounded state space, and some divisions that align with the safety constraints.
"""

# ╔═╡ d30c4834-0662-4db0-b8da-0d47bc58c6b3
outer_bounds = Bounds([0, 0], [1, 1])

# ╔═╡ f324d5f2-4f49-4009-84db-11b5a0a75669
outer_bounds_plus_margin = 
	Bounds(outer_bounds.lower - [0.1, 0.1], 
		   outer_bounds.upper + [0.1, 0.1])

# ╔═╡ 0216683a-9096-49a9-bfbb-d34c450fcdea
begin
	initial_tree = tree_from_bounds(outer_bounds, any_action, any_action)
	set_safety!(initial_tree, dimensionality, is_safe, any_action, no_action)
end

# ╔═╡ d1681879-edda-4073-a49e-4a1335002637
m = ShieldingModel(;environment..., 
				   samples_per_axis=3,
				   granularity=0.01,
				   pruning=naïve,
				   grow_method=plus,
				   reachability_caching=dependency_graph)

# ╔═╡ c45d1663-8937-4bbe-aabb-73d65f50c33e
md"""
# Grow, Update, Prune --  Try it Out!

This is based on the Update notebook, which in turn is based on the Grow notebook.
"""

# ╔═╡ 8084191a-b3e6-43e1-a168-f386113e0c06
m; @bind reset_button Button("Reset")

# ╔═╡ 00621cfa-fd2b-4d9e-8e00-c72fa834fb34
begin
	reactive_tree = copy(initial_tree)
	#set_safety!(reactive_tree, dimensionality, is_safe, any_action, no_action)
	reset_button
end

# ╔═╡ 548f07ac-1faa-44bb-8ad4-8450a234338f
reset_button; @bind grow_button CounterButton("Grow")

# ╔═╡ 15e7f68f-4bae-4301-86e7-79f757a42a13
if grow_button > 0
	grow!(reactive_tree, m)
	reactivity1 = "grown"
end

# ╔═╡ e38cb368-06e4-407f-a05f-93360719a72c
reset_button; @bind update_button CounterButton("Update")

# ╔═╡ fe91e5d0-f60d-4a5c-81b3-2b9381c575b8
if update_button > 0
	update!(reactive_tree, m)
	reactivity2 = "updated"
end

# ╔═╡ 95847db1-6a80-4889-b20a-61d67fa2e46b
reset_button; @bind prune_button CounterButton("Prune")

# ╔═╡ e114cf4a-db93-453c-8716-56f545ac6726
if prune_button > 0
	prune!(reactive_tree, m)
	reactivity3 = "pruned"
end

# ╔═╡ cd26f5e9-1726-4633-85de-83cfc0e53fde
md"""
`show_supporting_points:`
$(@bind show_supporting_points CheckBox(default=true))

`a =` $(@bind a Select(instances(Pace) |> collect))

Position: 
$(@bind partition_x 
	NumberField(outer_bounds.lower[1]:0.01:outer_bounds.upper[1], default=0.7))
$(@bind partition_y 
	NumberField(outer_bounds.lower[2]:0.01:outer_bounds.upper[2], default=0.7))
"""

# ╔═╡ 91113f19-bb4b-44c6-8cfb-00774ae3753b
p = (partition_x, partition_y)

# ╔═╡ b1ae86a0-dc42-4df9-b68b-220b117ee791
grow_button; update_button; prune_button; leaf = get_leaf(reactive_tree, p)

# ╔═╡ 3ace7cd9-3e2d-438e-8845-d25665bb0204
bounds = get_bounds(leaf, m.dimensionality)

# ╔═╡ f8d1cefd-2921-47b8-94d8-57078c849541
begin
	reset_button, grow_button, update_button, prune_button
	p1 = draw(reactive_tree, outer_bounds_plus_margin, color_dict=action_color_dict)

	if show_supporting_points
		#TreeShielding.set_reachable!(reactive_tree, m)
		show_reachable!(leaf, a, m)
		show_incoming!(leaf, m)
		if leaf.dirty
			scatter!(Tuple(middle(bounds)), m=(5, :x, :black), msw=4, label="Leaf is dirty")
		end
		scatter!(p, m=(4, :rtriangle, :white), msw=1, label=nothing)
	end

	bad_leaves = TreeShielding.get_leaves_with_orphans_in_cache(reactive_tree)
	bad_leaves = [get_bounds(bad, m.dimensionality) for bad in bad_leaves]

	if length(bad_leaves) > 0
		plot!(bad_leaves,
			  color=:red,
			  seriestype=:shape,
			  label="Leaves with orphans in their cache")
	end
	
	p1
end

# ╔═╡ 8af9e56a-51d4-4259-8bff-2b0844285c28
[(p, safe) for (p, safe) in compute_safety(reactive_tree, bounds, m) if !safe] |> unique

# ╔═╡ c512af10-6aa7-4992-a49f-7ca05172c833
leaf.reachable

# ╔═╡ 22d40c65-2fcd-4e1a-bd9b-7785896b3bdd
unique([leaf.value for leaf in Leaves(reactive_tree)])

# ╔═╡ Cell order:
# ╟─101b3a4a-523c-474c-88f0-dbafaf2f2813
# ╟─79718adb-1457-43cc-bec4-33caf7eee144
# ╠═41dcecdf-1584-439f-a30b-45f4f69f6c4c
# ╠═e51630be-8ede-49ea-ae13-545ce360b7fd
# ╠═173db6eb-5937-49c2-bcd2-554df231e2f7
# ╠═790eb504-5569-49d4-b39b-cd3daa96503f
# ╠═bc46cf8e-6f5c-48ac-9788-40a8f5552219
# ╟─8e13bd07-ec70-416e-a00a-ef519519188c
# ╟─eddf42d5-0525-49e7-a058-87c6d240b732
# ╠═9eec4dbf-037d-4d4b-84ca-b9cb89d14bd1
# ╟─5cd0afd8-a518-4625-b91d-71ffa82ac3b0
# ╟─aed5e5b0-9a21-4869-a711-64b8b0f7e8bb
# ╠═d30c4834-0662-4db0-b8da-0d47bc58c6b3
# ╠═f324d5f2-4f49-4009-84db-11b5a0a75669
# ╠═0216683a-9096-49a9-bfbb-d34c450fcdea
# ╠═d1681879-edda-4073-a49e-4a1335002637
# ╟─c45d1663-8937-4bbe-aabb-73d65f50c33e
# ╟─8084191a-b3e6-43e1-a168-f386113e0c06
# ╟─00621cfa-fd2b-4d9e-8e00-c72fa834fb34
# ╟─548f07ac-1faa-44bb-8ad4-8450a234338f
# ╟─15e7f68f-4bae-4301-86e7-79f757a42a13
# ╟─e38cb368-06e4-407f-a05f-93360719a72c
# ╟─fe91e5d0-f60d-4a5c-81b3-2b9381c575b8
# ╟─95847db1-6a80-4889-b20a-61d67fa2e46b
# ╟─e114cf4a-db93-453c-8716-56f545ac6726
# ╠═f8d1cefd-2921-47b8-94d8-57078c849541
# ╠═cd26f5e9-1726-4633-85de-83cfc0e53fde
# ╠═91113f19-bb4b-44c6-8cfb-00774ae3753b
# ╠═b1ae86a0-dc42-4df9-b68b-220b117ee791
# ╠═8af9e56a-51d4-4259-8bff-2b0844285c28
# ╠═3ace7cd9-3e2d-438e-8845-d25665bb0204
# ╠═c512af10-6aa7-4992-a49f-7ca05172c833
# ╠═22d40c65-2fcd-4e1a-bd9b-7785896b3bdd
