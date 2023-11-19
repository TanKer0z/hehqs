function loadPlayerMoney()
    local money_file = minetest.get_worldpath() .. "/money.txt"
    local player_money = {}
    
    local file = io.open(money_file, "r")
    if file then
        for line in file:lines() do
            local player_name, money = line:match("([^,]+),([^,]+)")
            if player_name and money then
                player_money[player_name] = tonumber(money)
            end
        end
        file:close()
    end
    
    return player_money
end

function savePlayerMoney(player_money)
    local money_file = minetest.get_worldpath() .. "/money.txt"
    
    local file = io.open(money_file, "w")
    if file then
        for player_name, money in pairs(player_money) do
            file:write(player_name .. "," .. money .. "\n")
        end
        file:close()
    end
end

minetest.register_globalstep(function(dtime)
    local player_money = loadPlayerMoney()
    for _, player in ipairs(minetest.get_connected_players()) do
        local player_name = player:get_player_name()
        local last_update = player:get_attribute("last_update") or 0
        local current_time = os.time()
        
        if current_time - last_update >= 600 then
            local previous_money = player_money[player_name] or 0
            player_money[player_name] = previous_money + 20
            savePlayerMoney(player_money)
            player:set_attribute("money", player_money[player_name])
            player:set_attribute("last_update", current_time)
            
            minetest.chat_send_player(player_name, "[System] You received $20! Your balance is now " .. player_money[player_name] .. "$.")
        end
    end
end)

-- Événement lorsque le joueur se connecte
minetest.register_on_joinplayer(function(player)
    local player_money = loadPlayerMoney()
    local player_name = player:get_player_name()
    local current_time = os.time()
    local last_update = player:get_attribute("last_update") or 0
    
    if current_time - last_update >= 600 then
        player_money[player_name] = (player_money[player_name] or 0) + 20
        savePlayerMoney(player_money)
        player:set_attribute("money", player_money[player_name])
        player:set_attribute("last_update", current_time)

        minetest.chat_send_player(player_name, "[System] Welcome! You received $20 in login bonus. Your balance is now " .. player_money[player_name] .. "$.")
    end
end)




minetest.register_chatcommand("money", {
    description = "Shows your money balance.",
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        if not player then
            return false, "[System] Joueur introuvable."
        end

        local player_money = loadPlayerMoney()
        local player_name = player:get_player_name()
        local money = player_money[player_name] or 0
        minetest.chat_send_player(player_name, "[System] Your balance is " .. money .. "$.")
        return true
    end,
})

minetest.register_chatcommand("out_money", {
    params = "<money [1/5/10/100]> <amount>",
    description = "Withdraw money from your balance.",
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        if not player then
            return false, "[System] Player not found."
        end

        local player_name = player:get_player_name()
        local params = param:split(" ")
        local denomination = params[1]
        local amount = tonumber(params[2])

        if not amount or amount <= 0 then
            return false, "[System] Invalid amount."
        end

        local player_money = loadPlayerMoney()

        local available_money = 0
        if denomination == "1" then
            available_money = player_money[player_name] or 0
        elseif denomination == "5" then
            available_money = (player_money[player_name] or 0) / 5
        elseif denomination == "10" then
            available_money = (player_money[player_name] or 0) / 10
        elseif denomination == "100" then
            available_money = (player_money[player_name] or 0) / 100
        else
            return false, "[System] Invalid denomination.| <money [1/5/10/100]> <amount>  "
        end

        if available_money >= amount then
            local withdrawn_money = 0

            if denomination == "1" then
                withdrawn_money = amount
                local money_1_count = math.floor(amount)
                local player_inventory = player:get_inventory()
                player_inventory:add_item("main", ItemStack("hehqs:money_1 " .. money_1_count))
            elseif denomination == "5" then
                withdrawn_money = amount * 5
                local money_5_count = math.floor(amount)
                local player_inventory = player:get_inventory()
                player_inventory:add_item("main", ItemStack("hehqs:money_5 " .. money_5_count))
            elseif denomination == "10" then
                withdrawn_money = amount * 10
                local money_10_count = math.floor(amount)
                local player_inventory = player:get_inventory()
                player_inventory:add_item("main", ItemStack("hehqs:money_10 " .. money_10_count))
            elseif denomination == "100" then
                withdrawn_money = amount * 100
                local money_100_count = math.floor(amount)
                local player_inventory = player:get_inventory()
                player_inventory:add_item("main", ItemStack("hehqs:money_100 " .. money_100_count))
            else
                return false, "[System] Invalid denomination."
            end

            player_money[player_name] = player_money[player_name] - withdrawn_money
            savePlayerMoney(player_money)

            minetest.chat_send_player(player_name, "[System] You withdrew " .. withdrawn_money .. "$ and received corresponding Money items. Your balance is now " .. player_money[player_name] .. "$.")
        else
            return false, "[System] Insufficient balance."
        end

        return true
    end,
})





minetest.register_craftitem("hehqs:money_1", {
    description = "HMoney 1$",
    inventory_image = "money.png",
    stack_max = 500,
    on_use = function(itemstack, user, pointed_thing)
        local player_name = user:get_player_name()
        local player_money = loadPlayerMoney()
        local current_money = player_money[player_name] or 0

        local money_amount = itemstack:get_count()
        player_money[player_name] = current_money + money_amount
        savePlayerMoney(player_money)

        minetest.chat_send_player(player_name, "[System] You received " .. money_amount .. "$. Your balance is now " .. player_money[player_name] .. "$.")

        itemstack:clear()
        return itemstack
    end,
})

