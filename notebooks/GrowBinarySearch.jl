### A Pluto.jl notebook ###
# v0.20.4

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    #! format: off
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
    #! format: on
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
	using Printf
	using Setfield
	using StaticArrays
	TableOfContents()
end

# ╔═╡ 06791d29-7dbd-4487-8448-cc84a1631025
begin
	@revise using TreeShielding
	using TreeShielding.RW
end

# ╔═╡ 137adf90-a162-11ed-358b-6fc69c09feba
md"""
# Binary-search Split
This notebook demonstrates the `binary_search` option for the `ShieldingModel`, used in the `grow!` function. 

Scroll to the bottom to see it in action, or read from the beginning to get the full context of what it does.
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
	any_action => colorant"#FFFFFF", 
	actions_to_int([fast]) => colorant"#9C59D1", 
	actions_to_int([slow]) => colorant"#FCF434", 
	no_action => colorant"#2C2C2C"
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

# ╔═╡ f0467c66-f1b4-441c-8786-259df7b6403b
md"""
### The Random Factor

The actions are affected by a random factor $\pm \epsilon$ in each dimension. This is captured in the below bounds, which make up part of the model. This will be used as part of the reachability simulation.
"""

# ╔═╡ fca75822-38bc-4cd4-a939-421a950c6859
ϵ = rwmechanics.ϵ

# ╔═╡ 7948d730-203c-4656-bf7a-2b446ac335f7
random_variable_bounds = Bounds((-ϵ,  -ϵ), (ϵ, ϵ))

# ╔═╡ de7fe51c-0f75-49bb-bc6f-726a21bcd064
md"""
### The Simulation Function

The function for taking a single step needs to be wrapped up, so that it has the signature `(point::AbstractVector, action, random_variables::AbstractVector) -> updated_point`. 
"""

# ╔═╡ 07ed71cc-a931-4785-9707-86aad883df30
simulation_function(point, random_variables, action) = RW.simulate(
	rwmechanics, 
	point[1], 
	point[2], 
	action,
	random_variables)

# ╔═╡ b1276cfe-4018-4f49-8c43-3e4c622e93f3
md"""
The goal of the game is to reach `x >= x_max` without reaching `t >= t_max`. 

This corresponds to the below safety property. It is defined both for a single `(x, t)` point, as well as for a set of points given by `Bounds`.
"""

# ╔═╡ 1cb52b21-8d14-4e2e-ad63-788a56d6bcd2
begin
	is_safe(point) = point[2] <= rwmechanics.t_max
	
	is_safe(bounds::Bounds) = is_safe((bounds.lower[1], bounds.upper[2])) &&
                              is_safe((bounds.upper[1], bounds.upper[2])) &&
                              is_safe((bounds.upper[1], bounds.lower[2])) &&
                              is_safe((bounds.lower[1], bounds.lower[2]))
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
	MArray(outer_bounds.lower .- [0.1, 0.1]),
	MArray(outer_bounds.upper .+ [0.1, 0.1])
)

# ╔═╡ 3b122740-090e-4d74-aa62-8736eba9cad2
outer_bounds.upper .+ [0.1, 0.1]

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
	tree = set_safety!(copy(initial_tree), 
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

# ╔═╡ a8a02260-61d8-4698-9b61-351adaf68f78
bounds = get_bounds(get_leaf(tree, 0.5, 0.5), dimensionality)

# ╔═╡ 826ed80a-bdad-4a38-a50b-cb5bec6216c0
@doc TreeShielding.get_action_safety_bounds

# ╔═╡ 2d999c21-cbdd-4ca6-9866-6f763c91feba
md"""
### `get_dividing_bounds`

$(@doc TreeShielding.get_dividing_bounds)
"""

# ╔═╡ b97cf160-79ab-4cf7-a321-31a86b3bccac
md"""
Also it is possible to control the number of refinement steps in the figures.

`refinement_steps =` $(@bind refinement_steps NumberField(0:9, default=3))

`samples_per_axis_refstep` = $(@bind samples_per_axis_refstep NumberField(3:16, default=3))
"""

# ╔═╡ 15b5d339-705e-4408-9629-2002117b8da7
md"""
### `get_threshold`

