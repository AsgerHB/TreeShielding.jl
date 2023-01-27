module TreeShielding

using Plots

export Tree, Node,  Leaf,  Bounds,  get_dim,  get_leaf,  get_value,  draw,  replace_subtree!,  split!,  get_bounds
include("Trees.jl")

export SupportingPoints
include("SuppotingPoints.jl")

export actions_to_int, int_to_actions
include("ActionConversion.jl")
end
