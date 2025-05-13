@testset "ActionConversion.jl" begin
    @enum TestActions::Int foo bar baz

    @test [foo, bar, baz] == int_to_actions(TestActions, actions_to_int([foo, bar, baz]))
    @test [foo, baz] == int_to_actions(TestActions, actions_to_int([foo, baz]))
    @test [foo, bar] == int_to_actions(TestActions, actions_to_int([foo, bar]))
    @test [bar, baz] == int_to_actions(TestActions, actions_to_int([bar, baz]))
    @test [foo] == int_to_actions(TestActions, actions_to_int([foo]))
end