$(@doc TreeShielding.get_threshold)
"""

# ╔═╡ 3621e6d2-cfac-43d4-8622-4f99eb4d4090
md"""
And note there is no threshold where all points below it are safe.
"""

# ╔═╡ 648fb8ab-b156-4c75-b0e0-16c8c7f151ec
md"""
### `get_split_by_binary_search`

$(@doc get_split_by_binary_search)
"""

# ╔═╡ 87e24687-5fc2-485a-ba01-41c10c10d395
md"""
### Parameters -- Try it Out!
!!! info "Tip"
	This cell controls multiple figures. Move it around to gain a better view.

Try setting a different number of samples per axis: 

`samples_per_axis =` $(@bind samples_per_axis NumberField(3:30, default=5))

`granularity =` $(@bind granularity NumberField(0:1E-15:1, default=1E-5)) 

`splitting_tolerance =` $(@bind splitting_tolerance NumberField(0:1E-10:1, default=1E-5))
"""

# ╔═╡ 3c613061-1cd9-4b72-b419-6387c25da513
m = ShieldingModel(;simulation_function, action_space=Pace, dimensionality, samples_per_axis, random_variable_bounds, granularity, splitting_tolerance, grow_method=binary_search)

# ╔═╡ 0197dfd6-e689-4aad-8af0-a0cbfa48dfa7
safe, unsafe = TreeShielding.get_action_safety_bounds(tree, bounds, (@set m.samples_per_axis=16))

# ╔═╡ e7609f1e-3d94-4e53-9620-dd62995cfc50
call() do
	leaf = get_leaf(tree, 0.5, 0.5)
	bounds = get_bounds(leaf, dimensionality)
	p1 = draw(tree, draw_bounds, color_dict=action_color_dict,legend=:outerright)
	plot!(size=(800,600), lims=(0.4, 1.1))

	for (a, c) in [(RW.slow, colors.NEPHRITIS), (RW.fast, colors.SUNFLOWER)]
		plot!(TreeShielding.rectangle(safe[a]), 
			label="$a safe", 
			fill=nothing, 
			lw=6,
			lc=c)
	end
	
	for (a, c) in [(RW.slow, colors.NEPHRITIS), (RW.fast, colors.SUNFLOWER)]
		plot!(TreeShielding.rectangle(unsafe[a]), 
			label="$a unsafe", 
			fill=nothing, 
			lw=4,
			ls=:dot,
			lc=c)
	end
	
	scatter_allowed_actions!(tree, bounds, (@set m.samples_per_axis=16))
end

# ╔═╡ c8d182d8-537f-43d7-ab5f-1374219964e8
let
	m = @set m.samples_per_axis = samples_per_axis_refstep
	axis = 1
	leaf = get_leaf(tree, 0.5, 0.5)
	bounds = get_bounds(leaf, dimensionality)
	p1 = draw(tree, draw_bounds, color_dict=action_color_dict,legend=:outerright)
	plot!(size=(800,600))
	scatter_allowed_actions!(tree, bounds, m)

	
	dividing_bounds = bounds
	for i in 0:refinement_steps
		dividing_bounds = 
			TreeShielding.get_dividing_bounds(tree, dividing_bounds, axis, RW.fast, TreeShielding.safe_above_threshold, m)
	
		plot!(TreeShielding.rectangle(dividing_bounds), lw=0, alpha=0.3, label="$i refinements")
	end
	p1
end

# ╔═╡ 2a382ef9-700a-4350-9a95-ff7f1a8f6f22
md"""
For the first axis, (`axis=1`) and the *fast* action, (action=`RW.fast`) find a threshold such that all points above it (`direction=safe_above_threshold`) are safe.

