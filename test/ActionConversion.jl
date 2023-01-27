@testset "ActionConversion.jl" begin
    @enum TestActions foo bar baz

    @test [foo, bar, baz] == int_to_actions(TestActions, (actions_to_int(TestActions, [foo, bar, baz])))
    @test [foo, baz] == int_to_actions(TestActions, (actions_to_int(TestActions, [foo, baz])))
    @test [foo, bar] == int_to_actions(TestActions, (actions_to_int(TestActions, [foo, bar])))
    @test [bar, baz] == int_to_actions(TestActions, (actions_to_int(TestActions, [bar, baz])))
    @test [foo] == int_to_actions(TestActions, (actions_to_int(TestActions, [foo])))
end