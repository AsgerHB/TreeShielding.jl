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

# ╔═╡ bdace121-c7a3-48ba-8588-0f68fabf5fea
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
	using StatsBase
	using Setfield
	TableOfContents()
end

# ╔═╡ 8377c2de-6078-463a-911d-29d1dd0e4138
begin
	@revise using TreeShielding
	using TreeShielding.BB
end

# ╔═╡ 82e532dd-8ec1-458f-b4d6-59cea44dc2b6
md"""
# Bouncing Ball Example
This notebook applies the package to a non-trivial example.
"""

# ╔═╡ dbdc3329-b95d-42a1-9a98-20ff149bb062
md"""
## Preliminaries
"""

# ╔═╡ 5464b116-06fb-4704-bbd5-f7817dce7cbe
md"""
### Colors
"""

# ╔═╡ ef615614-6e22-455b-b9aa-74b1dfbb4f61
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

# ╔═╡ 56f10aa2-c768-4936-9a70-76d6b0ec21a1
call(f) = f()

# ╔═╡ 1feb5107-1587-495d-8024-160f9cc68447
md"""
# The ShieldingModel

Everything is rolled up into a convenient little ball that is easy to toss around between functions. This ball is called `ShieldingModel`
"""

# ╔═╡ 4f55da12-5f81-484f-970a-691336e6e58f
no_action, any_action = actions_to_int([]), actions_to_int(instances(Action))

# ╔═╡ 3bf7051c-a644-427b-bbba-14a69d98f4f5
action_color_dict=Dict(
	any_action => colorant"#ffffff", 
	1 => colorant"#a1eaff", 
	2 => colors.AMETHYST,
	no_action => colorant"#ff9178"
)

# ╔═╡ 39cd11b7-2428-47ae-b8ec-90459bb03636
dimensionality = 2

# ╔═╡ 3cdda0dd-59f8-4d6f-b37a-cdc923b242c0
md"""
## Bouncing Ball Functions

The ball it bounce.
"""

# ╔═╡ 96155a32-5e05-4632-9fe8-e843970e3089
animate_trace(simulate_sequence(bbmechanics, 0, 7, random_policy(0.1), 10)...)

# ╔═╡ 7e0de76c-8a0e-46aa-a098-b5f0e8fd32b5
md"""
## Wrapping up the Simulation Function

The state will be saved as a `(velocity, position)` tuple.

The kwarg `min_v_on_impact=1` makes the ball come to a stop `(0,0)` if it impacts the ground at less than $1^m/{}_s$

The kwarg `unlucky=true` will tell the function to pick the worst-case outcome, i.e. the one where the ball preserves the least amount of power on impact. 

!!! info "TODO"
	Model random outcomes as an additional dimension, removing the need for assumptions about a "worst-case" outcome.
"""

# ╔═╡ 1cc57555-e687-4b84-9568-c7eb903f57ef
simulation_function(s, a) = 
	simulate_point(bbmechanics, s..., a, unlucky=true, min_v_on_impact=1)

# ╔═╡ d772354b-b855-4d4e-b768-2200c03cc0d6
simulation_function((0, 7), hit)

# ╔═╡ cd82ff88-3e88-4a94-b414-abca02a55217
simulation_function((0.1, 0), hit)

# ╔═╡ 33aae1b2-cffb-44f7-9b19-5c5b682473ed
md"""
## Safety Property

The ball should never "come to a stop." However, coming to a stop includes doing an infinite amount of bounces in a finite amount of time, until the velocity becomes zero.

In practice, this means it should bounce back with more than $1^m/{}_s$. 
"""

# ╔═╡ f86a0e8b-9d76-4e68-91cf-927595c27387
begin
	is_safe(state) = abs(state[1]) > 1 || state[2] > 0
	is_safe(bounds::Bounds) = is_safe((bounds.lower[1], bounds.lower[2]))
end

# ╔═╡ caa90ceb-0435-40b7-a97d-74919b040002
@test !is_safe((0, 0))

# ╔═╡ ac0047af-ce08-4131-915c-efd380884b73
@test is_safe((0, 10))

