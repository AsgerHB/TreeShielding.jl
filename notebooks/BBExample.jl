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
	TableOfContents()
end

# ╔═╡ 8377c2de-6078-463a-911d-29d1dd0e4138
begin
	@revise using TreeShielding
	using TreeShielding.RW
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

# ╔═╡ 39cd11b7-2428-47ae-b8ec-90459bb03636
dimensionality = 2

# ╔═╡ f9545edd-1621-4b87-89c2-81f25d669613
md"""
### Plotting Convenience Functions
"""

# ╔═╡ 739ac5a1-d9d1-4497-86b0-6fbaf1008c7a
scatter_supporting_points!(s::SupportingPoints) = 
	scatter!(unzip(s), 
		m=(:+, 5, colors.WET_ASPHALT), msw=4, 
		label="supporting points")

# ╔═╡ 4f8c1497-b904-4e44-8a87-4a15c92a4dda
scatter_outcomes!(outcomes) = scatter!(outcomes, m=(:c, 3, colors.ASBESTOS), msw=0, label="outcomes")

# ╔═╡ 76f3e2b3-daaa-4e69-bac7-9cf84857eb86
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

# ╔═╡ 3cdda0dd-59f8-4d6f-b37a-cdc923b242c0
md"""
# Bouncing Ball Functions

The ball it bounce.
"""

# ╔═╡ 3167e418-c88c-45ba-aea9-710ba48a7c97
@enum Action hit nohit

# ╔═╡ 31b93679-82d4-49e5-b47b-45873e4f8452
any_action, no_action = actions_to_int([hit, nohit]) , actions_to_int([])

# ╔═╡ 3bf7051c-a644-427b-bbba-14a69d98f4f5
action_color_dict=Dict(
	any_action => colorant"#ffffff", 
	1 => colorant"#a1eaff", 
	no_action => colorant"#ff9178"
)

# ╔═╡ 9590d625-ad3d-480a-ab1d-a27133457163
function simulate_point(mechanics, v, p, action; min_v_on_impact=1, unlucky=false)
	t_hit, g, β1, ϵ1, β2, ϵ2, v_hit, p_hit  = mechanics
    v0, p0 = v, p
    
    if action == hit && p >= p_hit # Hitting the ball changes the velocity
        if v < 0
            v0 = min(v, v_hit)
        else
			if unlucky
            	v0 = -(β2 - ϵ2)*v + v_hit
			else
				v0 = -rand(β2 - ϵ2:0.01:β2 + ϵ2)*v + v_hit
			end
        end
    end
    
    new_v = g * t_hit + v0
    new_p = 0.5 * g * t_hit^2 + v0*t_hit + p0
    
    if new_p <= 0 # It went through the floor, meaning that a bounce occurs
        t_impact = (-v0 - sqrt(v0^2 - 2*g*p0))/g 
        t_remaining = t_hit - t_impact      # Time left this timestep after bounce occurs
        new_v = g * t_impact + v0        # Gravity pull before impact
		# Impact
		if unlucky
        	new_v = -(β1 - ϵ1)*new_v
		else
        	new_v = -rand(β1 - ϵ1:0.01:β1 + ϵ1)*new_v 
		end
		new_p = 0

		mechanics′ = (t_hit=t_remaining, g, β1, ϵ1, β2, ϵ2, v_hit, p_hit)
		if new_v >= min_v_on_impact
	        new_v, new_p = simulate_point(mechanics′, new_v, new_p, action, min_v_on_impact=min_v_on_impact, unlucky=unlucky)
		else
			new_v, new_p = 0, 0
		end
    end
    
    new_v, new_p
end