There exists an exact threshold, but we approximate it to within `m.splitting_tolerance =` $(m.splitting_tolerance)
"""

# ╔═╡ 3e6a861b-cbb9-4972-adee-46996faf68f3
threshold = TreeShielding.get_threshold(tree, bounds, 1, RW.fast, TreeShielding.safe_above_threshold, m)

# ╔═╡ c53e43e9-dc81-4b74-b6bd-41f13791f488
call() do
	leaf = get_leaf(tree, 0.5, 0.5)
	bounds = get_bounds(leaf, dimensionality)
	p1 = draw(tree, draw_bounds, color_dict=action_color_dict,legend=:outerright)
	plot!(size=(800,600))
	#draw_support_points!(tree, (0.5, 0.5), RW.fast, m)

	dividing_bounds = bounds
	vline!([threshold], 
		line=(:dot, 5), 
		label="threshold", 
		color=colors.WET_ASPHALT)

end

# ╔═╡ bafe51aa-d791-4d36-939b-159a062a2dd4
@test nothing === TreeShielding.get_threshold(tree, bounds, 1, RW.fast, TreeShielding.safe_below_threshold, m)

# ╔═╡ 53cf3fc9-788c-4700-8b07-fe9118432c84
proposed_split = TreeShielding.get_split_by_binary_search(tree, get_leaf(tree, 0.5, 0.5), m)

# ╔═╡ bae11a44-67d8-4b6b-8d10-85b58e7fae63
call() do
	tree = copy(tree)
	leaf = get_leaf(tree, 0.5, 0.5)
	axis, threshold = proposed_split
	
	split!(leaf, axis, threshold)
	
	draw(tree, draw_bounds, color_dict=action_color_dict, 
		aspectratio=:equal,
		legend=:outertop,
		size=(500,500))
	leaf_count = length(Leaves(tree) |> collect)
	plot!([], l=nothing, label="leaves: $leaf_count")
end

# ╔═╡ da493978-1444-4ec3-be36-4aa1c59170b5
offset = get_spacing_sizes(SupportingPoints(samples_per_axis, bounds), dimensionality)

# ╔═╡ 9e807328-488f-4e86-ae53-71f39b2631a7
md"""
### `grow!`

