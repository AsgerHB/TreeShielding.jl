### A Pluto.jl notebook ###
# v0.19.27

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
	using StaticArrays
	TableOfContents()
end

# ╔═╡ edf99af5-443f-4c23-b63d-51d5075b30b5
begin
	@revise using TreeShielding
	using TreeShielding.RW
end

# ╔═╡ 6a50c8f7-6367-4d59-a574-c8a29a785e88
md"""
# Plus-grow

Along the middle in each axis. In the 2D case, this will resemble drawing a plus [+] across the partition.
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
	actions_to_int([fast]) => colorant"#a1eaff", 
	actions_to_int([slow]) => colorant"#a1ffc5", 
	no_action => colorant"#ff9178"
)

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
	Tuple(outer_bounds.lower .- [0.5, 0.5]),
	Tuple(outer_bounds.upper .+ [0.5, 0.5])
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

# ╔═╡ 52015eb7-b4d8-4a08-98b4-c6e006179452
md"""
## The plus-split
"""

# ╔═╡ 5a54dde8-041a-4f0e-ad7d-71a84999c0f0
"""
	homogenous(root::Tree, leaf::Tree, m::ShieldingModel)

Check if all samples within the bounds of `leaf` are homogenous in terms of which actions are safe. That is, the function returns true if all samples in the partition have the same set of safe actions, and false otherwise.

This is used to determine whether it makes sense to split the leaf further.
"""
function homogenous(root::Tree, leaf::Tree, m::ShieldingModel)
	no_action = actions_to_int([])
	bounds = get_bounds(leaf, m.dimensionality)
	actions_allowed = nothing
	for p in SupportingPoints(m.samples_per_axis, bounds)
		actions_allowed′ = []
		for a in m.action_space
			action_safe = true
			
			for r in SupportingPoints(m.samples_per_axis, 
				m.random_variable_bounds)
				
				p′ = m.simulation_function(p, r, a)
				leaf = get_leaf(root, p′)
				action_safe = action_safe && get_value(leaf) != no_action
				!action_safe && break
			end
			if action_safe
				push!(actions_allowed′, a)
			end
		end
		if isnothing(actions_allowed)
			actions_allowed = actions_allowed′
		elseif actions_allowed != actions_allowed′
				return false
		end
	end
	return true
end;

# ╔═╡ b7d5ff7f-d020-4e6b-bc49-f3e81b325e2d
"""
	plus_split!(leaf::Leaf, dimensionality; min_granularity=nothing)

Perform a "plus shaped" split, such that the leaf is split down the middle of each axis.

If the dimensionality is `n` then this creates `2^n` new leaves.
"""
function plus_split!(leaf::Leaf, dimensionality; min_granularity=nothing)
	queue = Leaf[leaf]
	result = leaf
	for axis in 1:dimensionality
		queue′ = Leaf[]
		while length(queue) > 0
			l = pop!(queue)
			bounds = get_bounds(l, dimensionality)
			width = bounds.upper[axis] - bounds.lower[axis]
			if !isnothing(min_granularity) && width/2 < min_granularity
				continue
			end
			threshold = bounds.lower[axis] + width/2
			node = split!(l, axis, threshold)
			if result == leaf
				result = node
			end
			push!(queue′, node.lt)
			push!(queue′, node.geq)
		end
		queue = queue′
	end
	return result
end;

# ╔═╡ efe775a4-7ec7-451a-b3db-2d2f52fba186
md"""
### Parameters -- Try it Out!
!!! info "Tip"
	This cell controls multiple figures. Move it around to gain a better view.

Try setting a different number of samples per axis: 

`samples_per_axis =` $(@bind samples_per_axis NumberField(3:30, default=9))

`granularity =` $(@bind granularity NumberField(0:1E-15:1, default=1E-2))

`margin =` $(@bind margin NumberField(0:0.001:1, default=0.00))