# ╔═╡ 8329227c-cbb8-4114-9215-445d604d4a20
function simulate_sequence(mechanics, v0, p0, 
						   policy, duration; 
						   unlucky=false, 
						   min_v_on_impact=1)
	t_hit, g, β1, ϵ1, β2, ϵ2, v_hit, p_hit  = mechanics
    velocities::Vector{Real}, positions::Vector{Real}, times = [v0], [p0], [0.0]
    v, p, t = v0, p0, 0
    while times[end] <= duration - t_hit
        action = policy(v, p)
        v, p = simulate_point(mechanics, v, p, action, 
								unlucky=unlucky,
								min_v_on_impact=min_v_on_impact)
		t += t_hit
        push!(velocities, v)
        push!(positions, p)
        push!(times, t)
    end
    velocities, positions, times
end

# ╔═╡ 1b3f5644-d382-4e61-b3c0-41e0797a0f18
function evaluate(mechanics, policy, duration;
		unlucky=false,
		runs=1000,
		cost_hit=1)
	t_hit, g, β1, ϵ1, β2, ϵ2, v_hit, p_hit  = mechanics
	costs = []
	for run in 1:runs
		v, p = 0, rand(7:10)
		cost = 0
		for i in 1:ceil(duration/t_hit)
			action = policy(v, p)
			cost += action == "hit" ? 1 : 0
			v, p = simulate_point(mechanics, v, p, action, unlucky=unlucky)
		end
		push!(costs, cost)
	end
	sum(costs)/runs
end

# ╔═╡ ef1f2639-617f-4811-8c20-4ebff79f7513
function animate_trace(vs, ps, ts; fps=10, plotargs...)
	
	pmax = maximum(ps)
	tmax = maximum(ts)
	vmin = minimum(vs)
	vmax = maximum(vs)
	layout = 2
	animation = @animate for (i, _) in enumerate(ts)
		p1 = plot(vs[1:i], ps[1:i],
				  xlims=(vmin, vmax), 
				  ylims=(0, pmax),
				  xlabel="v",
				  ylabel="p",
				  color=colors.WET_ASPHALT,
			  	  linewidth=2,
			  	  markersize=2,
			  	  markeralpha=1,
			  	  markershape=:circle)
		hline!([ps[i]], color=colors.NEPHRITIS)
		p2 = plot(ts[1:i], ps[1:i],
				  xlims=(0, tmax), 
				  ylims=(0, pmax),
				  xlabel="t",
				  ylabel="p",
				  color=colors.WET_ASPHALT,
			  	  linewidth=2,
			  	  markersize=2,
			  	  markeralpha=1,
			  	  markershape=:circle)
		hline!([ps[i]], color=colors.NEPHRITIS)
		plot(p1, p2, 
			layout=layout, 
			size=(800, 400), 
			legend=nothing
			;plotargs...)
	end
	
	gif(animation, joinpath(tempdir(), "trace.gif"), fps = fps, show_msg=false)
end

# ╔═╡ b622488e-45be-47fb-8484-4be6b5fe913a
# Default mechancis
bbmechanics = (t_hit = 0.1, g = -9.81, β1 = 0.91, ϵ1 = 0.06, β2 = 0.95, ϵ2 = 0.05, v_hit = -4.0, p_hit = 4.0)

# ╔═╡ 108d281f-e0d7-4b3f-bc6d-ed542aa27aa1
random_policy(hit_chance) = 
	(_, _) -> sample([hit nohit], Weights([hit_chance, 1-hit_chance]), 1)[1]

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

	unsafe_states = Bounds((-1, 0), (1 + eps(), 1))
	replace_subtree!(inside, tree_from_bounds(unsafe_states))
	set_safety!(tree, dimensionality, is_safe, any_action, no_action)
end

# ╔═╡ b8024843-e681-4dde-9af9-1254c0e0d732
draw(initial_tree, outer_bounds, color_dict=action_color_dict)

# ╔═╡ afd89bd1-347e-4792-8f3b-e5b372c649fe
md"""
# Synthesis --  Try it Out!

Change the inputs and click the buttons to see how the parameters affect synthesis, one step at a time.
"""

# ╔═╡ fb359eb9-2ce4-466a-9de8-0a0d691f78b9
@bind reset_button Button("Reset")

