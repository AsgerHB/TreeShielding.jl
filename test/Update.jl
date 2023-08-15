@testset "Update.jl" begin
    @enum Action fi fo
    safe, unsafe = actions_to_int(instances(Action)), actions_to_int([])

    function simulation_function(p, _, a)
        if a == fi
            if p[1] >= 0
                return 1
            end
        else
            if p[1] >= 0.5
                return 1
            end
        end
        return -10
    end

    tree = Node(1, -1,
        Leaf(unsafe), # ]-inf; -1]
        Node(1, 0,
            Leaf(safe), # ]-1;0] -> unsafe
            Node(1, 0.5,
                Leaf(safe), # ]0;0.5] -> fi allowed
                Node(1, 1,
                    Leaf(safe), # ]0.5;1] -> fi and fo allowed
                    Leaf(safe)  # ]1;Inf[
                )
            )
        )
    )
    leaf1 = get_leaf(tree, (0.3,))   # ]0.0, 0.5] fi is safe
    leaf2 = get_leaf(tree, (0.6,))   # ]0.5, 1.0] fi and fo are safe
    leaf3 = get_leaf(tree, (-0.1,))  # ]-1.0, 0.0] unsafe partition
    

    dimensionality = 1
    samples_per_axis = 3
    random_variable_bounds = Bounds([], [])

    m = ShieldingModel(simulation_function, Action, dimensionality, samples_per_axis, random_variable_bounds)

    # Act #
    @test update!(tree, m) == 2

    # @show get_bounds(leaf1, m.dimensionality)
    # @show get_bounds(leaf2, m.dimensionality)
    # @show get_bounds(leaf3, m.dimensionality)
    # @show TreeShielding.get_allowed_actions(leaf1, m)
    # @show TreeShielding.get_allowed_actions(leaf2, m)
    # @show TreeShielding.get_allowed_actions(leaf3, m)

    @test leaf1.value == actions_to_int([fi])
    @test leaf2.value == actions_to_int([fi, fo])
    @test leaf3.value == actions_to_int([])
end