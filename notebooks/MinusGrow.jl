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
	using Random
	TableOfContents()
end

# ╔═╡ edf99af5-443f-4c23-b63d-51d5075b30b5
begin
	@revise using TreeShielding
	using TreeShielding.RW
	using TreeShielding.BB
end

# ╔═╡ 6a50c8f7-6367-4d59-a574-c8a29a785e88
md"""
# Minus-grow

Split leaves down the middle of a random axis, until all leaves are either homogenous or down to some minimum splitting value.

I call it minus-split in reference to a plus-split that I also tried.
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
	any_action => colorant"#FFFFFF", 
	actions_to_int([fast]) => colorant"#9C59D1", 
	actions_to_int([slow]) => colorant"#FCF434", 
	no_action => colorant"#2C2C2C"
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
	Tuple(outer_bounds.lower .- [0.1 , 0.1 ]),
	Tuple(outer_bounds.upper .+ [0.1 , 0.1 ])
)

# ╔═╡ fbffa476-2fb1-46b3-b591-ecc7d6cc17d3
begin
	initial_tree = tree_from_bounds(outer_bounds, any_action, any_action)
	
	x_min, y_min = rwmechanics.x_min, rwmechanics.t_min
	x_max, y_max = rwmechanics.x_max, rwmechanics.t_max
	split!(get_leaf(initial_tree, x_min - 1, y_max), 2, y_max)
	split!(get_leaf(initial_tree, x_max + 1, y_max), 2, y_max)
	split!(get_leaf(initial_tree, 0, 0), 2, y_max/2)
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
	tree = set_safety!(copy(initial_tree), 
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
## The minus-split
"""

# ╔═╡ ee5a1881-3040-4748-aec2-5ffe14e51b7e


# ╔═╡ 0a3bb8da-1194-4b08-9951-5252d07b52e6


# ╔═╡ 229a0d92-1daa-4711-8570-79286bdc4e88


# ╔═╡ d43e8771-dee1-493f-82b1-1277e279a7b5
TreeShielding.get_root(get_leaf(tree, (.1, .1)))

# ╔═╡ a6b1402a-d1cc-4eb0-9334-cbf811827662
md"""
# Try it out!
"""

# ╔═╡ a7a033c6-b1fc-4791-bfe0-c454ad618c91
md"""
`x = ` $(@bind x NumberField(rwmechanics.x_min:0.01:rwmechanics.x_max))

`t = ` $(@bind t NumberField(rwmechanics.t_min:0.01:rwmechanics.t_max))

`show_cursor = ` $(@bind show_cursor CheckBox())
"""

# ╔═╡ d7063385-0fae-4326-81da-7d37411a0fe2
md"""
# Everything in one loop
"""

# ╔═╡ efe775a4-7ec7-451a-b3db-2d2f52fba186
md"""
### Parameters -- Try it Out!
!!! info "Tip"
	This cell controls multiple figures. Move it around to gain a better view.

Try setting a different number of samples per axis: 

`samples_per_axis =` $(@bind samples_per_axis NumberField(3:30, default=9))

`granularity =` $(@bind granularity NumberField(0:1E-15:1, default=1E-2))

`splitting_tolerance =` $(@bind splitting_tolerance NumberField(0:1E-10:1, default=1E-5))
"""

# ╔═╡ 364a95c2-de8a-468a-86eb-db18a5489c9d
m = ShieldingModel(;simulation_function, 
				   action_space=Pace, 
				   dimensionality,
				   grow_method=minus,
				   pruning=naïve,
				   samples_per_axis, 
				   random_variable_bounds, 
				   granularity, 
				   splitting_tolerance)

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

# ╔═╡ 9be6489e-0e9e-451e-94a8-d87a845c0a3c
let
	📽️ = @animate for i in 1:10
		tree′ = copy(tree)
		
		leaf = get_leaf(tree′, (0.5, 0.5))
		node = TreeShielding.try_split_minus!(tree′, leaf, m)
		
		leaf = get_leaf(tree′, (0.5, 0.5))
		node = TreeShielding.try_split_minus!(tree′, leaf, m)
		
		draw(tree′, draw_bounds, color_dict=action_color_dict, 
			aspectratio=:equal,
			legend=:outertop,
			size=(300, 300))
		
		leaf_count = length(Leaves(tree′) |> collect)
		plot!([], 
			  	l=nothing, 
			  	label="leaves: $leaf_count",
			  	titlefontsize=12,
				title="Performing minus-split twice")
	end
	gif(📽️, fps=3, show_msg=false)
end

# ╔═╡ afbb777f-6cdf-4af4-831d-b8992531f20b
m; (
	@bind reset_button Button("Reset")
)

# ╔═╡ d2097fb9-cf4c-4fb6-b23a-6721cc7017f2
reset_button; @bind grow_button CounterButton("Grow")

# ╔═╡ 407a80cd-9110-4c28-b5eb-6c5b3e858624
reset_button; @bind update_button CounterButton("Update")