# ╔═╡ b7843c6f-066d-473c-ad6c-a693b4601aad
@test !is_safe((0.1, 0))

# ╔═╡ 6012912a-2477-41e4-8cc7-65cea9911d8c
@test !is_safe(Bounds((0, 0) , (1, 10)))

# ╔═╡ 8603cb3e-6639-4664-b923-8db14c264eda
@test is_safe(Bounds((0, 1) , (1, 10)))

# ╔═╡ 0a267aab-98d7-4ee5-a907-29d54e2a09f0
md"""
# Applying Everything we Learned
"""

# ╔═╡ 40b843de-e367-49d7-8a50-d2cefe4e3939
outer_bounds = Bounds((-15, 0), (15, 10))

# ╔═╡ c8b40bd6-a8f3-42e8-bcbb-5bddd452dab0
initial_tree = call() do
	tree = tree_from_bounds(outer_bounds)
	inside = get_leaf(tree, 0, 0)

	unsafe_states = Bounds((-1, 0), (1 + 0.001, 1))
	replace_subtree!(inside, tree_from_bounds(unsafe_states))
	set_safety!(tree, dimensionality, is_safe, any_action, no_action)
end

# ╔═╡ b8024843-e681-4dde-9af9-1254c0e0d732
draw(initial_tree, outer_bounds, color_dict=action_color_dict)

# ╔═╡ 454f91d1-3e42-4424-a594-3bc35528d4d8
md"""
# One Split at a Time -- Try it out!
"""

# ╔═╡ baa640a5-7a21-483b-87a4-f112cfe48d2b
@bind reset_button1 Button("Reset")

# ╔═╡ 3e0e5c6f-e57c-41f2-9869-64f0e3bf2a8a
begin
	reset_button1
	reactive_tree1 = deepcopy(initial_tree)
end;

# ╔═╡ 0c99bd95-0c3e-46b7-bd27-70ac8bb605cf
begin
	reset_button1
	@bind refill_queue_button CounterButton("Refill Queue")
end

# ╔═╡ e293633b-81b9-4d82-8960-e4559f454905
begin
	refill_queue_button
	reactive_queue = collect(Leaves(reactive_tree1))
end;

# ╔═╡ 24354fb4-c782-4634-81c8-d2572063a77e
["Leaf($(leaf.value))" for leaf in reactive_queue]

# ╔═╡ 08d82e7a-85bd-4e5c-bc27-32f521fbb1fc
begin
	reset_button1
	@bind try_splitting_button CounterButton("Try Splitting")
end

# ╔═╡ c067c6df-2f1b-408d-aacd-104554038102
begin
	reset_button1, try_splitting_button
	if length(reactive_queue) == 0
		[push!(reactive_queue, leaf) for leaf in collect(Leaves(reactive_tree1))]
	end
	reactive_leaf = pop!(reactive_queue)
	if length(reactive_queue) == 0
		[push!(reactive_queue, leaf) for leaf in collect(Leaves(reactive_tree1))]
	end
	"Next: Leaf($(reactive_queue[end].value))"
end

# ╔═╡ afd89bd1-347e-4792-8f3b-e5b372c649fe
md"""
# Synthesis --  Try it Out!

Change the inputs and click the buttons to see how the parameters affect synthesis, one step at a time.
"""

# ╔═╡ 0e18b756-f8a9-4821-8b85-30c908f7e3af
md"""
`show_supporting_points:`
$(@bind show_supporting_points CheckBox(default=true))

`zoom_in`
$(@bind zoom_in CheckBox(default=false))

`a =` $(@bind a Select(instances(Action) |> collect, default=nohit))

Position: 
$(@bind partition_x 
	NumberField(outer_bounds.lower[1]:0.01:outer_bounds.upper[1], default=0.9))
$(@bind partition_y 
	NumberField(outer_bounds.lower[2]:0.01:outer_bounds.upper[2], default=0.9))
"""

