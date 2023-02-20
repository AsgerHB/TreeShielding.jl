module TreeShielding

using Plots
using Serialization
using AbstractTrees

export Bounds,  get_dim, bounded, magnitude
include("Bounds.jl")

export Tree, Node,  Leaf,   get_leaf,  get_value,  draw,  replace_subtree!,  split!,  get_bounds
include("Trees.jl")

export robust_serialize, robust_deserialize
include("RobustSerialization.jl")

export SupportingPoints, get_spacing_sizes
include("SuppotingPoints.jl")

export actions_to_int, int_to_actions
include("ActionConversion.jl")

export ShieldingModel
include("ShieldingModel.jl")

export get_split, compute_safety, get_safety_bounds, get_dividing_bounds, get_threshold, try_splitting!, grow! 
include("Grow.jl")

export update!, ValueUpdate
include("Update.jl")

export tree_from_bounds, even_split!, gridify!, set_safety!
include("TreeBuilding.jl")

export prune!
include("Prune.jl")

export synthesize!
include("Synthesize.jl")


module RW
using Plots
export rwmechanics, Pace, simulate, draw_next_step!, draw_walk!, take_walk, evaluate
include("RWExample.jl")
end#module

end#module