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
	TableOfContents()
end

# ╔═╡ 06791d29-7dbd-4487-8448-cc84a1631025
begin
	@revise using TreeShielding
	using TreeShielding.RW
end

# ╔═╡ 137adf90-a162-11ed-358b-6fc69c09feba
md"""
# Growing the tree
This notebook demonstrates the `grow!` function. Scroll to the bottom to see it in action, or read from the beginning to get the full context of what it does.
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

# ╔═╡ f3dd8d47-d582-4e76-ba7c-8975280eb273
md"""
### Plotting Convenience Functions
"""

# ╔═╡ 4a2cc218-1278-48a2-8e8e-2deabc664802
scatter_supporting_points!(s::SupportingPoints) = 
	scatter!(unzip(s), 
		m=(:+, 5, colors.WET_ASPHALT), msw=4, 
		label="supporting points")

# ╔═╡ a8b53549-5de6-43c8-983d-43e8ca1520da
scatter_outcomes!(outcomes) = scatter!(outcomes, m=(:c, 3, colors.ASBESTOS), msw=0, label="outcomes")

# ╔═╡ 4fe2ab4a-6bc3-40a1-9aed-b702a0fcdf69
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
	any_action => colorant"#ffffff", 
	1 => colorant"#a1eaff", 
	no_action => colorant"#ff9178"
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

# ╔═╡ de7fe51c-0f75-49bb-bc6f-726a21bcd064
md"""
The function for taking a single step needs to be wrapped up, so that it only takes the arguments `point` and `action`.

The kwarg `unlucky=true` will tell the function to pick the worst-case outcome, i.e. the one where the ball preserves the least amount of power on impact. 

!!! info "TODO"
	Model random outcomes as an additional dimension, removing the need for assumptions about a "worst-case" outcome.
"""

# ╔═╡ 07ed71cc-a931-4785-9707-86aad883df30
simulation_function(point, action) = RW.simulate(
	rwmechanics, 
	point[1], 
	point[2], 
	action,
	unlucky=true)

# ╔═╡ ef8dcaa1-4e61-450e-af1e-7cd54e7507f3
md"""
The goal of the game is to reach `x >= x_max` without reaching `t >= t_max`. 

This corresponds to the below safety property. It is defined both for a single `(x, t)` point, as well as for a set of points given by `Bounds`.
"""

# ╔═╡ 1cb52b21-8d14-4e2e-ad63-788a56d6bcd2
begin
	is_safe(point) = point[2] <= rwmechanics.t_max
	is_safe(bounds::Bounds) = is_safe((bounds.lower[1], bounds.upper[2]))
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
	outer_bounds.lower .- [0.5, 0.5],
	outer_bounds.upper .+ [0.5, 0.5]
)

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
	tree = set_safety!(deepcopy(initial_tree), 
		dimensionality, 
		is_safe, 
		any_action, 
		no_action)

	# Modification to make the split more interesting
	replace_subtree!(get_leaf(tree, 1.1, 1.1), Leaf(any_action))
end

# ╔═╡ e9c86cfa-e53f-4c1e-9102-14c821f4232a
draw(tree, draw_bounds, color_dict=action_color_dict, aspectratio=:equal)

# ╔═╡ 86e9b7f7-f1f5-4ba2-95d6-5e528b1c0ce6
md"""
## Where to Split

Get ready to read some cursed code.
"""

# ╔═╡ 0840b06f-246a-4d62-bf07-2ab9a1cc1e26
md"""

### `safety_bounds`
The function finds the minima and maxima for the sets of safe support ponits, and the same for the unsafe support points.

