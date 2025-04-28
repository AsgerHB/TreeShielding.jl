### A Pluto.jl notebook ###
# v0.19.40

using Markdown
using InteractiveUtils

# ╔═╡ 4059684c-1261-4bed-acf5-965e11101d29
begin
	using Pkg
	Pkg.activate(".")
	Pkg.develop("TreeShielding")
	
	using Plots
	using PlutoLinks
	using PlutoUI
	using PlutoTest
	using Unzip
end

# ╔═╡ 17fecb02-9e2a-11ed-345f-bf4f60752b7d
@revise using TreeShielding

# ╔═╡ c831e8e7-4240-4613-a3dc-ec28f4c92a0f
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

# ╔═╡ aeeeb801-6e68-4f05-a357-900ffa5819d4
policy_colors = [colors.CLOUDS, colors.SUNFLOWER, colors.CONCRETE, colors.PETER_RIVER, colors.ASBESTOS, colors.ORANGE]

# ╔═╡ 36b9e2fc-1f77-479f-827f-6fb9e248dac9
call(f) = f()

# ╔═╡ bf4d855e-eef8-48c3-a885-8b8b4e4e3a2c
tree = Node(1, 0, 
	Leaf(1),
	Leaf(2))

# ╔═╡ e50a20b4-1054-4a72-8780-872c9149c969
md"""
`SupportingPoints` is an iterable data structure representing a set of evenly spaced points within a given bound. 
"""

# ╔═╡ e375ffd9-987e-48ec-a34c-49143cda0a67
[@info s 
	for (i, s) in enumerate(SupportingPoints(3, Bounds((0, 0), (100, 100))))
	if i < 1000...];

# ╔═╡ 3cae5ec7-b510-4dd4-bb77-073f8c65f3d6
# Same upper and lower bounds
@test [(1, 10)] == [SupportingPoints(3, Bounds((1, 10), (1, 10)))...]

# ╔═╡ 397af844-f217-46dd-b61e-ab4fe757a040
# Same upper and lower bounds
@test 1 == length(SupportingPoints(3, Bounds((1, 10), (1, 10))))

# ╔═╡ 18ecc735-ccac-46ef-a338-001b8584c37d
call() do
	supporting_points = [SupportingPoints(3, Bounds((1, 10), (10, 100)))...]
	lower, upper = unzip(supporting_points)
	lower, upper = lower |> unique |> sort, upper |> unique |> sort
	@test ([1, 5.5, 10.0], [10, 55.0, 100.0]) == (lower, upper)
end

# ╔═╡ 96573822-8830-40e7-a2c2-95ccf7ab2da7
md"""
Time to try and draw them
"""

# ╔═╡ 79e27ab4-e215-4d3a-9a46-8392f689aeea
call() do
	dimensionality = 2
	tree = Node(1, 0,
		Leaf(1),
		Leaf(2))
	l, u = -6, 0
	split!(get_leaf(tree, l + 1, u - 1), 1, u, 3, 4)
	split!(get_leaf(tree, l + 1, u - 1), 2, u, 5, 6)
	split!(get_leaf(tree, l + 1, u - 1), 1, l, 7, 8)
	split!(get_leaf(tree, l + 1, u - 1), 2, l, 9, 10)
	
	draw(tree, Bounds((-10, -10), (10, 10)), G=0.05)

	partition = get_bounds(get_leaf(tree, l + 1, u - 1), dimensionality)
	
	xs, ys = unzip([SupportingPoints(3, partition)...])
	scatter!(xs, ys, 
		m=(:+, 5, colors.WET_ASPHALT), msw=4,
		label="supporting points")
end

# ╔═╡ Cell order:
# ╠═4059684c-1261-4bed-acf5-965e11101d29
# ╠═17fecb02-9e2a-11ed-345f-bf4f60752b7d
# ╟─c831e8e7-4240-4613-a3dc-ec28f4c92a0f
# ╟─aeeeb801-6e68-4f05-a357-900ffa5819d4
# ╠═36b9e2fc-1f77-479f-827f-6fb9e248dac9
# ╠═bf4d855e-eef8-48c3-a885-8b8b4e4e3a2c
# ╟─e50a20b4-1054-4a72-8780-872c9149c969
# ╠═e375ffd9-987e-48ec-a34c-49143cda0a67
# ╠═3cae5ec7-b510-4dd4-bb77-073f8c65f3d6
# ╠═397af844-f217-46dd-b61e-ab4fe757a040
# ╠═18ecc735-ccac-46ef-a338-001b8584c37d
# ╟─96573822-8830-40e7-a2c2-95ccf7ab2da7
# ╠═79e27ab4-e215-4d3a-9a46-8392f689aeea
