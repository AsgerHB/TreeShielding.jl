@testset "Update.jl" begin

    # We use a water-tank example. With open/close that does +0.1/-0.1. Unsafe to exceed 10 or have less than 0 water.

    @enum PumpState::Int open close
    safe, unsafe = actions_to_int(instances(PumpState)), actions_to_int([])

    function simulation_function(s, _, a::PumpState)
        water_level, = s
        if a == open
            water_level += 0.1
        elseif a == close
            water_level -= 0.1
        else
            error("Unexpected action $a")
        end

        (water_level,)
    end

    # 1D state-space with thresholds -∞,  0, 1, 9, 10, ∞
    tree = Node(1, 0,
        Leaf(unsafe), # ]-∞; 0]
        Node(1, 10,
            Node(1, 1, 
                Leaf(safe), # ]0; 1]
                Node(1, 9, 
                    Leaf(safe), # ]1; 9]
                    Leaf(safe)  # ]9; 10]
                )
            ),
            Leaf(unsafe) # ]10; ∞[
        )
    )
    leaf1 = get_leaf(tree, (0.1,))    # Initially safe; close should not be allowed
    leaf2 = get_leaf(tree, (1.1,))    # Initially safe; both actions allowed
    leaf3 = get_leaf(tree, (9.1,))    # Initially safe; open should not be allowed

    
    dimensionality = 1
    samples_per_axis = 3
    random_variable_bounds = Bounds([], [])
    reachability_caching = dependency_graph

    m = ShieldingModel(;simulation_function, action_space=PumpState, dimensionality, samples_per_axis, random_variable_bounds, reachability_caching)

    # @show get_bounds(leaf1, m.dimensionality)
    # @show get_bounds(leaf2, m.dimensionality)
    # @show get_bounds(leaf3, m.dimensionality)


    clear_reachable!(tree, m)
    TreeShielding.set_reachable!(tree, m)

    open_index = 1
    close_index = 2
    
    @test leaf1.reachable[open_index] ∋ leaf2
    @test leaf2.reachable[open_index] ∋ leaf3
    @test leaf3.reachable[close_index] ∋ leaf2

    #@show leaf1.reachable
    #@show leaf2.reachable
    #@show leaf3.reachable

    # for u in TreeShielding.get_updates(tree, m)
    #     @show get_bounds(u.leaf, 1), u.new_value
    # end

    # Act #
    n_updates = update!(tree, m)

    #@show TreeShielding.get_allowed_actions(tree, leaf1, m)
    #@show TreeShielding.get_allowed_actions(tree, leaf2, m)
    #@show TreeShielding.get_allowed_actions(tree, leaf3, m)

    @test n_updates == 2  # I expect it to update leaf1 and leaf3

    @test leaf1.value == actions_to_int([open])
    @test leaf2.value == actions_to_int([open, close])
    @test leaf3.value == actions_to_int([close])
end