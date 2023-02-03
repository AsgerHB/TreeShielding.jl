@testset "Update.jl" begin
    @enum Action fi fo
    safe, unsafe = actions_to_int(instances(Action)), actions_to_int([])

    function simulation_function(p, a)
        if a == fi
            if p[1] >= 0
                return 1
            end
        else
            if p[1] >= 0.5
                return 1
            end
        end
        return -1
    end


    struct MockTree <: Tree
        leaves
    end
    mutable struct MockLeaf
        value
        bounds::Bounds
    end

    leaf1 = MockLeaf(safe, Bounds((0,), (1,)))   # fi is safe
    leaf2 = MockLeaf(safe, Bounds((0.5,), (1,))) # fi and fo are safe
    leaf3 = MockLeaf(safe, Bounds((-1,), (0,)))  # unsafe partition
    mock_tree = MockTree([leaf1, leaf2, leaf3])

    AbstractTrees.Leaves(tree::MockTree) = tree.leaves
    TreeShielding.get_bounds(leaf::MockLeaf, _) = leaf.bounds
    TreeShielding.get_value(tree::MockTree, p) = p > 0 ? safe : unsafe # Positive values are safe

    dimensionality = 1
    samples_per_axis = 3

    # Act #
    update!(mock_tree, dimensionality, simulation_function, Action, samples_per_axis)

    @test leaf1.value == actions_to_int([fi])
    @test leaf2.value == actions_to_int([fi, fo])
    @test leaf3.value == actions_to_int([])
end