# ╔═╡ cd190e4a-9e48-4e6a-8058-1bcb105d9c0b
# ╠═╡ disabled = true
#=╠═╡
# Cell that does grow/update until it is about to create a vertical red bar
begin
	borked_bounds = nothing
	for i in 1:100
		grow!(reactive_tree, m)
		updates = TreeShielding.get_updates(reactive_tree, m)
	
		for update in updates
			if get_bounds(update.leaf, m.dimensionality).upper[2] == outer_bounds.upper[2] &&
				update.new_value == 0

				global borked_bounds = get_bounds(update.leaf, m.dimensionality)
				@warn "It's about to bork. $(borked_bounds)"
				
				@goto break_all
			end
		end
		TreeShielding.apply_updates!(updates)
	end
	@info "Didn't bork."
	@label break_all
end
  ╠═╡ =#

# ╔═╡ 57be14bb-d748-4432-8608-106c44c38f83
md"""
### Set the parameters -- Try it Out
Try setting a different number of samples per axis: 

`samples_per_axis =` $(@bind samples_per_axis NumberField(3:30, default=3))

`max_iterations =` $(@bind max_iterations NumberField(1:1000, default=20))

And configure min granularity. The value is set as the number of leading zeros to the first digit.

`min_granularity =` $(@bind min_granularity NumberField(0:1E-10:1, default=1E-8))


`margin =` $(@bind margin NumberField(0:0.001:1, default=0.00))

`splitting_tolerance =` $(@bind splitting_tolerance NumberField(0:1E-10:1, default=1E-5))
"""

# ╔═╡ f878ebd6-b261-4151-8aae-521b6736b28a
m = ShieldingModel(simulation_function, Action, dimensionality, samples_per_axis; max_iterations, min_granularity, margin, splitting_tolerance)

# ╔═╡ 42b0bcee-b931-4bad-9b4b-268f6b3d260c
if try_splitting_button > 0 && reactive_leaf !== nothing
	call() do
		axis, threshold = get_split(reactive_tree1, reactive_leaf, (@set m.verbose = true))
		if threshold != nothing
			split!(reactive_leaf, axis, threshold)
		end
		axis, threshold
	end
end; done_splitting = "Done Splitting";

# ╔═╡ 573a7989-6a88-47b7-8d2b-17cc605b76ea
call() do
	reset_button1, try_splitting_button, done_splitting
	
	draw(reactive_tree1, outer_bounds, color_dict=action_color_dict,
		legend=:outerright,
		xlims=(outer_bounds.lower[1], outer_bounds.upper[1]),
		ylims=(outer_bounds.lower[2], outer_bounds.upper[2]),
	)

	if length(reactive_queue) > 0
		bounds = get_bounds(reactive_queue[end], dimensionality)
		plot!(TreeShielding.rectangle(bounds ∩ outer_bounds), 
			label="next in queue",
			linewidth=4,
			linecolor=colors.PETER_RIVER,
			color=colors.CONCRETE,
			fillalpha=0.3)

		if bounded(bounds)
			scatter_allowed_actions!(reactive_tree1::Tree, bounds, m)
		end
	end

	leaf_count = Leaves(reactive_tree1) |> collect |> length
	plot!([], line=nothing, label="$leaf_count leaves")
end

# ╔═╡ fb359eb9-2ce4-466a-9de8-0a0d691f78b9
m; @bind reset_button Button("Reset")

# ╔═╡ 142d1db7-183e-45a5-b219-30120ffe437b
begin
	reactive_tree = deepcopy(initial_tree)
	set_safety!(reactive_tree, dimensionality, is_safe, any_action, no_action)
	debounce1, debounce2, debounce3 = Ref(1), Ref(1), Ref(1)
	reset_button
end

# ╔═╡ 129fbdb0-88a5-4f3d-82e0-56df43c7a46c
reset_button; @bind go_clock CounterButton("Go!")

# ╔═╡ e7fbb9bb-63b5-4f6a-bb27-7ea1613d6740
go_clock,
if debounce1[] == 1
	debounce1[] += 1
	"ready"
else
	
	grown = grow!(reactive_tree, m)

	# @info "Grown to $grown leaves"
	
	updates = update!(reactive_tree, m)
	# @info "Updated $updates leaves"
	
	pruned_to = prune!(reactive_tree)
	# @info "Pruned to $pruned_to leaves"
	
	"done"
end