# ╔═╡ 9abaf75a-7832-445f-83ff-6e6fd0c4fb71
reset_button; @bind prune_button CounterButton("Prune")

# ╔═╡ ddf18eba-38da-4e78-a204-040034ea55fd
reset_button; begin
	reactive_tree = copy(tree)
	clear_reachable!(reactive_tree, m)
end

# ╔═╡ 87581d91-2c9a-4505-8367-722038c962a8
if grow_button > 0
	@time grow!(reactive_tree, m)
else
	nothing
end

# ╔═╡ 8fe8cc53-ad34-4f75-8b36-37b0f43d3ab0
if update_button > 0 let
	@time update!(reactive_tree, m)
end end

# ╔═╡ 3e62fb7a-921d-4db9-8bde-fcf509f2a9ab
if prune_button > 0 let
	@time prune!(reactive_tree, m)
end end

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

# ╔═╡ 8dac6296-9656-4698-9e4b-d7c4c7c42833
let
	tree = copy(tree)
	synthesize!(tree, m)
	
	draw(tree, draw_bounds, color_dict=action_color_dict, 
		aspectratio=:equal,
		legend=:topleft,
		size=(500, 500))
	
	add_actions_to_legend(action_color_dict, m.action_space)
	leaf_count = length(Leaves(tree) |> collect)
	plot!([], l=nothing, label="leaves: $leaf_count")
end

# ╔═╡ 7f54a9c8-61c1-4a39-a9b0-a0f2f2223795
md"""
# Synthesis Animation

**very slow**

Generate an animation which shows every little step of the synthesis.
One frame for each split, and each leaf coloured in.

It's really fun to look at, kind of looking at a disc defragmenting.
"""

# ╔═╡ d832260e-773c-414c-8bf9-7b0e3588c1e1
@bind make_animation_button CounterButton("Make Animation")

# ╔═╡ 4040a51b-c7b4-4454-b996-cb40338d8402
📽 = let
	t = copy(tree)
	mm = @set(m.grow_method=minus)
	mm = @set(mm.pruning=naïve)

	📽 = Animation()
	
	function 📸(tree::Tree)
		draw(tree, draw_bounds, color_dict=action_color_dict, 
			aspectratio=:equal,
			legend=:bottomleft,
			size=(300, 300))
		
		frame(📽)
	end

	if make_animation_button > 0
	
		📸(t)
		
		synthesize!(t, mm, animation_callback=📸)
	end
	
	📸(t)
		
	📽
end;

# ╔═╡ 956b3db6-80ff-474e-92db-6690a5887e6d
if make_animation_button > 0
	gif(📽, fps=24, show_msg=false)
end

# ╔═╡ cf606e09-801d-447d-874e-844ce6d9c49c
md"""
# BB
"""

# ╔═╡ 10f5db07-5455-4c18-a79c-d53531220954
bb = let
	random_variable_bounds = Bounds((-1,), (1,))
	
	simulation_function(p, r, a) = 
		simulate_point(bbmechanics, p, r, a, min_v_on_impact=1)
	
	dimensionality = 2
	samples_per_axis = 3
	granularity = 0.01
	max_iterations = 300
	
	splitting_tolerance = granularity
	
	ShieldingModel(;simulation_function,
				   action_space=BB.Action,
				   pruning=naïve,
				   grow_method=minus,
				   dimensionality,
				   samples_per_axis,
				   random_variable_bounds,
				   max_iterations,
				   granularity,
				   splitting_tolerance)
end

# ╔═╡ 6bfd95e2-df1c-414c-8014-a31895173f1e
bb_tree = let
	is_safe(state) = abs(state[1]) > 1 || state[2] > 0
	is_safe(bounds::Bounds) = is_safe((bounds.lower[1], bounds.lower[2]))

	any_action, no_action = actions_to_int(instances(BB.Action)), actions_to_int([])
	
	outer_bounds = Bounds((-15, 0), (15, 10))
	
	tree = tree_from_bounds(outer_bounds)
	inside = get_leaf(tree, 0, 0)

	unsafe_states = Bounds((-1, 0), (2, 1))
	split!(inside, 1, unsafe_states.lower[1])
	inside = get_leaf(tree, 0, 0)
	split!(inside, 1, unsafe_states.upper[1])
	inside = get_leaf(tree, 0, 0)
	split!(inside, 2, unsafe_states.upper[2])
	inside = get_leaf(tree, 0, 0)
	set_safety!(tree, dimensionality, is_safe, any_action, no_action)
end

# ╔═╡ 9a28eb36-cbe6-4b50-9d55-786b5d645bc7
begin
	draw(bb_tree, Bounds((-16, -1), (16, 11)),
		xlabel="v",
		ylabel="p",
	 	line=0.1,
		title="initial")
		
	add_actions_to_legend(action_color_dict, bb.action_space)
end