`splitting_tolerance =` $(@bind splitting_tolerance NumberField(0:1E-10:1, default=1E-5))
"""

# ╔═╡ 364a95c2-de8a-468a-86eb-db18a5489c9d
m = ShieldingModel(simulation_function, Pace, dimensionality, samples_per_axis, random_variable_bounds; granularity, margin, splitting_tolerance)

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

# ╔═╡ eefd8f73-9632-4f7d-a1f2-42a7a048bc88
homogenous(tree, get_leaf(tree, 0.5, 0.5), m)

# ╔═╡ 9be6489e-0e9e-451e-94a8-d87a845c0a3c
let
	tree = deepcopy(tree)
	leaf = get_leaf(tree, (0.5, 0.5))
	plus_split!(leaf, m.dimensionality)
	draw(tree, draw_bounds, color_dict=action_color_dict, 
		aspectratio=:equal,
		legend=:outertop,
		size=(200,200))
	leaf_count = length(Leaves(tree) |> collect)
	plot!([], l=nothing, label="leaves: $leaf_count")
end

# ╔═╡ 8d33bf42-ff2d-444a-9a82-433981cc6f12
begin
	"""
		grow_plus!(root::Tree, leaf::Leaf, m::ShieldingModel)
		grow_plus!(root::Tree, node::Node, m::ShieldingModel)

	Grow the tree using "plus shaped" splitting. In the 2D case, whenever there are a mix of safe and unsafe samples for some action, the partition is split into four rectangles along the middle.
	"""
	function grow_plus!(root::Tree, leaf::Leaf, m::ShieldingModel)
		if m.granularity == 0
			error("Won't terminate: granularity cannot be zero.")
		end
		
		no_actions = actions_to_int([])

		# Bad partitions stay bad
		if leaf.value == no_actions
			return leaf
		end
		
		# Don't split unbounded partitions.
		bounds = get_bounds(leaf, m.dimensionality)
		if !bounded(bounds) 
			return leaf
		end

		if homogenous(root, leaf, m)
			return leaf
		end
		
		new_node = plus_split!(leaf, m.dimensionality, min_granularity=m.granularity)
		if !(new_node isa Leaf)
			grow_plus!(root, new_node, m)
		else
			return new_node
		end
	end

	function grow_plus!(root::Tree, node::Node, m::ShieldingModel)
		grow_plus!(root, node.lt, m)
		grow_plus!(root, node.geq, m)
	end
end

# ╔═╡ 4040a51b-c7b4-4454-b996-cb40338d8402
let
	tree = deepcopy(tree)
	grow_plus!(tree, tree, m)
	draw(tree, draw_bounds, color_dict=action_color_dict, 
		aspectratio=:equal,
		legend=:outerright,
		size=(400, 300))
	add_actions_to_legend(action_color_dict, m.action_space)
	leaf_count = length(Leaves(tree) |> collect)
	#=
	leaf = get_leaf(tree, (x, t))
	bounds = get_bounds(leaf, m.dimensionality)
	scatter_allowed_actions!(tree, bounds, m)

	@info get_partition_status(leaf, m)

	scatter!([x], [t], marker=(:rtriangle, 10, :white), label=nothing)
	=#
	plot!([], l=nothing, label="leaves: $leaf_count")
end

# ╔═╡ a6b1402a-d1cc-4eb0-9334-cbf811827662
md"""
# Try it out!
"""

# ╔═╡ afbb777f-6cdf-4af4-831d-b8992531f20b
m; (
	@bind reset_button Button("Reset")
)

# ╔═╡ ddf18eba-38da-4e78-a204-040034ea55fd
reset_button; (
	reactive_tree = deepcopy(tree)
)

# ╔═╡ d2097fb9-cf4c-4fb6-b23a-6721cc7017f2
reset_button; @bind grow_button CounterButton("Grow")

# ╔═╡ 87581d91-2c9a-4505-8367-722038c962a8
if grow_button > 0 let
	grow_plus!(reactive_tree, reactive_tree, m)
end end

# ╔═╡ 407a80cd-9110-4c28-b5eb-6c5b3e858624
reset_button; @bind update_button CounterButton("Update")

# ╔═╡ 8fe8cc53-ad34-4f75-8b36-37b0f43d3ab0
if update_button > 0 let
	update!(reactive_tree, m)
end end

# ╔═╡ 9abaf75a-7832-445f-83ff-6e6fd0c4fb71
reset_button; @bind prune_button CounterButton("Prune")

# ╔═╡ 3e62fb7a-921d-4db9-8bde-fcf509f2a9ab
if prune_button > 0 let
	prune!(reactive_tree)
end end

# ╔═╡ a7a033c6-b1fc-4791-bfe0-c454ad618c91
md"""
`x = ` $(@bind x NumberField(rwmechanics.x_min:0.01:rwmechanics.x_max))

`t = ` $(@bind t NumberField(rwmechanics.t_min:0.01:rwmechanics.t_max))