# ╔═╡ c7c48e96-77d5-4c98-a420-39c929130704
# Cell that does grow/update until it is about to create a vertical red bar
begin
	for i in 1:10
		grow!(reactive_tree, m)
		updates = TreeShielding.get_updates(reactive_tree, m)
		if length(updates) == 0
			@info "All done."
			break
		end
		TreeShielding.apply_updates!(updates)
	end
	@info "More work to do."
end

# ╔═╡ e0013651-12ed-4c81-ad05-2eb8f47a720c
reset_button, go_clock; Leaves(reactive_tree) |> collect |> length

# ╔═╡ 0837b974-a284-488d-9d6c-b21eb4a6aecf
#=╠═╡
l = get_leaf(reactive_tree, 
	borked_bounds.upper[1] - 0.0000001, 
	borked_bounds.upper[2] - 0.0000001)
  ╠═╡ =#

# ╔═╡ 29f7f0ce-e3e6-4071-bdfe-a6da3994dd85
l = get_leaf(reactive_tree, partition_x, partition_y)

# ╔═╡ ef651fce-cdca-4ca1-9f08-e94fd25df4a4
go_clock; b = get_bounds(l, m.dimensionality)

# ╔═╡ 165ba9e0-7409-4f5d-b10b-4223fe589ac6
begin
	reset_button, go_clock
	
	p1 = draw(reactive_tree, outer_bounds, 
		color_dict=action_color_dict,
		line=nothing
	)
	
	plot!(legend=:outerright)

	if show_supporting_points
		p = (partition_x, partition_y)
		scatter_allowed_actions!(reactive_tree, b,  m)
		scatter!(p, m=(4, :rtriangle, :white), msw=1, label=nothing, )
	end

	if zoom_in
		plot!(xlims=(b.lower[1] - 0.5, b.upper[1] + 0.5),
		      ylims=(b.lower[2] - 0.5, b.upper[2] + 0.5),)
	end

	hline!([bbmechanics.p_hit], c=colors.WET_ASPHALT, label="phit")
	
	plot!(xlabel="v", ylabel="p")
end

# ╔═╡ 7f560461-bfc7-4419-8a27-670b09830052
TreeShielding.get_allowed_actions(reactive_tree, b, (@set m.verbose = true))

# ╔═╡ f3edc169-94ff-4560-874c-05aab6f8782c
TreeShielding.compute_safety(reactive_tree, SupportingPoints(m.samples_per_axis, b), m)

# ╔═╡ f204e821-45d4-4518-8cd6-4a6ab3963460
go_clock; get_split(reactive_tree, l, (@set m.verbose=true))

# ╔═╡ 6bcff92a-941f-491c-99d1-2b50a4a94231
default = 2.55850

# ╔═╡ 6569a86b-4001-4e99-849e-c92ebcea47dd
m.min_granularity

# ╔═╡ 5a7e7e50-7485-4479-9873-98b2729e2f74
lower = 2.55839

# ╔═╡ 4e82ec51-6a75-456d-a801-721331c6c156
default - lower

# ╔═╡ 7889f07f-0234-48d0-87cc-4830e62e68b1
updated = max(default, lower + min_granularity)

# ╔═╡ 8a13e8b2-3e8a-471b-9f71-22fe3dc0e46b
updated - lower

# ╔═╡ ec1628b6-9dd3-43a6-aa10-01f9743ce0ea
go_clock; action_color_dict[l.value]

# ╔═╡ 0039a51e-26ed-4ad2-aeda-117436295ca1
md"""
# The Full Loop

Automation is a wonderful thing.
"""

# ╔═╡ 47e04910-d9e9-430f-8cec-bfd584c991e2
@doc synthesize!

# ╔═╡ 1d3ec97f-1818-48dc-9357-35da2a8d6a9d
m; @bind synthesize_button CounterButton("Synthesize")

# ╔═╡ ecf49f25-1ea4-48be-a391-c8f4c1012c6f
safety_strategy = deepcopy(initial_tree);

# ╔═╡ c92d8cf4-0908-4c7c-8d3d-3dd07972219e
if synthesize_button > 0
	synthesize!(safety_strategy, m)
end

