# https://flatuicolors.com/palette/defo
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

action_color_dict=Dict(
    3 => colorant"#FFFFFF", 
    2 => colorant"#9C59D1", 
    1 => colorant"#FCF434", 
    0 => colorant"#2C2C2C"
)

function rectangle(bounds::Bounds) 
    l, u = bounds.lower, bounds.upper
    xl, yl = l
    xu, yu = u
    Shape(
        [xl, xl, xu, xu],
        [yl, yu, yu, yl])
end

# Draw bounds as rectangles
@recipe function rectangle(bounds::Bounds)
	rectangle(bounds)
end

# Draw bounds as rectangles for an array of Bounds objects
@recipe function rectangle(boundss::AbstractVector{<:Bounds})
    rectangle.(boundss)
end

function draw(policy::Function, bounds; 
    G = 0.1, 
    slice=[:,:], 
    params...)

    if 2 != count((==(Colon())), slice)
        throw(ArgumentError("The slice argument should be an array of indices and exactly two colons. Example: [:, 10, :]"))
    end
    
    x, y = findall((==(Colon())), slice)

    lower = (bounds.lower[x], bounds.lower[y])
    upper = (bounds.upper[x], bounds.upper[y])
    x_min, y_min = lower
    x_max, y_max = upper
    
    size_x, size_y = Int((x_max - x_min)/G), Int((y_max - y_min)/G)
    matrix = Matrix(undef, size_x, size_y)
    for i in 1:size_x
        for j in 1:size_y
            x, y = i*G + x_min, j*G + y_min
            matrix[i, j] = policy((x, y))
        end
    end

    x_tics = x_min:G:x_max
    y_tics = y_min:G:y_max
    
    heatmap(x_tics, y_tics, transpose(matrix),
            levels=10;
            params...)
end

function draw(tree::Tree, global_bounds::Bounds; color_dict=action_color_dict, params...)
    dimensionality = 2
    rectangles = []
    fillcolors = []
    for leaf in Leaves(tree)
        bounds = get_bounds(leaf, dimensionality) ∩ global_bounds
        push!(rectangles, rectangle(bounds))
        push!(fillcolors, get(color_dict, leaf.value, leaf.value))
    end
    fillcolors = permutedims(fillcolors)
    plot([rectangles...], label=nothing, fillcolor=fillcolors; params...)
end


function scatter_supporting_points!(s::SupportingPoints)
	s = [(x[1], x[2]) for x in s]
	scatter!(unzip(s), 
		m=(:+, 5, colors.WET_ASPHALT), msw=4, 
		label="supporting points")
end


scatter_outcomes!(outcomes) = scatter!(outcomes, m=(:c, 3, colors.ASBESTOS), msw=0, label="outcomes")


function draw_support_points!(tree::Tree, point, action, m::ShieldingModel)
    
    bounds = get_bounds(get_leaf(tree, point), m.dimensionality)

    draw_support_points!(tree::Tree, bounds, action, m)
end

function draw_support_points!(tree::Tree,  bounds::Bounds, action, m::ShieldingModel)
    supporting_points = SupportingPoints(m.samples_per_axis, bounds)
    scatter_supporting_points!(supporting_points)
	outcomes = map((p_r) -> m.simulation_function(p_r..., action), TreeShielding.all_supporting_points(bounds, m))
    outcomes = reshape(outcomes, (:,1))
    scatter_outcomes!(outcomes |> unzip)

    points_safe = compute_safety(tree, bounds, m)
    
    unsafe_points = [Tuple(p) for (p, safe) in points_safe if !safe] |> unique
    if length(unsafe_points) > 0
        scatter!(unsafe_points, m=(:x, 5, colors.ALIZARIN), msw=3, label=nothing)
        scatter!([], m=(:x, 5, colors.ALIZARIN), msw=3, label="unsafe")
    end
end

function scatter_allowed_actions!(tree, bounds, m)
    no_action = actions_to_int([])
	actions = [[] for _ in m.action_space]
	unsafe = []

	for p in SupportingPoints(m.samples_per_axis, bounds)
		point_safe = false
		for (i, a) in enumerate(m.action_space)
            action_safe = true
            for r in SupportingPoints(m.samples_per_axis, m.random_variable_bounds)
                p′ = m.simulation_function(p, r, a)
                action_safe = action_safe && get_value(get_leaf(tree, p′)) != no_action
                !action_safe && break
            end
			if action_safe
				push!(actions[i], Tuple(x for x in p))
				point_safe = true
			end
		end
		if !point_safe
			push!(unsafe, Tuple(x for x in p))
		end
	end
	markers = [(:hline, colors.ORANGE, 6) (:vline, colors.PETER_RIVER, 6) (:circle, colors.NEPHRITIS, 7)]
	for (i, a) in enumerate(m.action_space)
        if length(actions[i]) > 0
            scatter!(actions[i] |> unzip, 
                marker=markers[i],
                markerstrokewidth=4,
                label=a)
        end
	end
    if length(unsafe) > 0
        scatter!(unsafe |> unzip,
            marker=(:circle, 4, colors.ALIZARIN),
            markerstrokewidth=0,
            label="unsafe",
            legend=:outerright)
    end
    plot!()
end

function add_actions_to_legend(action_color_dict, action_space; plotargs...)
	for (k, v) in action_color_dict
		label = int_to_actions(typeof(action_space[1]), k)
		label = join(label, ", ")
		label = "{$label}"
		plot!([], 
			seriestype=:shape, 
			color=v, 
			label=label, 
			plotargs...)
	end
    return plot!()
end

function show_reachable!(leaf::Leaf, action, m::ShieldingModel; plotargs...)
	if isnothing(leaf.reachable) || leaf.dirty
		return plot!()
	end

	start = Tuple(middle(get_bounds(leaf, m.dimensionality)))
	scatter!([start], marker=(:circle, 3, :black), label=nothing)

	action_index = indexin([action], m.action_space)[1]
	for leaf′ in leaf.reachable[action_index]
		reachable = Tuple(middle(get_bounds(leaf′, m.dimensionality)))

		
		plot!([start, reachable],
			  linecolor=:black,
			  arrow=:head,
			  label=nothing,
              plotargs...)
	end
	plot!()
end

function show_incoming!(leaf::Leaf, m::ShieldingModel; plotargs...)
	if isnothing(leaf.reachable) || leaf.dirty
		return plot!()
	end

	start = Tuple(middle(get_bounds(leaf, m.dimensionality)))
	scatter!([start], marker=(:circle, 3, :black), label=nothing)

	for leaf′ in leaf.incoming
		reachable = Tuple(middle(get_bounds(leaf′, m.dimensionality)))

		plot!([start, reachable],
			  linecolor=:gray,
			  arrow=:tail,
			  label=nothing,
              plotargs...)
	end
	plot!()
end