
# Returns an integer representing the given set of actions
function actions_to_int(actions, list)
	translation_dict = get_translation_dict(actions)
	
	result = 0

	if actions == [] 
		return result
	end
	
	for action in list
		result += translation_dict[action]
	end
	result
end

prebaked_translation_dict = Dict()

function get_translation_dict(actions)
	if haskey(prebaked_translation_dict, actions)
		return prebaked_translation_dict[actions]
	else
		prebaked_translation_dict[actions] = Dict(a => 2^(i-1) for (i, a) in enumerate(instances(actions)))
		return get_translation_dict(actions)
	end
end

#Returns an integer representing the given set of actions
function int_to_actions(actions, int::Number)
	translation_dict = get_translation_dict(actions)
	
	result = []
	for (k, v) in translation_dict
		 if int & v != 0
			 push!(result, k)
		 end
	end
	result
end