These bounds are used to compute where a split can be made, such that there are only safe supporting points at one side of the split.
"""

# ╔═╡ 4455372a-5d12-4a35-bc43-97dcc5719f6c
function safety_bounds(tree, bounds, 
	simulation_function, 
    action_space,
    samples_per_axis)

	no_action = actions_to_int([])
	dimensionality = get_dim(bounds)

	min_safe = [Inf for _ in 1:dimensionality]
	max_safe = [-Inf for _ in 1:dimensionality]
	min_unsafe = [Inf for _ in 1:dimensionality]
	max_unsafe = [-Inf for _ in 1:dimensionality]

	for point in SupportingPoints(samples_per_axis, bounds)
		safe = false
		for action in instances(action_space)
			point′ = simulation_function(point, action)
			if get_value(tree, point′) != no_action
				safe = true
			end
		end

		if safe
			for axis in 1:dimensionality
				if min_safe[axis] > point[axis]
					min_safe[axis] = point[axis]
				end
				if max_safe[axis] < point[axis]
					max_safe[axis] = point[axis]
				end
			end
		else
			for axis in 1:dimensionality
				if min_unsafe[axis] > point[axis]
					min_unsafe[axis] = point[axis]
				end
				if max_unsafe[axis] < point[axis]
					max_unsafe[axis] = point[axis]
				end
			end
		end
	end

	safe, unsafe = Bounds(min_safe, max_safe), Bounds(min_unsafe, max_unsafe)
end

# ╔═╡ 2d999c21-cbdd-4ca6-9866-6f763c91feba
md"""
### `get_dividing_bounds`

Recursively finds the best threshold, such that all points to one side of it are safe.

Taking as its arguments a set of bounds and the variables required to define supporting points, it computes the safe and unsafe states from the supporting points.

Then it returns the area between the last set of safe supporting points, and the unsafe ones. This is easiest to see in a notebook.

However, if no such bound exists, it returns `nothing`
"""

# ╔═╡ ed0def9c-15a3-41a2-b266-849d4a382a69
function get_dividing_bounds(tree, 
	bounds,
	simulation_function, 
	action_space, 
	samples_per_axis,
	axis;
	max_recursion_depth=5,
	verbose=false)

	dimensionality = get_dim(bounds)
	
	offset = get_spacing_sizes(SupportingPoints(samples_per_axis, bounds), 
		dimensionality)
	
	safe, unsafe = safety_bounds(tree, 
		bounds,
		simulation_function,
		action_space,
		samples_per_axis)

	verbose && @info "safe: $safe \nunsafe: $unsafe"

	if !bounded(safe)
		@warn "No safe points found in partition."
		return nothing, nothing
	elseif !bounded(unsafe)
		verbose && @info "No unsafe points found in partition."
		return nothing, nothing
	end

	threshold = nothing
	safe_above = nothing
	bounds′ = deepcopy(bounds)
	
	if unsafe.lower[axis]  - offset[axis] > safe.lower[axis] ||
			unsafe.lower[axis]  - offset[axis] ≈ safe.lower[axis]
		
		threshold = unsafe.lower[axis] - offset[axis]
		safe_above = false
		
		bounds′.lower[axis] = threshold
		bounds′.upper[axis] = threshold + offset[axis]
		
	elseif unsafe.upper[axis]  + offset[axis] < safe.upper[axis] ||
			unsafe.upper[axis]  + offset[axis] ≈ safe.upper[axis]
		
		threshold = unsafe.upper[axis] + offset[axis]
		safe_above = true
		
		bounds′.lower[axis] = threshold - offset[axis]
		bounds′.upper[axis] = threshold
	else
		return nothing, nothing
	end
	
	if max_recursion_depth < 1 
		verbose && @info "Found dividing bounds $bounds′"
		return safe_above, bounds′
	end
	return something(
		get_dividing_bounds(tree,
					bounds′,
					simulation_function,
					action_space,
					samples_per_axis,
					axis,
					max_recursion_depth=max_recursion_depth - 1),
		(safe_above, bounds′)
	)
end

# ╔═╡ 15b5d339-705e-4408-9629-2002117b8da7
md"""
### `get_threshold`