$(@doc grow!)
"""

# ╔═╡ 46f3eefe-15c7-4bae-acdb-54e485e4b5b7
call() do
	tree = copy(tree)
	
	# Here. #
	grow!(tree, m)
	
	draw(tree, draw_bounds, color_dict=action_color_dict, 
		aspectratio=:equal,
		legend=:outertop,
		size=(500,500))
	
	leaf_count = length(Leaves(tree) |> collect)

	scatter_allowed_actions!(tree, bounds, (@set m.samples_per_axis = 12))
	
	plot!([], l=nothing, 
		label="leaves: $leaf_count",
		title="Result of calling `grow!`")
end

# ╔═╡ 76f13f2a-82cb-4037-a097-394fb080bf84
md"""
# One Split at a Time -- Try it out!
"""

# ╔═╡ 66af047f-a34f-484a-8608-8eaaed45b37d
@bind reset_button Button("Reset")

# ╔═╡ 447dc1e2-809a-4f71-b7f4-949ae2a0c4b6
begin
	reset_button
	reactive_tree = copy(tree)
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

# ╔═╡ 8cc5f9f3-263c-459f-ae78-f2c0e8487e86
if try_splitting_button > 0 && reactive_leaf !== nothing
	call() do
		axis, threshold = TreeShielding.get_split_by_binary_search(reactive_tree, reactive_leaf, (@set m.verbose = true))
		if threshold != nothing
			split!(reactive_leaf, axis, threshold)
		end
		@info "Found result", axis, threshold
	end
end; done_splitting = "Done Splitting";

# ╔═╡ 7f394991-4673-4f32-8c4f-09225822ae95
call() do
	reset_button, try_splitting_button, done_splitting
	
	draw(reactive_tree, draw_bounds, color_dict=action_color_dict, 
		aspectratio=:equal,
		legend=:outerright,
		lims=(draw_bounds.lower[1], draw_bounds.upper[1]))

	if length(reactive_queue) > 0
		bounds = get_bounds(reactive_queue[end], dimensionality)
		plot!(TreeShielding.rectangle(bounds ∩ draw_bounds), 
			label="next in queue",
			linewidth=2,
			linecolor=colors.CONCRETE,
			color=colors.CONCRETE,
			fillalpha=0.3)

		scatter_allowed_actions!(tree::Tree, bounds, m)
	end

	leaf_count = Leaves(reactive_tree) |> collect |> length
	plot!([], line=nothing, label="$leaf_count leaves")
end

# ╔═╡ 8b749715-66a2-4a48-9a78-0462869ea3d0
md"""
---
end
$br
$br
$br
$br
$br
$br
$br
$br
$br
$br
$br
$br
"""

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
# ╟─f14a4efc-1063-4e0d-b968-6c5f46a8c384
# ╠═d043a35e-8092-4306-afbc-e076200e6240
# ╠═7fd00150-0b98-4825-8064-3c805e077206
# ╠═3cee4706-ea98-47b4-aec1-59b27c1cfd0e
# ╟─f0467c66-f1b4-441c-8786-259df7b6403b
# ╠═fca75822-38bc-4cd4-a939-421a950c6859
# ╠═7948d730-203c-4656-bf7a-2b446ac335f7
# ╟─de7fe51c-0f75-49bb-bc6f-726a21bcd064
# ╠═07ed71cc-a931-4785-9707-86aad883df30
# ╟─b1276cfe-4018-4f49-8c43-3e4c622e93f3
# ╠═1cb52b21-8d14-4e2e-ad63-788a56d6bcd2
# ╟─9f9aed0a-66c3-4628-8e7f-cc59374383c9
# ╠═a136ec18-5e84-489b-a13a-ff4ffbb1870d
# ╠═0b6ba501-bc18-4239-b99e-6365b6f5deac
# ╠═3b122740-090e-4d74-aa62-8736eba9cad2
# ╠═b2bc01c9-f501-4c75-8fc4-56dad5cd5c38
# ╠═ee408360-8c64-4619-9810-6038738045dc
# ╠═e9c86cfa-e53f-4c1e-9102-14c821f4232a
# ╟─f2e8855b-95b8-4fcf-bd47-85ec0fdb2a04
# ╠═3c613061-1cd9-4b72-b419-6387c25da513
# ╟─86e9b7f7-f1f5-4ba2-95d6-5e528b1c0ce6
# ╠═a8a02260-61d8-4698-9b61-351adaf68f78
# ╠═826ed80a-bdad-4a38-a50b-cb5bec6216c0
# ╠═0197dfd6-e689-4aad-8af0-a0cbfa48dfa7
# ╟─e7609f1e-3d94-4e53-9620-dd62995cfc50
# ╟─2d999c21-cbdd-4ca6-9866-6f763c91feba
# ╟─b97cf160-79ab-4cf7-a321-31a86b3bccac
# ╠═c8d182d8-537f-43d7-ab5f-1374219964e8
# ╟─15b5d339-705e-4408-9629-2002117b8da7
# ╠═da493978-1444-4ec3-be36-4aa1c59170b5
# ╟─2a382ef9-700a-4350-9a95-ff7f1a8f6f22
# ╠═3e6a861b-cbb9-4972-adee-46996faf68f3
# ╟─3621e6d2-cfac-43d4-8622-4f99eb4d4090
# ╠═bafe51aa-d791-4d36-939b-159a062a2dd4
# ╟─c53e43e9-dc81-4b74-b6bd-41f13791f488
# ╟─648fb8ab-b156-4c75-b0e0-16c8c7f151ec
# ╠═53cf3fc9-788c-4700-8b07-fe9118432c84
# ╟─bae11a44-67d8-4b6b-8d10-85b58e7fae63
# ╟─87e24687-5fc2-485a-ba01-41c10c10d395
# ╟─9e807328-488f-4e86-ae53-71f39b2631a7
# ╟─46f3eefe-15c7-4bae-acdb-54e485e4b5b7
# ╟─76f13f2a-82cb-4037-a097-394fb080bf84
# ╟─66af047f-a34f-484a-8608-8eaaed45b37d
# ╟─447dc1e2-809a-4f71-b7f4-949ae2a0c4b6
# ╟─1817421e-50b0-47b2-859d-e87aaf3064b0
# ╟─7fd058fa-20c2-4b7a-b32d-0a1f806b48ac
# ╟─569efbf8-14da-47a3-b990-88cf223d4b82
# ╟─e21201c8-b043-4214-b8bc-9e7cc2dced6f
# ╟─42d2f87e-ce8b-4928-9d00-b0aa70a18cb5
# ╟─7f394991-4673-4f32-8c4f-09225822ae95
# ╟─8cc5f9f3-263c-459f-ae78-f2c0e8487e86
# ╟─8b749715-66a2-4a48-9a78-0462869ea3d0
