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

# ╔═╡ 12e0989a-9cc1-11ed-2520-1f3866e942fa
begin
	using Pkg
	Pkg.activate(".")
	Pkg.develop("TreeShielding")
	
	using Plots
	using PlutoUI
	using PlutoTest
	using PlutoLinks
	using Serialization
	using AbstractTrees
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
					Leaf(1),
					Node(2, 21,
						Leaf(2),
						Leaf(3))),
				Leaf(4)),
			
			Node(2, 10,
				Leaf(5),
				Node(2, 17,
					Leaf(6),
					Leaf(7))),)
	

# ╔═╡ 8c1c6675-c501-499f-bea0-16b9eae49678
md"""
Bounds define a hyper-rectangle.
"""

# ╔═╡ 8c15e8e6-f4e9-4132-8caf-e8b878e1b8d1
Bounds((0.5, 3.0, -Inf), (1.0, 10.0, 100))

# ╔═╡ 2f2c7b76-03b6-4bac-b411-e1fa7d013fc1
md"""
# Operations
"""

# ╔═╡ f42ea23b-c7ce-4ccd-a643-4f58cc9bafd7
md"""
Bounds support ∈, == and ≈
"""

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

# ╔═╡ 407ba3bf-c67f-46ff-bd19-ec98b341b2cc
md"""
Trees support ==
"""

# ╔═╡ fd2699a6-a849-42b6-961f-19e234acd521
@test bigtree == copy(bigtree)

# ╔═╡ bbf7a3d6-4838-412e-b59d-389fe71cbccb
@doc get_leaf

# ╔═╡ fc187749-c0f7-4d3e-a412-0cfef6f4e3e6
get_leaf(bigtree, (10, 10))

# ╔═╡ 9b8f5bc6-3018-4428-b4fe-fffe9417c0c0
md"""
`get_value` gets the value (contained in the leaf) for a given state.
"""

# ╔═╡ d2aa4aa8-6d97-4074-8644-8704c84a0ee9
@test get_value(bigtree, (2, 20)) == 2

# ╔═╡ 62be74fd-adc6-4f15-abbd-40373bee03bc
@test get_value(bigtree, (10, 10)) == 4

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
	
	replace_subtree!(tree.geq, Leaf(0))
	@test get_value(tree, [0.99]) == 0
end

# ╔═╡ af40206e-42f0-4b45-9a20-510c81b4c755
call() do
	tree = Node(1, 0.5, 
		Leaf(-1),
		Leaf(-2))
	
	split!(tree.geq, 1, 0.75, -3, 0)
	@test get_value(tree, [0.99]) == 0
end

# ╔═╡ 6c2bb206-05d2-482f-93e4-0fe8bf253f10
call() do
	tree = copy(bigtree)
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

# ╔═╡ 6dc7c178-f1fd-4421-a333-897e1d53f6ca
get_value(bigtree, x, y)

# ╔═╡ b0f20e69-e1fc-4cdb-81f1-125116382ecc
dimensionality = 2

# ╔═╡ 60ac823b-cfe1-4212-ab9e-14a90aa683d0
get_bounds(get_leaf(bigtree, (x, y)), dimensionality)

# ╔═╡ dc3a0c5d-8f06-442e-8fe1-d662b0ed896d
md"""
## Serialization

It is my experience that the built-in serialization is fragile to changes in module scope and package versions.
"""

# ╔═╡ df8e53e0-d1c1-45a1-81b3-5e0f2ece53f6
md"""
Tree to serialize:

![A 4-level binary tree named from A to O. At the 4th level there are 8 leaves.](https://i.stack.imgur.com/9jegh.png)
"""

# ╔═╡ df236b61-7f19-461c-9f10-9163175393b3
tree_to_serialize = Node(0, :A,
	Node(0, :B,
		Node(0, :D,
			Leaf(:h),
			Leaf(:i)
		),
		Node(0, :E,
			Leaf(:j),
			Leaf(:k)
		)
	),
	Node(0, :C,
		Node(0, :F,
			Leaf(:l),
			Leaf(:m)
		),
		Node(0, :G,
			Leaf(:n),
			Leaf(:o)
		)
	)
)

# ╔═╡ 602d60b1-21ae-4233-9957-ddab756d1906
working_dir = mktemp()

# ╔═╡ 66fb431c-55dd-4745-b526-106dbf0b713a
file_name = join(working_dir, "tree to serialize.tree")

# ╔═╡ 79386bc7-759c-4cde-9fba-7721215c852e
robust_serialize(file_name, tree_to_serialize)

# ╔═╡ 1cbd2cf9-6a94-4adc-a35c-16a51b0bbe3f
deserialized_tree = robust_deserialize(file_name)

# ╔═╡ 655f8934-fd3e-48c3-b27c-6fee5f976a87
tree_to_serialize == deserialized_tree

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
# ╟─2f2c7b76-03b6-4bac-b411-e1fa7d013fc1
# ╟─f42ea23b-c7ce-4ccd-a643-4f58cc9bafd7
# ╠═2fd4f72a-392a-4b41-86fa-c2899d451a76
# ╠═ae5a9c0d-37ef-4c81-b596-ae09268950fe
# ╠═74c101f9-e14e-4c80-8486-6c433ae64d94
# ╠═4fc92de7-0280-425c-871c-5103a36c8b17
# ╠═a104cf0a-8ec3-4bc5-af3b-99a7583267c0
# ╠═7eb6eb8a-bbfd-47d0-a129-3fcc811af416
# ╟─407ba3bf-c67f-46ff-bd19-ec98b341b2cc
# ╠═fd2699a6-a849-42b6-961f-19e234acd521
# ╠═bbf7a3d6-4838-412e-b59d-389fe71cbccb
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
# ╠═6dc7c178-f1fd-4421-a333-897e1d53f6ca
# ╠═b0f20e69-e1fc-4cdb-81f1-125116382ecc
# ╠═60ac823b-cfe1-4212-ab9e-14a90aa683d0
# ╟─dc3a0c5d-8f06-442e-8fe1-d662b0ed896d
# ╟─df8e53e0-d1c1-45a1-81b3-5e0f2ece53f6
# ╟─df236b61-7f19-461c-9f10-9163175393b3
# ╠═602d60b1-21ae-4233-9957-ddab756d1906
# ╠═66fb431c-55dd-4745-b526-106dbf0b713a
# ╠═79386bc7-759c-4cde-9fba-7721215c852e
# ╠═1cbd2cf9-6a94-4adc-a35c-16a51b0bbe3f
# ╠═655f8934-fd3e-48c3-b27c-6fee5f976a87