# ╔═╡ 45002c2b-8df7-4f42-b95d-47fc2833c39d
let
	bb_tree = copy(bb_tree)
	grow!(bb_tree, bb)
	
	draw(bb_tree, Bounds((-16, -1), (16, 11)),
		xlabel="v",
		ylabel="p",
	 	line=0.1,
		title="First grow-step")
		
	add_actions_to_legend(action_color_dict, bb.action_space)
end

# ╔═╡ 1aec4440-3db6-495b-a994-1831a694cdf1
@bind synthesize_bb_button CounterButton("Synthesize BB")

# ╔═╡ 39dc7fc6-da83-4c90-b288-90e0ea73aef7
bb_strategy = let
	bb_tree = copy(bb_tree)
	if synthesize_bb_button > 0
		synthesize!(bb_tree, bb)
	end
	bb_tree
end;

# ╔═╡ aec7bf28-6b61-438c-9711-d853e9491af3
bb_strategy′ = let
	bb_strategy = copy(bb_strategy)
	if synthesize_bb_button > 0
		synthesize!(bb_strategy, @set bb.samples_per_axis = 8)
	end
	prune!(bb_strategy, m)
	bb_strategy
end;

# ╔═╡ 673498e0-690b-497a-a0a7-569b716482f5
begin
	draw(bb_strategy′, Bounds((-16, -1), (16, 11)),
		xlabel="v",
		ylabel="p",
	 	line=0.1,
		title="Bouncing Ball Safety Strategy")
	
	add_actions_to_legend(action_color_dict, bb.action_space)
end

# ╔═╡ dfaf1fd7-3e1d-4a5d-9343-6a18a6ce576a
function shield(tree::Tree, action_type, policy)
    return (p) -> begin
		a = policy(p)
        allowed = int_to_actions(action_type, get_value(tree, p))
        if a ∈ allowed
            return a
        elseif length(allowed) > 0
			a′ = rand(allowed)
            return a′
        else
            return a
        end
    end
end

# ╔═╡ a375a86b-d7ac-432b-a717-e5e4a8b69a71
check_safety(bbmechanics, 
	shield(bb_strategy′, BB.Action, (_...) -> nohit), 
	120, 
	runs=2000)

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
# ╟─16d39b87-8d2d-4a54-8eb1-ee727671e299
# ╠═e2c7decc-ec60-4eae-88c3-491ca06673ea
# ╟─9be6489e-0e9e-451e-94a8-d87a845c0a3c
# ╟─ee5a1881-3040-4748-aec2-5ffe14e51b7e
# ╟─0a3bb8da-1194-4b08-9951-5252d07b52e6
# ╟─229a0d92-1daa-4711-8570-79286bdc4e88
# ╠═d43e8771-dee1-493f-82b1-1277e279a7b5
# ╟─a6b1402a-d1cc-4eb0-9334-cbf811827662
# ╟─afbb777f-6cdf-4af4-831d-b8992531f20b
# ╠═ddf18eba-38da-4e78-a204-040034ea55fd
# ╟─d2097fb9-cf4c-4fb6-b23a-6721cc7017f2
# ╠═87581d91-2c9a-4505-8367-722038c962a8
# ╟─407a80cd-9110-4c28-b5eb-6c5b3e858624
# ╠═8fe8cc53-ad34-4f75-8b36-37b0f43d3ab0
# ╠═9abaf75a-7832-445f-83ff-6e6fd0c4fb71
# ╠═3e62fb7a-921d-4db9-8bde-fcf509f2a9ab
# ╟─a175916f-0b4b-47d5-9a0f-c4668146801c
# ╟─a7a033c6-b1fc-4791-bfe0-c454ad618c91
# ╟─d7063385-0fae-4326-81da-7d37411a0fe2
# ╟─efe775a4-7ec7-451a-b3db-2d2f52fba186
# ╠═8dac6296-9656-4698-9e4b-d7c4c7c42833
# ╟─7f54a9c8-61c1-4a39-a9b0-a0f2f2223795
# ╟─d832260e-773c-414c-8bf9-7b0e3588c1e1
# ╟─4040a51b-c7b4-4454-b996-cb40338d8402
# ╟─956b3db6-80ff-474e-92db-6690a5887e6d
# ╟─cf606e09-801d-447d-874e-844ce6d9c49c
# ╠═10f5db07-5455-4c18-a79c-d53531220954
# ╠═6bfd95e2-df1c-414c-8014-a31895173f1e
# ╟─9a28eb36-cbe6-4b50-9d55-786b5d645bc7
# ╟─45002c2b-8df7-4f42-b95d-47fc2833c39d
# ╠═1aec4440-3db6-495b-a994-1831a694cdf1
# ╠═39dc7fc6-da83-4c90-b288-90e0ea73aef7
# ╠═aec7bf28-6b61-438c-9711-d853e9491af3
# ╠═673498e0-690b-497a-a0a7-569b716482f5
# ╠═dfaf1fd7-3e1d-4a5d-9343-6a18a6ce576a
# ╠═a375a86b-d7ac-432b-a717-e5e4a8b69a71