# ╔═╡ 142d1db7-183e-45a5-b219-30120ffe437b
begin
	reactive_tree = deepcopy(initial_tree)
	set_safety!(reactive_tree, dimensionality, is_safe, any_action, no_action)
	debounce1, debounce2, debounce3 = Ref(1), Ref(1), Ref(1)
	reset_button
end

# ╔═╡ c277b47d-169c-4d4c-9629-4d84fe74a44c
md"""
Try changing the number of samples per axis, to see how this affects the growth of the tree.

`spa =` $(@bind spa NumberField(1:20, default=5))

And likewise try to adjust the minimum granularity. Defined as the number of leading zeros to the one.

`min_granularity_decimals` $(@bind min_granularity_decimals NumberField(1:15, 3))

`max_grow_iterations` $(@bind max_grow_iterations NumberField(1:20, default=20))
"""

# ╔═╡ c8b29812-4cd6-4929-994b-cb769d2122c9
min_granularity = 10.0^(-min_granularity_decimals)

# ╔═╡ 129fbdb0-88a5-4f3d-82e0-56df43c7a46c
reset_button; @bind go_clock CounterButton("Go!")

# ╔═╡ e7fbb9bb-63b5-4f6a-bb27-7ea1613d6740
go_clock,
if debounce1[] == 1
	debounce1[] += 1
	reactivity1 = "ready"
else
	
	grown = grow!(reactive_tree, 
		dimensionality, 
		simulation_function, 
		Action, 
		spa, 
		min_granularity, 
		max_iterations=max_grow_iterations)

	@info "Grown to $grown leaves"
	
	updates = update!(reactive_tree, dimensionality, simulation_function, Action, spa)
	@info "Updated $updates leaves"
	
	pruned_to = prune!(reactive_tree)
	@info "Pruned to $pruned_to leaves"
	
	reactivity1 = "done"
end

# ╔═╡ 0e18b756-f8a9-4821-8b85-30c908f7e3af
md"""
`show_supporting_points:`
$(@bind show_supporting_points CheckBox(default=true))

`a =` $(@bind a Select(instances(Action) |> collect, default=nohit))

Position: 
$(@bind partition_x 
	NumberField(outer_bounds.lower[1]:0.01:outer_bounds.upper[1], default=0.9))
$(@bind partition_y 
	NumberField(outer_bounds.lower[2]:0.01:outer_bounds.upper[2], default=0.9))
"""

# ╔═╡ 165ba9e0-7409-4f5d-b10b-4223fe589ac6
begin
	reactivity1
	
	p1 = draw(reactive_tree, outer_bounds, 
		color_dict=action_color_dict,
		line=nothing)
	
	plot!(legend=:outerright)

	if show_supporting_points
		p = (partition_x, partition_y)
		draw_support_points!(reactive_tree, dimensionality, simulation_function, Pace, spa, p, a)
		scatter!(p, m=(4, :rtriangle, :white), msw=1, label=nothing, )
	end
	plot!(xlabel="v", ylabel="p")
end

# ╔═╡ 0039a51e-26ed-4ad2-aeda-117436295ca1
md"""
# The Full Loop

Automation is a wonderful thing.
"""

# ╔═╡ 47e04910-d9e9-430f-8cec-bfd584c991e2
@doc synthesize!

# ╔═╡ c92d8cf4-0908-4c7c-8d3d-3dd07972219e
finished_tree = call() do
	spa = 8
	min_granularity = 0.00001
	margin = 0.00000
	max_recursion_depth = 10
	grow_iterations=100
	
	tree = deepcopy(initial_tree)
	
	synthesize!(tree, 
		dimensionality, 
		simulation_function, 
		Action, 
		spa, 
		min_granularity,
		grow_margin=margin,
		max_grow_recursion_depth=max_recursion_depth,
		max_grow_iterations=grow_iterations,
		verbose=true)

	tree
end

# ╔═╡ c42af80d-bb1e-42f7-9131-1080639cbd6a
md"""
Leaves: $(Leaves(finished_tree) |> collect |> length)
"""

