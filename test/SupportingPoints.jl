@testset "SupportingPoints.jl" begin
    
    # Same upper and lower bounds
    @test [(1, 10)] == [SupportingPoints(3, Bounds((1, 10), (1, 10)))...]
    
    
    # Same upper and lower bounds
    @test 1 == length(SupportingPoints(3, Bounds((1, 10), (1, 10))))

    supporting_points = [SupportingPoints(3, Bounds((1, 10), (10, 100)))...]
    lower, upper = unzip(supporting_points)
    lower, upper = lower |> unique |> sort, upper |> unique |> sort
    @test ([1, 5.5, 10.0], [10, 55.0, 100.0]) == (lower, upper)
end