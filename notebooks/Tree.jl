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

# ╔═╡ 12e0989a-9cc1-11ed-2520-1f3866e942fa
begin
	using Pkg
	Pkg.activate(".")
	Pkg.develop("TreeShielding")
	
	using Plots
	using PlutoUI
	using PlutoTest
	using PlutoLinks
	TableOfContents()
end

# ╔═╡ db69a6fe-b1b0-4e02-88c9-f9bac9f2519c
@revise using TreeShielding

# ╔═╡ 7c49171f-86b9-48a3-ade0-08685965833d
md"""
# Preamble
"""

# ╔═╡ 13bb91da-b57f-49dd-a8ce-ab34d12c973f
call(f) = f()

# ╔═╡ 20b8ab36-5285-4eb2-a658-c3cdeaf8b6f7
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

# ╔═╡ 77eaf90d-f874-4b6e-80e1-4b8107c84cfb
policy_colors = [colors.CLOUDS, colors.SUNFLOWER, colors.CONCRETE, colors.PETER_RIVER, colors.ASBESTOS, colors.ORANGE]

# ╔═╡ 6598365c-643c-4627-a54b-c5a92bfbecfa
md"""
# Basic definitions
"""

# ╔═╡ afab6f48-e09c-4c16-a8e9-593940916ed2
md"""
Trees are made up of Nodes and Leaves. Leaves contain a value, and nodes represent a binary decision.
"""

# ╔═╡ cf318f36-9a50-489e-b541-bb769e72d824
Leaf(1)

# ╔═╡ aa94a2b7-2de8-4de5-bd91-fa2d37c1da50
Leaf(:a)

# ╔═╡ aed0bb69-09a5-465b-a674-0ba6152a087a
Node(1, 0.5,
	Leaf("less than half"),
	Leaf("Half or more"))

# ╔═╡ d4524e62-c515-4667-939e-2f7f90e11a94
bigtree =  
		Node(1, 20, 
			Node(1, 5,
				Node(2, 15,
					Leaf(-3),
					Node(2, 21,
						Leaf(0),
						Leaf(-4))),
				Leaf(-2)),
			
			Node(2, 10,
				Leaf(-5),
				Node(2, 17,
					Leaf(-7),
					Leaf(-6))),)
	

# ╔═╡ 8c1c6675-c501-499f-bea0-16b9eae49678
md"""
Bounds define a hyper-rectangle. They support ∈, == and ≈
"""

# ╔═╡ 8c15e8e6-f4e9-4132-8caf-e8b878e1b8d1
Bounds(Dict(1 => 0.5, 2 => 3), Dict(1 => 1.0, 2 => 10, 3 => 100))

# ╔═╡ 2fd4f72a-392a-4b41-86fa-c2899d451a76
@test (9, 99) ∈ Bounds((-1, -1), (10, 100))

# ╔═╡ ae5a9c0d-37ef-4c81-b596-ae09268950fe
@test !((-10, 99) ∈ Bounds((-1, -1), (10, 100)))

# ╔═╡ 74c101f9-e14e-4c80-8486-6c433ae64d94
@test Bounds([1, 2], [3, 4]) == Bounds([1, 2], [3, 4])

# ╔═╡ 4fc92de7-0280-425c-871c-5103a36c8b17
@test Bounds([1, 2], [3, 4]) != Bounds([-1, -2], [-3, -4])

# ╔═╡ a104cf0a-8ec3-4bc5-af3b-99a7583267c0
@test Bounds([1-eps(), 2], [3, 4]) ≈ Bounds([1, 2], [3, 4])

# ╔═╡ 7eb6eb8a-bbfd-47d0-a129-3fcc811af416
@test Bounds([1-0.1, 2], [3, 4]) ≉ Bounds([1, 2], [3, 4])

# ╔═╡ 2f2c7b76-03b6-4bac-b411-e1fa7d013fc1
md"""
# Operations
"""

# ╔═╡ bbf7a3d6-4838-412e-b59d-389fe71cbccb
md"""
`get_leaf` gets the leaf at the end of the decision-tree for a given state
"""

# ╔═╡ fc187749-c0f7-4d3e-a412-0cfef6f4e3e6
get_leaf(bigtree, (10, 10))

# ╔═╡ 9b8f5bc6-3018-4428-b4fe-fffe9417c0c0
md"""
`get_value` gets the value (contained in the leaf) for a given state.
"""

# ╔═╡ d2aa4aa8-6d97-4074-8644-8704c84a0ee9
@test get_value(bigtree, (2, 20)) == 0

# ╔═╡ 62be74fd-adc6-4f15-abbd-40373bee03bc
@test get_value(bigtree, (10, 10)) == -2

# ╔═╡ c7ecfcd1-a0f8-4eda-804b-85ee14fb0b9a
md"""
`draw` will draw a 2D heatmap representing the values of the decision tree. If the decision tree has more than two axes, the `slice` keyword argument should be provided, to configure which axes will be shown and the constant values to use in the remaining axes.
"""

# ╔═╡ 502cdeb9-951f-48ff-a20a-90617b1c0e7d
bigtree_bounds = Bounds((0, 0), (30, 30))

# ╔═╡ 0a592103-7859-4f4c-b21f-2efad664b930
draw(bigtree, bigtree_bounds)

# ╔═╡ 5b251276-ba63-4bd6-87ff-3dc01a2b5a3c
md"""
`replace_subtree!` and `split!` can be used to modify a tree structure.
"""

# ╔═╡ cc17d0e5-8784-4175-b4db-7c9625a11636
call() do
	tree = Node(1, 0.5, 
		Leaf(-1),
		Leaf(-2))
	
	replace_subtree!(tree.greater_or_equal, Leaf(0))
	@test get_value(tree, [0.99]) == 0