# ╔═╡ f113308a-1d72-41e9-ba54-71576994a664
begin
	draw(finished_tree, 
		Bounds(outer_bounds.lower, (outer_bounds.upper[1], outer_bounds.upper[2]+2)), 
		color_dict=action_color_dict,
		line=nothing,
		xlabel="v",
		ylabel="p")
end

# ╔═╡ 60d28d01-7209-477f-b3db-97a5b96dc642
for v in -15:0.01:15
	p = 8
	if get_value(finished_tree, v, p) == 0
		@show v, p
		break
	end
end

# ╔═╡ Cell order:
# ╠═82e532dd-8ec1-458f-b4d6-59cea44dc2b6
# ╠═bdace121-c7a3-48ba-8588-0f68fabf5fea
# ╠═8377c2de-6078-463a-911d-29d1dd0e4138
# ╟─dbdc3329-b95d-42a1-9a98-20ff149bb062
# ╟─5464b116-06fb-4704-bbd5-f7817dce7cbe
# ╟─ef615614-6e22-455b-b9aa-74b1dfbb4f61
# ╟─3bf7051c-a644-427b-bbba-14a69d98f4f5
# ╠═56f10aa2-c768-4936-9a70-76d6b0ec21a1
# ╠═39cd11b7-2428-47ae-b8ec-90459bb03636
# ╟─f9545edd-1621-4b87-89c2-81f25d669613
# ╟─739ac5a1-d9d1-4497-86b0-6fbaf1008c7a
# ╟─4f8c1497-b904-4e44-8a87-4a15c92a4dda
# ╟─76f3e2b3-daaa-4e69-bac7-9cf84857eb86
# ╟─3cdda0dd-59f8-4d6f-b37a-cdc923b242c0
# ╠═3167e418-c88c-45ba-aea9-710ba48a7c97
# ╠═31b93679-82d4-49e5-b47b-45873e4f8452
# ╟─9590d625-ad3d-480a-ab1d-a27133457163
# ╟─8329227c-cbb8-4114-9215-445d604d4a20
# ╟─1b3f5644-d382-4e61-b3c0-41e0797a0f18
# ╟─ef1f2639-617f-4811-8c20-4ebff79f7513
# ╟─b622488e-45be-47fb-8484-4be6b5fe913a
# ╠═108d281f-e0d7-4b3f-bc6d-ed542aa27aa1
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
# ╟─afd89bd1-347e-4792-8f3b-e5b372c649fe
# ╟─fb359eb9-2ce4-466a-9de8-0a0d691f78b9
# ╟─142d1db7-183e-45a5-b219-30120ffe437b
# ╟─c277b47d-169c-4d4c-9629-4d84fe74a44c
# ╟─c8b29812-4cd6-4929-994b-cb769d2122c9
# ╟─129fbdb0-88a5-4f3d-82e0-56df43c7a46c
# ╠═e7fbb9bb-63b5-4f6a-bb27-7ea1613d6740
# ╟─0e18b756-f8a9-4821-8b85-30c908f7e3af
# ╠═165ba9e0-7409-4f5d-b10b-4223fe589ac6
# ╟─0039a51e-26ed-4ad2-aeda-117436295ca1
# ╠═47e04910-d9e9-430f-8cec-bfd584c991e2
# ╠═c92d8cf4-0908-4c7c-8d3d-3dd07972219e
# ╟─c42af80d-bb1e-42f7-9131-1080639cbd6a
# ╠═f113308a-1d72-41e9-ba54-71576994a664
# ╠═60d28d01-7209-477f-b3db-97a5b96dc642
# ╠═8d1cc07c-a529-4135-b92a-c24845009461
# ╠═8918db4a-8814-46f9-b74f-7e48205f9df1
# ╠═bda061b8-f809-4924-b60d-4f2eff419ef9
# ╠═7a1911c2-9eb1-41ea-8894-e4c53117d8eb
# ╠═752b7b36-df02-4581-913b-9902c750b1b2