Find a threshold along any axis, such that to one side all points are safe.
"""

# ╔═╡ 394d5768-951b-418c-ab87-367a9b9b90ad
function get_threshold(tree, 
	bounds,
	simulation_function, 
	action_space, 
	samples_per_axis,
	min_granularity;
	max_recursion_depth=5,
	verbose=false)

	for axis in 1:dimensionality
		safe_above, dividing_bounds = get_dividing_bounds(tree, 
			bounds,
			simulation_function, 
			action_space, 
			samples_per_axis,
			axis; 
			max_recursion_depth,
			verbose)
		
	
		if safe_above === nothing
			continue
		elseif safe_above
			threshold = dividing_bounds.upper[axis]
		else
			threshold = dividing_bounds.lower[axis]
		end

		lower, upper = bounds.lower[axis], bounds.upper[axis]
		if  abs(threshold - lower) < min_granularity ||
			abs(threshold - upper) < min_granularity
			verbose && @info "Skipped a split that went below min_granularity."
			continue
		end

		return axis, threshold
	end

	return nothing, nothing
end

# ╔═╡ a8a02260-61d8-4698-9b61-351adaf68f78
bounds = get_bounds(get_leaf(tree, 0.5, 0.5), dimensionality)

# ╔═╡ 648fb8ab-b156-4c75-b0e0-16c8c7f151ec
"""
    try_splitting!(leaf::Leaf, 
    dimensionality, 
    simulation_function, 
    action_space,
    samples_per_axis,
    min_granularity)


Makes calls to `get_splitting_point` for each axis, and performs the first split which can be made. The split can be made if 

 - The leaf has at least one safe action it can take. Splitting unsafe partitions is useless.
 - The leaf is properly bounded. That is, its bounds are finite on all axes.
 - `get_splitting_point` returns something other than `nothing`, i.e. there exists a thereshold such that all points are safe on one side of it.
 - The threshold would not create a bound whose size is smaller than `min_granularity`.
   
**Returns:** `true` if a split is made, and `false` otherwise.

**Args:**
 - `leaf` This leaf will be split at the first axis where a division can be made between safe and unsafe points.
 - `dimensionality` Number of axes. 
 - `simulation_function` A function `f(state, action)` which returns the resulting state.
 - `action_space` The possible actions to provide `simulation_function`. Should be an `Enum` or at least work with functions `actions_to_int` and `instances`.
 - `samples_per_axis` See `SupportingPoints`.
 - `min_granularity` Splits are not made if the resulting size of the partition would be less than `min_granularity` on the given axis
"""
function try_splitting!(leaf::Leaf, 
	    dimensionality, 
	    simulation_function, 
	    action_space,
	    samples_per_axis,
	    min_granularity;
		max_recursion_depth=5,
		verbose=false)

    root = getroot(leaf)
    bounds = get_bounds(leaf, dimensionality)
    unsafe_value = actions_to_int([]) # The value for states where no actions are allowed.

    if leaf.value == unsafe_value
		verbose && @info "Skipping leaf since it has no safe actions."
        return false
    end

    if !bounded(bounds)
		verbose && @info "Skipping leaf since one of its bounds are infinite."
        return false
    end

	axis, threshold = get_threshold(root, 
		bounds, 
		simulation_function, 
		action_space,
		samples_per_axis,
		min_granularity;
		max_recursion_depth,
		verbose)

        
	if threshold === nothing 
		verbose && @info "Leaf cannot be split further."
		return false
	end

	verbose && @info "Split axis $axis at $threshold"
	
	split!(leaf, axis, threshold)
	return true
end

# ╔═╡ 410cb8b5-2ff3-4a5c-8956-cf748f46edf5
md"""
###  `grow!`
"""

# ╔═╡ 9e807328-488f-4e86-ae53-71f39b2631a7

"""
    grow!(tree::Tree, 
                dimensionality,
                simulation_function, 
                action_space,
                samples_per_axis,
                min_granularity;
                max_iterations=100)


Grow the entire tree by calling `split_all!` on all leaves, until no more changes can be made, or `max_iterations` is exceeded.

Note that the number of resulting leaves is potentially exponential in the number of iterations. Therefore, setting a suitably high `min_granularity` and a suitably low `max_iterations` is adviced.

**Returns:** The number of leaves in the resulting tree.

**Args:**
 - `tree` Tree to modify.
 - `dimensionality` Number of axes. 
 - `simulation_function` A function `f(state, action)` which returns the resulting state.
 - `action_space` The possible actions to provide `simulation_function`. Should be an `Enum` or at least work with functions `actions_to_int` and `instances`.
 - `samples_per_axis` See `SupportingPoints`.
 - `min_granularity` Splits are not made if the resulting size of the partition would be less than `min_granularity` on the given axis
 - `max_iterations` Function automatically terminates after this number of iterations.