end

# ╔═╡ af40206e-42f0-4b45-9a20-510c81b4c755
call() do
	tree = Node(1, 0.5, 
		Leaf(-1),
		Leaf(-2))
	
	split!(tree.greater_or_equal, 1, 0.75, -3, 0)
	@test get_value(tree, [0.99]) == 0
end

# ╔═╡ 6c2bb206-05d2-482f-93e4-0fe8bf253f10
call() do
	tree = deepcopy(bigtree)
	split!(get_leaf(tree, 10, 10), 2, 10, -4, -3)
	split!(get_leaf(tree, 10, 10), 1, 10, -4, -1)
	return draw(tree, bigtree_bounds)
end

# ╔═╡ b02af88b-6f2c-4793-8515-1d7d77ede167
md"""
`get_bounds` can be used to extract the bounds of a particular partition.
"""

# ╔═╡ 67683995-5031-4e19-8982-15983af4ea82
@bind x NumberField(0:30, default = 5)

# ╔═╡ d482a356-484b-4dca-aef0-c63e93307565
@bind y NumberField(0:30, default = 25)

# ╔═╡ e5df00e2-1ed8-48f4-bb85-b80cb71e3bc8
call() do
	draw(bigtree, bigtree_bounds, G=0.1)
	scatter!([x], [y], m=:x, msw=4, c=colors.WET_ASPHALT, label=nothing)
end

# ╔═╡ d16de4ff-d984-4329-aa01-49632d639e74
get_leaf(bigtree, x, y)

# ╔═╡ 60ac823b-cfe1-4212-ab9e-14a90aa683d0
get_bounds(get_leaf(bigtree, (x, y)))

# ╔═╡ 96774555-be84-4776-a17d-609454111f08
call() do
	tree = Node(1, 0,
		Leaf(1),
		Leaf(2))
	l, u = -6, 0
	split!(get_leaf(tree, l + 1, u - 1), 1, u, 3, 4)
	split!(get_leaf(tree, l + 1, u - 1), 2, u, 5, 6)
	split!(get_leaf(tree, l + 1, u - 1), 1, l, 7, 8)
	split!(get_leaf(tree, l + 1, u - 1), 2, l, 9, 10)
	
	#draw(tree, Bounds((-10, -10), (10, 10)))
	#scatter!([l + 1], [u - 1], m=(:+, 5, colors.WET_ASPHALT), msw=3)
	
	@test Bounds([l, l], [u, u]) == get_bounds(get_leaf(tree, -5, -5))
end

# ╔═╡ Cell order:
# ╟─7c49171f-86b9-48a3-ade0-08685965833d
# ╠═12e0989a-9cc1-11ed-2520-1f3866e942fa
# ╠═db69a6fe-b1b0-4e02-88c9-f9bac9f2519c
# ╠═13bb91da-b57f-49dd-a8ce-ab34d12c973f
# ╟─20b8ab36-5285-4eb2-a658-c3cdeaf8b6f7
# ╟─77eaf90d-f874-4b6e-80e1-4b8107c84cfb
# ╟─6598365c-643c-4627-a54b-c5a92bfbecfa
# ╟─afab6f48-e09c-4c16-a8e9-593940916ed2
# ╠═cf318f36-9a50-489e-b541-bb769e72d824
# ╠═aa94a2b7-2de8-4de5-bd91-fa2d37c1da50
# ╠═aed0bb69-09a5-465b-a674-0ba6152a087a
# ╠═d4524e62-c515-4667-939e-2f7f90e11a94
# ╟─8c1c6675-c501-499f-bea0-16b9eae49678
# ╠═8c15e8e6-f4e9-4132-8caf-e8b878e1b8d1
# ╠═2fd4f72a-392a-4b41-86fa-c2899d451a76
# ╠═ae5a9c0d-37ef-4c81-b596-ae09268950fe
# ╠═74c101f9-e14e-4c80-8486-6c433ae64d94
# ╠═4fc92de7-0280-425c-871c-5103a36c8b17
# ╠═a104cf0a-8ec3-4bc5-af3b-99a7583267c0
# ╠═7eb6eb8a-bbfd-47d0-a129-3fcc811af416
# ╟─2f2c7b76-03b6-4bac-b411-e1fa7d013fc1
# ╟─bbf7a3d6-4838-412e-b59d-389fe71cbccb
# ╠═fc187749-c0f7-4d3e-a412-0cfef6f4e3e6
# ╟─9b8f5bc6-3018-4428-b4fe-fffe9417c0c0
# ╠═d2aa4aa8-6d97-4074-8644-8704c84a0ee9
# ╠═62be74fd-adc6-4f15-abbd-40373bee03bc
# ╟─c7ecfcd1-a0f8-4eda-804b-85ee14fb0b9a
# ╠═502cdeb9-951f-48ff-a20a-90617b1c0e7d
# ╠═0a592103-7859-4f4c-b21f-2efad664b930
# ╟─5b251276-ba63-4bd6-87ff-3dc01a2b5a3c
# ╠═cc17d0e5-8784-4175-b4db-7c9625a11636
# ╠═af40206e-42f0-4b45-9a20-510c81b4c755
# ╠═6c2bb206-05d2-482f-93e4-0fe8bf253f10
# ╠═b02af88b-6f2c-4793-8515-1d7d77ede167
# ╠═67683995-5031-4e19-8982-15983af4ea82
# ╠═d482a356-484b-4dca-aef0-c63e93307565
# ╠═e5df00e2-1ed8-48f4-bb85-b80cb71e3bc8
# ╠═d16de4ff-d984-4329-aa01-49632d639e74
# ╠═60ac823b-cfe1-4212-ab9e-14a90aa683d0
# ╠═96774555-be84-4776-a17d-609454111f08