`show_cursor = ` $(@bind show_cursor CheckBox())
"""

# ╔═╡ a175916f-0b4b-47d5-9a0f-c4668146801c
let	
	reset_button, grow_button, update_button, prune_button
	draw(reactive_tree, draw_bounds, color_dict=action_color_dict, 
		aspectratio=:equal,
		legend=:outerright,
		size=(800, 500))
	add_actions_to_legend(action_color_dict, m.action_space)
	leaf_count = length(Leaves(reactive_tree) |> collect)

	if show_cursor
		leaf = get_leaf(reactive_tree, (x, t))
		bounds = get_bounds(leaf, m.dimensionality)
		scatter_allowed_actions!(reactive_tree, bounds, m)
		scatter!([x], [t], marker=(:rtriangle, 5, :white), label=nothing)
	end	
		
	plot!([], l=nothing, label="leaves: $leaf_count")
end

# ╔═╡ d7063385-0fae-4326-81da-7d37411a0fe2
md"""
# Everything in one loop
"""

# ╔═╡ 8dac6296-9656-4698-9e4b-d7c4c7c42833
let
	tree = deepcopy(tree)
	updates = -1
	while updates != 0
		grow_plus!(tree, tree, m)
		updates = update!(tree, m)
	end
	prune!(tree)
	draw(tree, draw_bounds, color_dict=action_color_dict, 
		aspectratio=:equal,
		legend=:topleft,
		size=(500, 500))
	add_actions_to_legend(action_color_dict, m.action_space)
	leaf_count = length(Leaves(tree) |> collect)
	plot!([], l=nothing, label="leaves: $leaf_count")
end

# ╔═╡ 7f10ecc9-ab21-4299-9f8d-c69fe3ace234
"""
	synthesize_plus!(tree::Tree, m::ShieldingModel)

Synthesize a safety strategy using the "plus shaped" dynamic partitioning strategy. 
"""
function synthesize_plus!(tree::Tree, m::ShieldingModel)
	while updates != 0
		grow_plus!(tree, tree, m)
		updates = update!(tree, m)
	end
	prune!(tree)
end;

# ╔═╡ Cell order:
# ╟─6a50c8f7-6367-4d59-a574-c8a29a785e88
# ╠═23a8f930-95ae-4820-bac0-82edd0bfbc8a
# ╠═edf99af5-443f-4c23-b63d-51d5075b30b5
# ╟─1550fddd-6b9d-4b16-9265-c12f44b0f1e4
# ╟─00716b11-f49e-4790-9442-c4e24d05f369
# ╟─c669d727-88fb-4ee8-9f50-7681d1b8df5a
# ╠═193ea2f4-548f-4dcf-b661-4bf1aca16b43
# ╠═ae6142f5-ace2-4211-9318-6f8257f2fdfa
# ╠═b05c8d41-c62c-4780-90d6-7aa174645770
# ╟─00d60986-0a1b-4b8e-87e7-dc8597dc35b0
# ╠═55931748-f860-4ced-9fc9-3906368042ba
# ╟─70c269f7-e47c-4405-8012-4f1c68cfb879
# ╠═0e22d8cc-bd9d-4ff1-a369-c8f1b73f65f1
# ╠═d88cd139-6a31-4d9d-b1c5-f6828c16d441
# ╠═4ba1c107-8db5-4273-95f6-77b66b25b2c3
# ╟─9ea39d19-4238-4e6e-abb9-968bdcaa8851
# ╠═40068b9c-3faf-4091-9786-fbfab9973485
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
# ╟─52015eb7-b4d8-4a08-98b4-c6e006179452
# ╠═16d39b87-8d2d-4a54-8eb1-ee727671e299
# ╠═e2c7decc-ec60-4eae-88c3-491ca06673ea
# ╠═5a54dde8-041a-4f0e-ad7d-71a84999c0f0
# ╠═eefd8f73-9632-4f7d-a1f2-42a7a048bc88
# ╠═9be6489e-0e9e-451e-94a8-d87a845c0a3c
# ╠═b7d5ff7f-d020-4e6b-bc49-f3e81b325e2d
# ╟─efe775a4-7ec7-451a-b3db-2d2f52fba186
# ╠═8d33bf42-ff2d-444a-9a82-433981cc6f12
# ╠═4040a51b-c7b4-4454-b996-cb40338d8402
# ╟─a6b1402a-d1cc-4eb0-9334-cbf811827662
# ╟─afbb777f-6cdf-4af4-831d-b8992531f20b
# ╠═ddf18eba-38da-4e78-a204-040034ea55fd
# ╠═d2097fb9-cf4c-4fb6-b23a-6721cc7017f2
# ╠═87581d91-2c9a-4505-8367-722038c962a8
# ╠═407a80cd-9110-4c28-b5eb-6c5b3e858624
# ╠═8fe8cc53-ad34-4f75-8b36-37b0f43d3ab0
# ╠═9abaf75a-7832-445f-83ff-6e6fd0c4fb71
# ╠═3e62fb7a-921d-4db9-8bde-fcf509f2a9ab
# ╟─a7a033c6-b1fc-4791-bfe0-c454ad618c91
# ╟─a175916f-0b4b-47d5-9a0f-c4668146801c
# ╟─d7063385-0fae-4326-81da-7d37411a0fe2
# ╠═8dac6296-9656-4698-9e4b-d7c4c7c42833
# ╠═7f10ecc9-ab21-4299-9f8d-c69fe3ace234
