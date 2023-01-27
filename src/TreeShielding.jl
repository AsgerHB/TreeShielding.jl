module TreeShielding

using Plots

export Tree, Node,  Leaf,  Bounds,  get_dim,  get_leaf,  get_value,  draw,  replace_subtree!,  split!,  get_bounds
include("Trees.jl")

export SupportingPoints
include("SuppotingPoints.jl")

end
