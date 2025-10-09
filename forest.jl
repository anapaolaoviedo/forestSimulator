using Agents, Random, Distributions

@enum TreeStatus green burning burnt

@agent struct TreeAgent(GridAgent{2})
    status::TreeStatus = green
end

function forest_step(tree::TreeAgent, model)
    if tree.status == burning
        for neighbor in nearby_agents(tree, model)
            if neighbor.status == green
                # cambio principal
               #numero aleatori dentro del rango
                random_value = rand(abmrng(model)) * 100
                
                
                if random_value < model.probability_of_spread
                    neighbor.status = burning
                end
            end
        end
        tree.status = burnt
    end
end

function forest_fire(; density = 0.45, griddims = (5, 5), probability_of_spread = 100.0)  # ✅ AGREGAR PARÁMETRO
    space = GridSpaceSingle(griddims; periodic = false, metric = :manhattan)
    
    properties = Dict(:probability_of_spread => probability_of_spread)
    
    forest = StandardABM(
        TreeAgent, 
        space; 
        agent_step! = forest_step, 
        scheduler = Schedulers.ByID(),
        properties = properties  # PASAR LAS PROPIEDADES
    )

    for pos in positions(forest)
        if rand(abmrng(forest)) < density  # USAR RNG del modelo (buena práctica)
            tree = add_agent!(pos, TreeAgent, forest)
            if pos[1] == 1
                tree.status = burning
            end
        end
    end
    return forest
end