"""
function grow!(tree::Tree, 
                dimensionality,
                simulation_function, 
                action_space,
                samples_per_axis,
                min_granularity;
				max_recursion_depth=5,
                max_iterations=10)

	changes_made = 1 # just to enter loop
    leaf_count = 0
	while changes_made > 0
		if (max_iterations -= 1) < 0
			@warn "Max iterations reached while growing tree."
			break
		end
		
		changes_made = 0
		queue = collect(Leaves(tree))
        leaf_count = length(queue)
		for leaf in queue

			split_successful = try_splitting!(leaf, 
				dimensionality, 
				simulation_function, 
                action_space,
				samples_per_axis,
				min_granularity;
				max_recursion_depth)

			if split_successful
                changes_made += 1
                leaf_count += 1 # One leaf wsa removed, two leaves were added.
            end
		end
	end
	leaf_count
end

# ╔═╡ 76f13f2a-82cb-4037-a097-394fb080bf84
md"""
# Try it out!
"""

# ╔═╡ 87e24687-5fc2-485a-ba01-41c10c10d395
md"""
!!! info "Tip"
	This cell controls multiple figures. Move it around to gain a better view.

Try setting a different number of samples per axis: 

`samples_per_axis =` $(@bind samples_per_axis NumberField(3:30, default=3))

And configure min granularity. The value is set as the number of leading zeros to the first digit.

`min_granularity_leading_zeros =` $(@bind min_granularity_leading_zeros NumberField(0:20, default=2))

And the recursion depth:

