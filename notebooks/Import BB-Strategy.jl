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
	actions_to_int([hit, nohit]) => colorant"#FFFFFF", 
	actions_to_int([hit]) => colorant"#9C59D1", 
	actions_to_int([nohit]) => colorant"#FCF434", 
	actions_to_int([]) => colorant"#2C2C2C"
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
draw_bounds = Bounds((-15, 0), (15, 11))

# ╔═╡ 030f98a3-dd57-43db-86b1-f7d54b0aadd9
draw(tree, draw_bounds, 
	color_dict=action_color_dict, 
	xlims=(draw_bounds.lower[1], draw_bounds.upper[1]),
	ylims=(draw_bounds.lower[2], draw_bounds.upper[2]),
	dpi=200,
	xlabel="v",
	ylabel="p",
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

# ╔═╡ d721d6b7-fc17-4f8b-8c5f-93b6d488da18


# ╔═╡ 7f25e2a3-e001-4ad6-ad82-eaea1040ef87
@bind runs NumberField(1:100000, default=100)

# ╔═╡ 7fa73b53-a860-447d-9a0c-b7a8eac5cad8
shielded_lazy = shield(tree, _ -> nohit)

# ╔═╡ ca56e3ca-1325-45b9-8d3a-ff5c26c30b5b
function check_safety(mechanics, policy, duration; runs=1000)
	t_hit, g, β1, ϵ1, β2, ϵ2, v_hit, p_hit  = mechanics
	deaths = 0
	unsafe_trace = nothing
	for run in 1:runs
		v, p, t = 0., rand(7.:10.), 0.
		vs, ps, ts = [v], [p], [t]
		for i in 1:ceil(duration/t_hit)
			action = policy((v, p))
			v, p = simulate_point(mechanics, (v, p), action)
			t += t_hit
			push!(vs, v)
			push!(ps, p)
			push!(ts, t)
		end
		if v == 0 && p == 0
			deaths += 1
			unsafe_trace = (vs, ps, ts)
		end
	end
	deaths, unsafe_trace
end

# ╔═╡ 99a2989d-9962-4d6b-af0b-79818a96cbba
# ╠═╡ disabled = true
#=╠═╡
safety_violations, unsafe_trace = check_safety(bbmechanics, 
		shielded_hits_rarely, 
		120, 
		runs=runs)
  ╠═╡ =#

# ╔═╡ c1194290-5ea6-448e-8a05-1f4fb521fb42
#=╠═╡
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
  ╠═╡ =#

# ╔═╡ 48a165f3-a585-414a-95a6-e97b807e3a18
call() do
	shielded_lazy = shield(tree, _ -> nohit)
	
	background = draw(p -> Int(shielded_lazy(p)), draw_bounds, color=action_gradient, colorbar=nothing)
	
	animate_trace(
		simulate_sequence(bbmechanics, (0, 7), shielded_lazy, 10)...,
		left_background=background)
end

# ╔═╡ bbacbed2-868f-4018-82e8-941aeead21f4
md"""
### Inspect Unsafe Trace
"""

# ╔═╡ b4b4a0e0-ca76-48ec-b16c-5b21db13ee22
md"""
`v_min =` $(@bind v_min NumberField(-20:1:20,
	default=draw_bounds.lower[1]))

`v_max =` $(@bind v_max NumberField(-20:1:20,
	default=draw_bounds.upper[1]))

--

`p_min =` $(@bind p_min NumberField(0:1:15,
	default=draw_bounds.lower[2]))

`p_max =` $(@bind p_max NumberField(0:1:15,
	default=draw_bounds.upper[2]))

--

`t_min =` $(@bind t_min NumberField(0:BB.bbmechanics.t_hit:120, default=0))

`t_max =` $(@bind t_max NumberField(0:BB.bbmechanics.t_hit:120, default=120))
"""

# ╔═╡ dd71a666-c6a8-48b1-a045-c1855d46135e
zoom_bounds = Bounds((v_min, p_min), (v_max, p_max))

# ╔═╡ 5d4bbe8a-fd88-4884-86f5-c01e5b6084fc
tree_plot = draw(tree, zoom_bounds, 
		color_dict=action_color_dict, 
		xlabel="v",
		ylabel="p",
		line=nothing,);

# ╔═╡ b1836fa4-6892-4307-9cca-745b9c8be64c
#=╠═╡
begin
	plot(tree_plot)

	if unsafe_trace !== nothing
		begin
			vs, ps, ts = unsafe_trace
			t_hit = BB.bbmechanics.t_hit
			i_min = ceil(Int, t_min/t_hit) + 1
			i_max = ceil(Int, t_max/t_hit) + 1
			plot!(vs[i_min:i_max], ps[i_min:i_max], 
				label="unsafe trace",
				line=(1, colors.ASBESTOS),
				marker=(2, colors.ASBESTOS),
				msw=0)
		end
	end

	plot!(
		size=(600, 300),
		xlabel="v",
		ylabel="p",
		xlims=(zoom_bounds.lower[1], zoom_bounds.upper[1]),
		ylims=(zoom_bounds.lower[2], zoom_bounds.upper[2]),)
end
  ╠═╡ =#

# ╔═╡ 7a187022-06a3-4749-8057-b579f25de9da
md"""
#### Finding the Bad Partition

Inspect the first point in the trace. Adjust `t_min` until it starts in the place where things go wrong.
"""

# ╔═╡ 135c029c-1035-40b9-9db1-b4492b514eaf
#=╠═╡
v = vs[i_min]
  ╠═╡ =#

# ╔═╡ 04fc8c11-24a1-4cc0-9874-16a4e79896c7
#=╠═╡
p = ps[i_min]
  ╠═╡ =#

# ╔═╡ 8debaa0c-d636-437d-bb93-ea1b358f8213
#=╠═╡
partition = get_leaf(tree, v, p)
  ╠═╡ =#

# ╔═╡ 7358b48a-9ebd-4783-8b29-1f8143947815
md"""
#### Set the Parameters
Try setting a different number of samples per axis: 

`samples_per_axis =` $(@bind samples_per_axis NumberField(3:30, default=3))

`max_iterations =` $(@bind max_iterations NumberField(1:1000, default=20))

And configure min granularity. The value is set as the number of leading zeros to the first digit.

`granularity =` $(@bind granularity NumberField(0:1E-10:1, default=1E-2))


`margin =` $(@bind margin NumberField(0:1E-10:1, default=0))

`splitting_tolerance =` $(@bind splitting_tolerance NumberField(0:1E-10:1, default=1E-4))
"""

# ╔═╡ ab7443d6-d7c2-48b5-8c0a-482702b6063f
dimensionality = 2

# ╔═╡ 45c54b8f-69f1-4ba6-afbf-b82b8bae7ed7
#=╠═╡
bounds = get_bounds(partition, dimensionality)
  ╠═╡ =#

# ╔═╡ 1ebe1f77-8749-4885-b08a-321f28af0a69
simulation_function(p, r, a) = 
	simulate_point(bbmechanics, p, r, a, min_v_on_impact=1)

# ╔═╡ 006ee324-6936-410b-9fd8-ba6e0040c69f
random_variable_bounds = Bounds((-1,), (1,))

# ╔═╡ 37290094-7ecd-4032-88ac-88c0ed21696d
m = ShieldingModel(simulation_function, Action, dimensionality, samples_per_axis, random_variable_bounds; max_iterations, granularity, margin, splitting_tolerance)

# ╔═╡ ca362313-8755-48a4-a444-e598313743ee
m.samples_per_axis^3

# ╔═╡ 7f770f3b-89a1-4189-8e83-7af994b8b6e0


# ╔═╡ 3f181890-8a7c-4ed5-b11e-5f25d947344e
function add_margin(bounds::Bounds, margin)
	Bounds(
		Tuple(l - margin for l in bounds.lower),
		Tuple(u + margin for u in bounds.upper)
	)
end

# ╔═╡ ec6a326e-1267-4d6f-ba81-e01689f7ac3b
#=╠═╡
let

	bounds′ = add_margin(bounds, 0.5)
	
	draw(tree, bounds′, 
		xlim=(bounds′.lower[1], bounds′.upper[1]),
		ylim=(bounds′.lower[2], bounds′.upper[2]),
		color_dict=action_color_dict, 
		xlabel="v",
		ylabel="p",
		line=nothing,);

	scatter_allowed_actions!(tree, bounds, m)
	
	scatter!([v], [p], 
		marker=(2, colors.ASBESTOS), 
		msw=0,
		label="point being inspected")
end
  ╠═╡ =#

# ╔═╡ 02945078-5b6d-4999-9d78-9dc26d7c85c7
md"""
# Tweaking the Strategy
"""

# ╔═╡ 13513f3c-86f7-4e66-bc4b-166360f865c1
tree′ = deepcopy(tree);

# ╔═╡ 67a26631-699a-4638-9798-4134f6903e33
synthesize!(tree′, m)

# ╔═╡ 69427471-b317-4878-b23c-309ad432f883
let
	draw(tree′, draw_bounds, 
		color_dict=action_color_dict, 
		xlims=(draw_bounds.lower[1], draw_bounds.upper[1]),
		ylims=(draw_bounds.lower[2], draw_bounds.upper[2]),
		dpi=200,
		size=(300,200),
		xlabel="v",
		ylabel="p",
		line=(0.1, colors.WET_ASPHALT),)

		# The Float typing has been added to avoid a weird warning
		plot!(Float64[], Float64[], seriestype=:shape, 
			label="{hit nohit}", color=action_color_dict[3])
		
		plot!(Float64[], Float64[], seriestype=:shape, 
			label="{hit}", color=action_color_dict[1])
		
		#plot!(Float64[], Float64[], seriestype=:shape, 
		#	label="{nohit}", color=action_color_dict[2])
		
		plot!(Float64[], Float64[], seriestype=:shape, 
			label="{}", color=action_color_dict[0])
		
end

# ╔═╡ f34e6225-d677-4125-bfd3-8eafe6722470
Leaves(tree′) |> collect |> length

# ╔═╡ bbe18220-3497-465c-b081-62b1b40e5d21
shielded_hits_rarely′ = shield(tree′, hits_rarely)

# ╔═╡ 71720ab5-256d-4ca2-b79c-72f54e3adb48
safety_violations′, unsafe_trace′ = check_safety(bbmechanics, 
		shielded_hits_rarely′,
		120, 
		runs=runs)

# ╔═╡ 3480aa06-68b6-41ce-ad57-d4bcd1e32d8c
begin
	if safety_violations′ > 0
		Markdown.parse("""
		!!! danger "Not Safe"
			There were $safety_violations′ safety violations in $runs runs. 
		""")
	else
		Markdown.parse("""
		!!! success "Seems Safe"
			No safety violations observed in $runs runs.
		""")
	end
end

# ╔═╡ b0ae5ddc-61ab-46b7-a147-c1aa4e547c44
md"""
### Download
"""

# ╔═╡ 36ba3a54-3d9c-453a-851c-ab9cb2e14b88
begin
	save_buffer = IOBuffer()
	robust_serialize(save_buffer, tree′)
end;

# ╔═╡ afa7cd66-9ead-4fa8-a7b5-fabfa36a1ecf
tree′ !== nothing &&
DownloadButton(save_buffer.data, "safety strategy.tree")

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
# ╠═d721d6b7-fc17-4f8b-8c5f-93b6d488da18
# ╠═7f25e2a3-e001-4ad6-ad82-eaea1040ef87
# ╠═7fa73b53-a860-447d-9a0c-b7a8eac5cad8
# ╠═ca56e3ca-1325-45b9-8d3a-ff5c26c30b5b
# ╠═99a2989d-9962-4d6b-af0b-79818a96cbba
# ╟─c1194290-5ea6-448e-8a05-1f4fb521fb42
# ╠═48a165f3-a585-414a-95a6-e97b807e3a18
# ╟─bbacbed2-868f-4018-82e8-941aeead21f4
# ╟─b4b4a0e0-ca76-48ec-b16c-5b21db13ee22
# ╠═dd71a666-c6a8-48b1-a045-c1855d46135e
# ╠═5d4bbe8a-fd88-4884-86f5-c01e5b6084fc
# ╟─b1836fa4-6892-4307-9cca-745b9c8be64c
# ╟─7a187022-06a3-4749-8057-b579f25de9da
# ╠═135c029c-1035-40b9-9db1-b4492b514eaf
# ╠═04fc8c11-24a1-4cc0-9874-16a4e79896c7
# ╠═8debaa0c-d636-437d-bb93-ea1b358f8213
# ╠═45c54b8f-69f1-4ba6-afbf-b82b8bae7ed7
# ╟─7358b48a-9ebd-4783-8b29-1f8143947815
# ╠═ca362313-8755-48a4-a444-e598313743ee
# ╠═ab7443d6-d7c2-48b5-8c0a-482702b6063f
# ╠═ec6a326e-1267-4d6f-ba81-e01689f7ac3b
# ╠═1ebe1f77-8749-4885-b08a-321f28af0a69
# ╠═006ee324-6936-410b-9fd8-ba6e0040c69f
# ╠═37290094-7ecd-4032-88ac-88c0ed21696d
# ╠═7f770f3b-89a1-4189-8e83-7af994b8b6e0
# ╠═3f181890-8a7c-4ed5-b11e-5f25d947344e
# ╟─02945078-5b6d-4999-9d78-9dc26d7c85c7
# ╠═13513f3c-86f7-4e66-bc4b-166360f865c1
# ╠═67a26631-699a-4638-9798-4134f6903e33
# ╠═69427471-b317-4878-b23c-309ad432f883
# ╠═f34e6225-d677-4125-bfd3-8eafe6722470
# ╠═bbe18220-3497-465c-b081-62b1b40e5d21
# ╠═71720ab5-256d-4ca2-b79c-72f54e3adb48
# ╟─3480aa06-68b6-41ce-ad57-d4bcd1e32d8c
# ╟─b0ae5ddc-61ab-46b7-a147-c1aa4e547c44
# ╠═36ba3a54-3d9c-453a-851c-ab9cb2e14b88
# ╠═afa7cd66-9ead-4fa8-a7b5-fabfa36a1ecf
