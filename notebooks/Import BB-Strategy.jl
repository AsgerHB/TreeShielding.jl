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

# ╔═╡ fd8acf9a-f757-455d-b582-85f14e54955b
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
	TableOfContents()
end

# ╔═╡ 7e541f6d-cb20-4b7a-906a-d399af0709e6
begin
	@revise using TreeShielding
	using TreeShielding.BB
end

# ╔═╡ 35275075-889f-4c97-b8ed-407ec0249821
md"""
# Importing a Strategy

## Preface
"""

# ╔═╡ da37b8a2-7dee-4ecc-a0cd-909a571ee8b3
call(f) = f()

# ╔═╡ 7bfba5f8-dcd6-4741-9291-cd5492bf0e4f
action_color_dict=Dict(
	0 => colorant"#ff9178",
	1 => colorant"#a1eaff", 
	2 => colorant"#a1eaaa", 
	3 => colorant"#ffffff", 
)

# ╔═╡ 91605a2d-e7f5-4eda-ab74-89e5327fa08a
action_gradient=cgrad([action_color_dict[1], action_color_dict[2]], categorical=true)

# ╔═╡ 212362c1-8dc3-4cf7-892d-0a4a65c19930
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

# ╔═╡ 8ccad848-e2c5-4039-8cb0-b0f93ffa6235
md"""
## Select Strategy -- Action Required

`selected_file` = $(@bind selected_file PlutoUI.FilePicker([MIME("application/octet-stream")]))
"""

# ╔═╡ 19951daf-a6f5-48ce-bff1-eec3984a30d3
tree = robust_deserialize(selected_file["data"] |> IOBuffer);

# ╔═╡ 7083006d-123c-4f69-8899-292af7e44341
draw_bounds = Bounds((-13, 0), (13, 8))

# ╔═╡ 030f98a3-dd57-43db-86b1-f7d54b0aadd9
draw(tree, draw_bounds, 
	color_dict=action_color_dict, 
	xlims=(draw_bounds.lower[1], draw_bounds.upper[1]),
	ylims=(draw_bounds.lower[2], draw_bounds.upper[2]),
	dpi=300,
	line=nothing,)

# ╔═╡ 5785f277-2e98-494f-b777-a0e35a4fa7ca
md"""
**$(count(_ -> true, Leaves(tree))) leaves**
"""

# ╔═╡ 87f9064d-b8b5-4402-b4cb-a39a13e08a6e
md"""
## Evaluating the safety of the shield
"""

# ╔═╡ d79fd47b-91b1-4839-9081-0124d1dff81c
function shield(tree::Tree, policy)
    return (p) -> begin
		a = policy(p)
        allowed = int_to_actions(Action, get_value(tree, p))
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

# ╔═╡ dcf8957a-9521-49f1-b582-38ea8e22c3f6
hits_rarely = random_policy(0.05)

# ╔═╡ 0ce4f000-6285-4074-9ae2-9d3a578e9aa4
shielded_hits_rarely = shield(tree, hits_rarely)

# ╔═╡ 339e4a3b-489c-41cb-8947-17a049e4b3a8
shielded_hits_rarely((7, 0))

# ╔═╡ 7f25e2a3-e001-4ad6-ad82-eaea1040ef87
@bind runs NumberField(1:100000, default=100)

# ╔═╡ 99a2989d-9962-4d6b-af0b-79818a96cbba
safety_violations = check_safety(bbmechanics, 
		shielded_hits_rarely, 
		120, 
		runs=runs)

# ╔═╡ c1194290-5ea6-448e-8a05-1f4fb521fb42
begin	

	if safety_violations > 0
		Markdown.parse("""
		!!! danger "Not Safe"
			There were $safety_violations safety violations in $runs runs. 
		""")
	else
		Markdown.parse("""
		!!! success "Seems Safe"
			No safety violations observed in $runs runs.
		""")
	end
end

# ╔═╡ 48a165f3-a585-414a-95a6-e97b807e3a18
# ╠═╡ disabled = true
#=╠═╡
call() do
	shielded_lazy = shield(tree, _ -> nohit)
	
	background = draw(p -> Int(shielded_lazy(p)), draw_bounds, color=action_gradient, colorbar=nothing)
	
	animate_trace(
		simulate_sequence(bbmechanics, (0, 7), shielded_lazy, 10)...,
		left_background=background)
end
  ╠═╡ =#

# ╔═╡ 7fa73b53-a860-447d-9a0c-b7a8eac5cad8
shielded_lazy = shield(tree, _ -> nohit)

# ╔═╡ Cell order:
# ╟─35275075-889f-4c97-b8ed-407ec0249821
# ╠═fd8acf9a-f757-455d-b582-85f14e54955b
# ╠═da37b8a2-7dee-4ecc-a0cd-909a571ee8b3
# ╠═7e541f6d-cb20-4b7a-906a-d399af0709e6
# ╠═7bfba5f8-dcd6-4741-9291-cd5492bf0e4f
# ╠═91605a2d-e7f5-4eda-ab74-89e5327fa08a
# ╟─212362c1-8dc3-4cf7-892d-0a4a65c19930
# ╟─8ccad848-e2c5-4039-8cb0-b0f93ffa6235
# ╠═19951daf-a6f5-48ce-bff1-eec3984a30d3
# ╠═7083006d-123c-4f69-8899-292af7e44341
# ╟─030f98a3-dd57-43db-86b1-f7d54b0aadd9
# ╟─5785f277-2e98-494f-b777-a0e35a4fa7ca
# ╟─87f9064d-b8b5-4402-b4cb-a39a13e08a6e
# ╠═d79fd47b-91b1-4839-9081-0124d1dff81c
# ╠═dcf8957a-9521-49f1-b582-38ea8e22c3f6
# ╠═0ce4f000-6285-4074-9ae2-9d3a578e9aa4
# ╠═339e4a3b-489c-41cb-8947-17a049e4b3a8
# ╠═7f25e2a3-e001-4ad6-ad82-eaea1040ef87
# ╠═99a2989d-9962-4d6b-af0b-79818a96cbba
# ╟─c1194290-5ea6-448e-8a05-1f4fb521fb42
# ╠═48a165f3-a585-414a-95a6-e97b807e3a18
# ╠═7fa73b53-a860-447d-9a0c-b7a8eac5cad8
