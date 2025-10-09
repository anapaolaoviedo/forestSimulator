using Agents, Random, Distributions

@enum TreeStatus green burning burnt

@agent struct TreeAgent(GridAgent{2})
    status::TreeStatus = green
end

function forest_step(tree::TreeAgent, model)
    if tree.status == burning
        
        for neighbor in nearby_agents(tree, model)
            if neighbor.status == green
                # Calcular dirección del vecino
                dx = neighbor.pos[1] - tree.pos[1]
                dy = neighbor.pos[2] - tree.pos[2]
                
                
                adjusted_probability = model.probability_of_spread
                
                if dx > 0  # Vecino al este
                    adjusted_probability += model.west_wind_speed
                elseif dx < 0  # Vecino al oeste
                    adjusted_probability -= model.west_wind_speed
                end
                
                if dy > 0  # Vecino al norte
                    adjusted_probability += model.south_wind_speed
                elseif dy < 0  # Vecino al sur
                    adjusted_probability -= model.south_wind_speed
                end
                
                adjusted_probability = clamp(adjusted_probability, 0.0, 100.0)
                
                random_value = rand(abmrng(model)) * 100
                
                if random_value < adjusted_probability
                    neighbor.status = burning
                end
            end
        end
        tree.status = burnt
    end
end

function forest_fire(; 
    density = 0.45, 
    griddims = (5, 5), 
    probability_of_spread = 100.0,
    south_wind_speed = 0.0,
    west_wind_speed = 0.0
)
    space = GridSpaceSingle(griddims; periodic = false, metric = :chebyshev)
    
    properties = Dict(
        :probability_of_spread => probability_of_spread,
        :south_wind_speed => south_wind_speed,
        :west_wind_speed => west_wind_speed
    )
    
    forest = StandardABM(
        TreeAgent, 
        space; 
        agent_step! = forest_step, 
        scheduler = Schedulers.ByID(),
        properties = properties
    )

    for pos in positions(forest)
        if rand(abmrng(forest)) < density
            tree = add_agent!(pos, TreeAgent, forest)
            if pos[1] == 1
                tree.status = burning
            end
        end
    end
    return forest
end