# ╔═╡ c42af80d-bb1e-42f7-9131-1080639cbd6a
md"""
Leaves: $(Leaves(safety_strategy) |> collect |> length)
"""

# ╔═╡ f113308a-1d72-41e9-ba54-71576994a664
if safety_strategy !== nothing
	draw(safety_strategy, 
		Bounds(outer_bounds.lower, (outer_bounds.upper[1], outer_bounds.upper[2]+2)), 
		color_dict=action_color_dict,
		line=nothing,
		xlabel="v",
		ylabel="p")
end

# ╔═╡ 629440a0-3ec7-4204-9f27-6575334aae3c
if safety_strategy !== nothing
	safety_strategy_buffer = IOBuffer()
	robust_serialize(safety_strategy_buffer, safety_strategy)
end

# ╔═╡ b338748b-0801-474f-9a79-5d794e88d15c
safety_strategy !== nothing &&
DownloadButton(safety_strategy_buffer, "safety strategy.tree")

# ╔═╡ 3caf3b3d-42e9-42e8-8fc8-62cc6cb08d3a
function shield(tree::Tree, policy)
    return (p) -> begin
		a = policy(p)
        allowed = int_to_actions(Action, get_value(tree, p))
        if a ∈ allowed
            return a
        elseif length(allowed) > 0
            return rand(allowed)
        else
            return hit
        end
    end
end

# ╔═╡ 18d7baa2-4af2-4c06-a0ba-cc8d1a16da97
hits_rarely = random_policy(0.05)

# ╔═╡ 51e0f06e-d317-4325-8473-76b195457469
shield(safety_strategy, hits_rarely)((7, 0))

# ╔═╡ a0ecb865-b8f6-471c-b32b-80e376792ecd
check_safety(bbmechanics, (x, y) -> shield(safety_strategy, hits_rarely), 120, runs=1000)

# ╔═╡ 25d4797d-293d-449d-984f-c1d7d830dfaa
md"""
# Scratchpad
"""

# ╔═╡ eba405af-7cf2-4a19-85ba-6750e3ccdef0