`max_recursion_depth =` $(@bind max_recursion_depth NumberField(0:9, default=3))
"""

# ╔═╡ 50495f8a-e38f-4fdd-8c75-ca84fd9360c5
bounds_safe, bounds_unsafe = 
	safety_bounds(tree, 
		bounds,
		simulation_function, Pace, samples_per_axis,)

# ╔═╡ e7609f1e-3d94-4e53-9620-dd62995cfc50
call() do
	leaf = get_leaf(tree, 0.5, 0.5)
	bounds = get_bounds(leaf, dimensionality)
	p1 = draw(tree, draw_bounds, color_dict=action_color_dict,legend=:outerright)
	plot!(size=(800,600))
	draw_support_points!(tree, dimensionality, simulation_function, Pace, samples_per_axis, (0.5, 0.5), RW.fast)

	plot!(TreeShielding.rectangle(bounds_safe), 
		label="safe", 
		fill=nothing, 
		lw=4,
		lc=colors.NEPHRITIS)
	plot!(TreeShielding.rectangle(bounds_unsafe), 
		label="unsafe", 
		fill=nothing, 
		lw=6,
		lc=colors.ALIZARIN)
end

# ╔═╡ da493978-1444-4ec3-be36-4aa1c59170b5
offset = get_spacing_sizes(SupportingPoints(samples_per_axis, bounds), dimensionality)

# ╔═╡ 9fa8dd4a-3ffc-4c19-858e-e6188e73175e
min_granularity = 10.0^(-min_granularity_leading_zeros)

# ╔═╡ 3e6a861b-cbb9-4972-adee-46996faf68f3
axis, threshold = get_threshold(tree,
		get_bounds(get_leaf(tree, 0.5, 0.5), dimensionality),
		simulation_function, Pace, samples_per_axis, min_granularity;
		max_recursion_depth)

# ╔═╡ c8d182d8-537f-43d7-ab5f-1374219964e8
call() do
	leaf = get_leaf(tree, 0.5, 0.5)
	bounds = get_bounds(leaf, dimensionality)
	p1 = draw(tree, draw_bounds, color_dict=action_color_dict,legend=:outerright)
	plot!(size=(800,600))
	draw_support_points!(tree, dimensionality, simulation_function, Pace, samples_per_axis, (0.5, 0.5), RW.fast)

	if threshold === nothing 
		return p1
	end
	for i in 0:max_recursion_depth
		safe_above, bounds = get_dividing_bounds(tree,
			get_bounds(get_leaf(tree, 0.5, 0.5), dimensionality),
			simulation_function, Pace, samples_per_axis,
			axis,
			max_recursion_depth=i)
	
		plot!(TreeShielding.rectangle(bounds), lw=0, alpha=0.3, label="$i recursoins")
	end
	p1
end

# ╔═╡ c53e43e9-dc81-4b74-b6bd-41f13791f488
call() do
	leaf = get_leaf(tree, 0.5, 0.5)
	bounds = get_bounds(leaf, dimensionality)
	p1 = draw(tree, draw_bounds, color_dict=action_color_dict,legend=:outerright)
	plot!(size=(800,600))
	draw_support_points!(tree, dimensionality, simulation_function, Pace, samples_per_axis, (0.5, 0.5), RW.fast)

	if threshold === nothing 
		return p1
	end
	for i in 0:max_recursion_depth
		safe_above, bounds = get_dividing_bounds(tree,
			get_bounds(get_leaf(tree, 0.5, 0.5), dimensionality),
			simulation_function, Pace, samples_per_axis,
			axis,
			max_recursion_depth=i)
	
		plot!(TreeShielding.rectangle(bounds), lw=0, alpha=0.3, label="$i recursions")
	end
	if axis == 1
		vline!([threshold], 
			line=(:dot, 5), 
			label="threshold", 
			color=colors.WET_ASPHALT)
	else
		hline!([threshold], 
			line=(:dot, 5), 
			label="threshold", 
			color=colors.WET_ASPHALT)
	end
end

# ╔═╡ bae11a44-67d8-4b6b-8d10-85b58e7fae63
call() do
	tree = deepcopy(tree)
	leaf = get_leaf(tree, 0.5, 0.5)
	try_splitting!(leaf, dimensionality, simulation_function, Pace, samples_per_axis, min_granularity)
	draw(tree, draw_bounds, color_dict=action_color_dict, aspectratio=:equal)
end

# ╔═╡ 46f3eefe-15c7-4bae-acdb-54e485e4b5b7
call() do
	tree = deepcopy(tree)
	grow!(tree, dimensionality, simulation_function, Pace, samples_per_axis, min_granularity; max_recursion_depth)
	leaf_count = length(Leaves(tree) |> collect)
	draw(tree, draw_bounds, color_dict=action_color_dict, aspectratio=:equal)
	plot!([], l=nothing, label="leaves: $leaf_count")
end

# ╔═╡ 66af047f-a34f-484a-8608-8eaaed45b37d
@bind reset_button Button("Reset")

# ╔═╡ 447dc1e2-809a-4f71-b7f4-949ae2a0c4b6
begin
	reset_button
	reactive_tree = deepcopy(tree)
end

# ╔═╡ 1817421e-50b0-47b2-859d-e87aaf3064b0
begin
	reset_button
	@bind refill_queue_button CounterButton("Refill Queue")
end

# ╔═╡ 7fd058fa-20c2-4b7a-b32d-0a1f806b48ac
begin
	refill_queue_button
	reactive_queue = collect(Leaves(reactive_tree))
end

# ╔═╡ e21201c8-b043-4214-b8bc-9e7cc2dced6f
begin
	reset_button
	@bind try_splitting_button CounterButton("Try Splitting")
end

# ╔═╡ 42d2f87e-ce8b-4928-9d00-b0aa70a18cb5
begin
	reset_button, try_splitting_button
	reactive_leaf = pop!(reactive_queue)
end

# ╔═╡ 8cc5f9f3-263c-459f-ae78-f2c0e8487e86
if try_splitting_button > 0
	try_splitting!(reactive_leaf, 
			dimensionality, 
			simulation_function, 
			Pace, 
			samples_per_axis, 
			min_granularity;
			max_recursion_depth,
			verbose=true)
end

# ╔═╡ 7f394991-4673-4f32-8c4f-09225822ae95
call() do
	reset_button, try_splitting_button
	
	draw(reactive_tree, draw_bounds, color_dict=action_color_dict, 
		aspectratio=:equal,
		legend=:outertop,
		size=(500,500))

	if length(reactive_queue) > 0
		bounds = get_bounds(reactive_queue[end], dimensionality)
		plot!(TreeShielding.rectangle(bounds ∩ draw_bounds), 
			label="next in queue",
			linewidth=4,
			linecolor=colors.PETER_RIVER,
			color=colors.CONCRETE,
			fillalpha=0.3)
	end

	leaf_count = Leaves(reactive_tree) |> collect |> length
	plot!([], line=nothing, label="$leaf_count leaves")
end

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
# ╟─f3dd8d47-d582-4e76-ba7c-8975280eb273
# ╟─4a2cc218-1278-48a2-8e8e-2deabc664802
# ╟─a8b53549-5de6-43c8-983d-43e8ca1520da
# ╟─4fe2ab4a-6bc3-40a1-9aed-b702a0fcdf69
# ╟─f14a4efc-1063-4e0d-b968-6c5f46a8c384
# ╠═d043a35e-8092-4306-afbc-e076200e6240
# ╠═7fd00150-0b98-4825-8064-3c805e077206
# ╠═3cee4706-ea98-47b4-aec1-59b27c1cfd0e
# ╟─de7fe51c-0f75-49bb-bc6f-726a21bcd064
# ╠═07ed71cc-a931-4785-9707-86aad883df30
# ╟─ef8dcaa1-4e61-450e-af1e-7cd54e7507f3
# ╠═1cb52b21-8d14-4e2e-ad63-788a56d6bcd2
# ╟─9f9aed0a-66c3-4628-8e7f-cc59374383c9
# ╠═a136ec18-5e84-489b-a13a-ff4ffbb1870d
# ╠═0b6ba501-bc18-4239-b99e-6365b6f5deac
# ╠═b2bc01c9-f501-4c75-8fc4-56dad5cd5c38
# ╠═ee408360-8c64-4619-9810-6038738045dc
# ╠═e9c86cfa-e53f-4c1e-9102-14c821f4232a
# ╟─86e9b7f7-f1f5-4ba2-95d6-5e528b1c0ce6
# ╟─0840b06f-246a-4d62-bf07-2ab9a1cc1e26
# ╠═4455372a-5d12-4a35-bc43-97dcc5719f6c
# ╠═50495f8a-e38f-4fdd-8c75-ca84fd9360c5
# ╠═e7609f1e-3d94-4e53-9620-dd62995cfc50
# ╟─2d999c21-cbdd-4ca6-9866-6f763c91feba
# ╠═ed0def9c-15a3-41a2-b266-849d4a382a69
# ╠═c8d182d8-537f-43d7-ab5f-1374219964e8
# ╟─15b5d339-705e-4408-9629-2002117b8da7
# ╠═394d5768-951b-418c-ab87-367a9b9b90ad
# ╠═a8a02260-61d8-4698-9b61-351adaf68f78
# ╠═da493978-1444-4ec3-be36-4aa1c59170b5
# ╠═9fa8dd4a-3ffc-4c19-858e-e6188e73175e
# ╠═3e6a861b-cbb9-4972-adee-46996faf68f3
# ╠═c53e43e9-dc81-4b74-b6bd-41f13791f488
# ╠═648fb8ab-b156-4c75-b0e0-16c8c7f151ec
# ╠═bae11a44-67d8-4b6b-8d10-85b58e7fae63
# ╟─410cb8b5-2ff3-4a5c-8956-cf748f46edf5
# ╠═9e807328-488f-4e86-ae53-71f39b2631a7
# ╟─87e24687-5fc2-485a-ba01-41c10c10d395
# ╠═46f3eefe-15c7-4bae-acdb-54e485e4b5b7
# ╟─76f13f2a-82cb-4037-a097-394fb080bf84
# ╠═66af047f-a34f-484a-8608-8eaaed45b37d
# ╠═447dc1e2-809a-4f71-b7f4-949ae2a0c4b6
# ╟─1817421e-50b0-47b2-859d-e87aaf3064b0
# ╟─7fd058fa-20c2-4b7a-b32d-0a1f806b48ac
# ╟─42d2f87e-ce8b-4928-9d00-b0aa70a18cb5
# ╟─e21201c8-b043-4214-b8bc-9e7cc2dced6f
# ╠═8cc5f9f3-263c-459f-ae78-f2c0e8487e86
# ╠═7f394991-4673-4f32-8c4f-09225822ae95