minetest.register_craftitem("hehqs:money_5", {
    description = "Money 5$",
    inventory_image = "money_5.png",
    stack_max = 500,
    on_use = function(itemstack, user, pointed_thing)
        local player_name = user:get_player_name()
        local player_money = loadPlayerMoney()
        local current_money = player_money[player_name] or 0

        local money_amount = itemstack:get_count()
        player_money[player_name] = current_money + (money_amount * 5)
        savePlayerMoney(player_money)

        minetest.chat_send_player(player_name, "[System] You received " .. money_amount * 5 .. "$. Your balance is now " .. player_money[player_name] .. "$.")

        itemstack:clear()
        return itemstack
    end,
})

minetest.register_craftitem("hehqs:money_10", {
    description = "Money 10$",
    inventory_image = "money_10.png",
    stack_max = 500,
    on_use = function(itemstack, user, pointed_thing)
        local player_name = user:get_player_name()
        local player_money = loadPlayerMoney()
        local current_money = player_money[player_name] or 0

        local money_amount = itemstack:get_count()
        player_money[player_name] = current_money + (money_amount * 10)
        savePlayerMoney(player_money)

        minetest.chat_send_player(player_name, "[System] You received " .. money_amount * 10 .. "$. Your balance is now " .. player_money[player_name] .. "$.")

        itemstack:clear()
        return itemstack
    end,
})

minetest.register_craftitem("hehqs:money_100", {
    description = "Money 100$",
    inventory_image = "money_100.png",
    stack_max = 500,
    on_use = function(itemstack, user, pointed_thing)
        local player_name = user:get_player_name()
        local player_money = loadPlayerMoney()
        local current_money = player_money[player_name] or 0

        local money_amount = itemstack:get_count()
        player_money[player_name] = current_money + (money_amount * 100)
        savePlayerMoney(player_money)

        minetest.chat_send_player(player_name, "[System] You received " .. money_amount * 100 .. "$. Your balance is now " .. player_money[player_name] .. "$.")

        itemstack:clear()
        return itemstack
    end,
})




minetest.register_chatcommand("donate_money", {
    params = "<playername> <amount>",
    description = "Gives an amount of money to another player.",
    func = function(name, param)
        local giver = minetest.get_player_by_name(name)
        if not giver then
            return false, "[System] Player not found."
        end

        local target_name, amount = param:match("(%S+)%s+(%d+)")
        if not target_name or not amount then
            return false, "Use : /give_money <playername> <amount>"
        end

        amount = tonumber(amount)
        if not amount or amount <= 0 then
            return false, "[System] Invalid amount."
        end

        local giver_name = giver:get_player_name()
        local giver_money = loadPlayerMoney()

        if giver_money[giver_name] and giver_money[giver_name] >= amount then
            local target_money = loadPlayerMoney()
            target_money[target_name] = (target_money[target_name] or 0) + amount
            giver_money[giver_name] = giver_money[giver_name] - amount
            savePlayerMoney(target_money)
            savePlayerMoney(giver_money)

            minetest.chat_send_player(giver_name, "[System] You gave " .. amount .. "$ to " .. target_name)
            minetest.chat_send_player(target_name, "[System] You received " .. amount .. "$ from " .. giver_name)

            local target_money_file = minetest.get_worldpath() .. "/money.txt"
            local target_file = io.open(target_money_file, "r")

            if target_file then
                local target_player_money = {}
                for line in target_file:lines() do
                    local player_name, money = line:match("([^,]+),([^,]+)")
                    if player_name and money then
                        target_player_money[player_name] = tonumber(money)
                    end
                end
                target_file:close()

                target_player_money[target_name] = (target_player_money[target_name] or 0) + amount

                target_file = io.open(target_money_file, "w")
                if target_file then
                    for player_name, money in pairs(target_player_money) do
                        target_file:write(player_name .. "," .. money .. "\n")
                    end
                    target_file:close()
                end
            end
        else
            return false, "[System] Insufficient balance."
        end

        return true
    end,
})

minetest.register_chatcommand("set_money", {
    params = "<playername> <amount>",
    description = "Set a player's money to the specified amount.",
    privs = { server = true },
    func = function(name, param)
        local target_name, amount = param:match("(%S+)%s+(%d+)")
        if not target_name or not amount then
            return false, "Usage: /set_money <playername> <amount>"
        end

        amount = tonumber(amount)
        if not amount or amount < 0 then
            return false, "[System] Invalid amount."
        end

        local target_money = loadPlayerMoney()
        target_money[target_name] = amount
        savePlayerMoney(target_money)

        minetest.chat_send_player(target_name, "[System] Your balance has been set to " .. amount .. "$")
        minetest.chat_send_player(name, "[System] You set " .. target_name .. "'s balance to " .. amount .. "$")

        return true
    end,
})


local special_nodes = {
    ["default:stone_with_iron"] = 1,
    ["default:stone_with_gold"] = 1,
    ["default:stone_with_coal"] = 0.5,
    ["default:stone_with_mese"] = 5,
    ["default:stone_with_diamond"] = 10,
}

minetest.register_on_dignode(function(pos, oldnode, digger)
    local node_name = oldnode.name
    local player_name = digger:get_player_name()
    
    if special_nodes[node_name] then
        local money = special_nodes[node_name]
        
        local player_money = loadPlayerMoney()
        player_money[player_name] = (player_money[player_name] or 0) + money
        savePlayerMoney(player_money)
    end
end)