# ╔═╡ Cell order:
# ╠═82e532dd-8ec1-458f-b4d6-59cea44dc2b6
# ╠═bdace121-c7a3-48ba-8588-0f68fabf5fea
# ╠═8377c2de-6078-463a-911d-29d1dd0e4138
# ╟─dbdc3329-b95d-42a1-9a98-20ff149bb062
# ╟─5464b116-06fb-4704-bbd5-f7817dce7cbe
# ╟─ef615614-6e22-455b-b9aa-74b1dfbb4f61
# ╠═3bf7051c-a644-427b-bbba-14a69d98f4f5
# ╠═56f10aa2-c768-4936-9a70-76d6b0ec21a1
# ╟─1feb5107-1587-495d-8024-160f9cc68447
# ╠═4f55da12-5f81-484f-970a-691336e6e58f
# ╠═39cd11b7-2428-47ae-b8ec-90459bb03636
# ╠═f878ebd6-b261-4151-8aae-521b6736b28a
# ╟─3cdda0dd-59f8-4d6f-b37a-cdc923b242c0
# ╠═96155a32-5e05-4632-9fe8-e843970e3089
# ╟─7e0de76c-8a0e-46aa-a098-b5f0e8fd32b5
# ╠═1cc57555-e687-4b84-9568-c7eb903f57ef
# ╠═d772354b-b855-4d4e-b768-2200c03cc0d6
# ╠═cd82ff88-3e88-4a94-b414-abca02a55217
# ╟─33aae1b2-cffb-44f7-9b19-5c5b682473ed
# ╠═f86a0e8b-9d76-4e68-91cf-927595c27387
# ╠═caa90ceb-0435-40b7-a97d-74919b040002
# ╠═ac0047af-ce08-4131-915c-efd380884b73
# ╠═b7843c6f-066d-473c-ad6c-a693b4601aad
# ╠═6012912a-2477-41e4-8cc7-65cea9911d8c
# ╠═8603cb3e-6639-4664-b923-8db14c264eda
# ╟─0a267aab-98d7-4ee5-a907-29d54e2a09f0
# ╠═40b843de-e367-49d7-8a50-d2cefe4e3939
# ╠═c8b40bd6-a8f3-42e8-bcbb-5bddd452dab0
# ╠═b8024843-e681-4dde-9af9-1254c0e0d732
# ╟─454f91d1-3e42-4424-a594-3bc35528d4d8
# ╟─baa640a5-7a21-483b-87a4-f112cfe48d2b
# ╟─3e0e5c6f-e57c-41f2-9869-64f0e3bf2a8a
# ╟─0c99bd95-0c3e-46b7-bd27-70ac8bb605cf
# ╟─e293633b-81b9-4d82-8960-e4559f454905
# ╟─24354fb4-c782-4634-81c8-d2572063a77e
# ╟─08d82e7a-85bd-4e5c-bc27-32f521fbb1fc
# ╟─c067c6df-2f1b-408d-aacd-104554038102
# ╟─573a7989-6a88-47b7-8d2b-17cc605b76ea
# ╟─42b0bcee-b931-4bad-9b4b-268f6b3d260c
# ╟─afd89bd1-347e-4792-8f3b-e5b372c649fe
# ╟─fb359eb9-2ce4-466a-9de8-0a0d691f78b9
# ╟─142d1db7-183e-45a5-b219-30120ffe437b
# ╟─129fbdb0-88a5-4f3d-82e0-56df43c7a46c
# ╟─e7fbb9bb-63b5-4f6a-bb27-7ea1613d6740
# ╟─0e18b756-f8a9-4821-8b85-30c908f7e3af
# ╠═cd190e4a-9e48-4e6a-8058-1bcb105d9c0b
# ╠═c7c48e96-77d5-4c98-a420-39c929130704
# ╟─165ba9e0-7409-4f5d-b10b-4223fe589ac6
# ╟─57be14bb-d748-4432-8608-106c44c38f83
# ╠═e0013651-12ed-4c81-ad05-2eb8f47a720c
# ╠═0837b974-a284-488d-9d6c-b21eb4a6aecf
# ╠═29f7f0ce-e3e6-4071-bdfe-a6da3994dd85
# ╠═ef651fce-cdca-4ca1-9f08-e94fd25df4a4
# ╠═7f560461-bfc7-4419-8a27-670b09830052
# ╠═f3edc169-94ff-4560-874c-05aab6f8782c
# ╠═f204e821-45d4-4518-8cd6-4a6ab3963460
# ╠═6bcff92a-941f-491c-99d1-2b50a4a94231
# ╠═6569a86b-4001-4e99-849e-c92ebcea47dd
# ╠═5a7e7e50-7485-4479-9873-98b2729e2f74
# ╠═4e82ec51-6a75-456d-a801-721331c6c156
# ╠═7889f07f-0234-48d0-87cc-4830e62e68b1
# ╠═8a13e8b2-3e8a-471b-9f71-22fe3dc0e46b
# ╠═ec1628b6-9dd3-43a6-aa10-01f9743ce0ea
# ╟─0039a51e-26ed-4ad2-aeda-117436295ca1
# ╠═47e04910-d9e9-430f-8cec-bfd584c991e2
# ╟─1d3ec97f-1818-48dc-9357-35da2a8d6a9d
# ╠═ecf49f25-1ea4-48be-a391-c8f4c1012c6f
# ╠═c92d8cf4-0908-4c7c-8d3d-3dd07972219e
# ╟─c42af80d-bb1e-42f7-9131-1080639cbd6a
# ╠═f113308a-1d72-41e9-ba54-71576994a664
# ╠═629440a0-3ec7-4204-9f27-6575334aae3c
# ╠═b338748b-0801-474f-9a79-5d794e88d15c
# ╠═3caf3b3d-42e9-42e8-8fc8-62cc6cb08d3a
# ╠═18d7baa2-4af2-4c06-a0ba-cc8d1a16da97
# ╠═51e0f06e-d317-4325-8473-76b195457469
# ╠═a0ecb865-b8f6-471c-b32b-80e376792ecd
# ╟─25d4797d-293d-449d-984f-c1d7d830dfaa
# ╠═eba405af-7cf2-4a19-85ba-6750e3ccdef0
