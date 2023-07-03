@enum Action hit nohit

function simulate_point(mechanics, point, random_variable, action; min_v_on_impact=1)
	t_hit, g, β1, ϵ1, β2, ϵ2, v_hit, p_hit  = mechanics
    v, p = point
    v0, p0 = v, p
    
    if action == hit && p >= p_hit # Hitting the ball changes the velocity
        if v < 0
            v0 = min(v, v_hit)
        else
			v0 = -(β2 + random_variable[1]*ϵ2)*v + v_hit
        end
    end
    
    new_v = g * t_hit + v0
    new_p = 0.5 * g * t_hit^2 + v0*t_hit + p0
    
    if new_p <= 0 # It went through the floor, meaning that a bounce occurs
        t_impact = (-v0 - sqrt(v0^2 - 2*g*p0))/g 
        t_remaining = t_hit - t_impact      # Time left this timestep after bounce occurs
        new_v = g * t_impact + v0        # Gravity pull before impact
		# Impact
		new_v = -(β1 + random_variable[1]*ϵ1)*new_v 
		new_p = 0

		mechanics′ = (t_hit=t_remaining, g, β1, ϵ1, β2, ϵ2, v_hit, p_hit)
		if new_v >= min_v_on_impact
	        new_v, new_p = simulate_point(mechanics′,( new_v, new_p), action, min_v_on_impact=min_v_on_impact)
		else
			new_v, new_p = 0, 0
		end
    end
    
    new_v, new_p
end


function simulate_point(mechanics, point, action; min_v_on_impact=1)
	r = rand(Uniform(-1, 1))
	simulate_point(mechanics, point, r, action; min_v_on_impact=min_v_on_impact)
end


function simulate_sequence(mechanics, initial_point, 
						   policy, duration; 
						   min_v_on_impact=1)
	t_hit, g, β1, ϵ1, β2, ϵ2, v_hit, p_hit  = mechanics
    v0, p0 = initial_point
    velocities::Vector{Real}, positions::Vector{Real}, times = [v0], [p0], [0.0]
    v, p, t = v0, p0, 0
    while times[end] <= duration - t_hit
        action = policy((v, p))
        v, p = simulate_point(mechanics, (v, p), action, 
								min_v_on_impact=min_v_on_impact)
		t += t_hit
        push!(velocities, v)
        push!(positions, p)
        push!(times, t)
    end
    velocities, positions, times
end

function evaluate(mechanics, policy, duration;
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
			v, p = simulate_point(mechanics, (v, p), action)
		end
		push!(costs, cost)
	end
	sum(costs)/runs
end

function check_safety(mechanics, policy, duration; runs=1000)
	t_hit, g, β1, ϵ1, β2, ϵ2, v_hit, p_hit  = mechanics
	deaths = 0
	for run in 1:runs
		v, p = 0, rand(7:10)
		for i in 1:ceil(duration/t_hit)
			action = policy((v, p))
			v, p = simulate_point(mechanics, (v, p), action)
		end
		if v == 0 && p == 0
			deaths += 1
		end
	end
	deaths
end

function animate_trace(vs, ps, ts; fps=10, left_background=plot(), right_background=plot(), plotargs...)
	
	pmax = maximum(ps)
	tmax = maximum(ts)
	vmin = minimum(vs)
	vmax = maximum(vs)
	layout = 2

	animation = @animate for (i, _) in enumerate(ts)

		p1 = plot(left_background)

        plot!(vs[1:i], ps[1:i],
				  xlims=(vmin, vmax), 
				  ylims=(0, pmax),
				  xlabel="velocity (m/s)",
				  ylabel="position (m)",
				  color=colorant"#34495e",
				  markerstrokecolor=colorant"#34495e",
			  	  linewidth=2,
			  	  markersize=2,
			  	  markeralpha=1,
				  margin=4mm,
			  	  markershape=:circle)

		hline!([ps[i]], color=colorant"#27ae60")

		p2 = plot(right_background)

        plot!(ts[1:i], ps[1:i],
				  xlims=(0, tmax), 
				  ylims=(0, pmax),
				  xlabel="time (s)",
				  ylabel="position (m)",
				  color=colorant"#34495e",
			  	  linewidth=2,
			  	  markersize=2,
			  	  markeralpha=1,
				  margin=4mm,
			  	  markershape=:circle)

		hline!([ps[i]], color=colorant"#27ae60")
		plot(p1, p2, 
			layout=layout, 
			size=(800, 400), 
			legend=nothing
			;plotargs...)
	end
	
	gif(animation, joinpath(tempdir(), "trace.gif"), fps = fps, show_msg=false)
end

# Default mechancis
bbmechanics = (t_hit = 0.1, g = -9.81, β1 = 0.91, ϵ1 = 0.06, β2 = 0.95, ϵ2 = 0.05, v_hit = -4.0, p_hit = 4.0)

random_policy(hit_chance) = 
	(_...) -> sample([hit nohit], Weights([hit_chance, 1-hit_chance]), 1)[1]
