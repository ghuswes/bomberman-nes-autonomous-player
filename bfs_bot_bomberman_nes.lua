-- globals
-- creating our movimentation board and the size for the graph
STAGE_TIME_REMAINING_ADDRESS  = 0x0093  -- address of the time remaining from the current stage
BOARD_START_ADDRESS           = 0x0200  -- address of the first tile
BOARD_END_ADDRESS             = 0x041F  -- address of the last tile
BOARD_MAP                     = {}      -- mapping actual stage
BOARD_WIDTH                   = 32      -- total columns
BOARD_HEIGHT                  = 13      -- total lines
STAGE_ADDRESS                 = 0x0058  -- current stage information
STAGE_START_ADDRESS           = 0x0060  -- an auxiliar to help us to initilize the board map
BONUS_ADDRESS                 = 0       -- an auxiliar to help us to save some time
EXIT_DOOR_ADDRESS             = 0       -- an auxiliar to help us to save some time
EXIT_DOOR_COORD               = {}      -- an auxiliar to help us to not difficult our life
EXIT_DOOR_IS_NEARBY           = 0       -- an auxiliar to help us to not explode exit door
PRIZE_MOVEMENT_BUFFER         = {}      -- an auxiliar to help moving to the right place
BONUS_COORD                   = {}      -- an auxiliar to help us to update the map when we take the bonus
LIFE_CONTROLLER               = 0       -- an auxiliar to remap the board after we die
ENEMIES_CONTROLLER            = 0       -- an auxiliar to help us to kill enemies
BOMB_COUNT                    = 0       -- an auxiliar to count how much bombs we have used to kill an enemy
ENEMY_COORD_BUFFER            = {}      -- an auxiliar to help the character to avoid enemies
BOMB_FRAME_COUNT              = 0       -- an auxiliar to prevent death to our own bomb

-- board specs          // only to read do not uncomment
-- MAP_EMPTY            = 0 -- default value for empty tiles
-- MAP_CONCRETE         = 1 -- default value for indestructible bricks
-- MAP_BRICK            = 2 -- default value for empty bricks
-- MAP_BOMB             = 3 -- default value for bomb on this tile
-- MAP_HIDDEN_EXIT      = 4 -- default value for brick with a exit door below
-- MAP_HIDDEN_BONUS     = 5 -- default value for brick with a bonus below
-- MAP_BONUS            = 6 -- default value for bonus on this tile
-- MAP_EXIT             = 8 -- default value for exit door on this tile

-- player specs
PLAYER_POSITION_Y_ADDRESS     = 0x0028  -- address for the posY of the player
PLAYER_POSITION_X_ADDRESS     = 0x002A  -- address for the posX of the player
LIFE_LEFT_ADDRESS             = 0x0068  -- address for the quantity of lifes remaining
BOMB_POWER_LEVEL_ADDRESS      = 0x0073  -- address for the power of the bomb (x16)
BOMB_QUANTITY_ADDRESS         = 0x0074  -- address for the quantity bombs can put around the map at the same time
PLAYER_SPEED_ADDRESS          = 0x0075  -- address for the player speed (0-1)
WALLS_TRESPASSING_ADDRESS     = 0x0076  -- address for the ability to trespass walls (0-1)
BOMB_DETONATOR_ADDRESS        = 0x0077  -- address for the ability to detonate bomb using B button (0-1)
BOMB_TRESPASSING_ADDRESS      = 0x0078  -- address for the ability to trespass bombs (0-1)
FIREPROOF_ADDRESS             = 0x0079  -- address for the ability to not die for the bomb explosion ray (0-1)

local function createBomb(bomb_active, address_y, address_x)
    return {
        ACTIVE_INFO         = bomb_active,      -- address for the bomb active bool
        POSITION_Y_ADDRESS  = address_y,        -- address for the posY of bomb
        POSITION_X_ADDRESS  = address_x         -- address for the posX of bomb
    }
end

-- bomb specs
BOMB_ANIMATION_ADDRESS_1      = 0x0431  -- address for the animation of explosion
BOMB_ANIMATION_ADDRESS_2      = 0x0434  -- address for the animation of explosion to make sure
BOMB_ANIMATION_ADDRESS_3      = 0x0435  -- address for the animation of explosion to make sure twice
BOMB = {
    createBomb(0x03A0, 0x03AA, 0x03B4),
    createBomb(0x03A1, 0x03AB, 0x03B5),
    createBomb(0x03A2, 0x03AC, 0x03B6),
    createBomb(0x03A3, 0x03AD, 0x03B7),
    createBomb(0x03A4, 0x03AE, 0x03B8),
    createBomb(0x03A5, 0x03AF, 0x03B9),
    createBomb(0x03A6, 0x03B0, 0x03BA),
    createBomb(0x03A7, 0x03B1, 0x03BB),
    createBomb(0x03A8, 0x03B2, 0x03BC),
    createBomb(0x03A9, 0x03B3, 0x03BD)
}

-- update the position from the enemies around the stage
local function createEnemy(enemy_type, address_y, address_x)
    return {
        ENEMY_TYPE         = enemy_type,        -- address for the enemy type 
        POSITION_Y_ADDRESS = address_y,         -- address for the posY of enemy
        POSITION_X_ADDRESS = address_x          -- address for the posX of enemy
    }
end

-- enemies
ENEMIES_REMAINING_ADDRESS     = 0x009C -- address for the quantity of enemies remaining on current stage
ENEMIES_DEFEATED_ADDRESS      = 0x009E -- address for the quantity of enemies defeated on current stage
ENEMY = {
    createEnemy(0x0576, 0x0580, 0x0594),       -- enemy 1 address of enemy type, posY and posX
    createEnemy(0x0577, 0x0581, 0x0595),       -- enemy 2 address of enemy type, posY and posX
    createEnemy(0x0578, 0x0582, 0x0596),       -- enemy 3 address of enemy type, posY and posX
    createEnemy(0x0579, 0x0583, 0x0597),       -- enemy 4 address of enemy type, posY and posX
    createEnemy(0x057A, 0x0584, 0x0598),       -- enemy 5 address of enemy type, posY and posX
    createEnemy(0x057B, 0x0585, 0x0599),       -- enemy 6 address of enemy type, posY and posX
    createEnemy(0x057C, 0x0586, 0x059A),       -- enemy 7 address of enemy type, posY and posX
    createEnemy(0x057D, 0x0587, 0x059B),       -- enemy 8 address of enemy type, posY and posX
    createEnemy(0x057E, 0x0588, 0x059C),       -- enemy 9 address of enemy type, posY and posX
    createEnemy(0x057F, 0x0589, 0x059D)        -- enemy 10 address of enemy type, posY and posX
}

-- this structure creates a copy of a table
local function deepCopy(original_table)
    local target_type = type(original_table)
    local table_copy
    if target_type == 'table' then
        table_copy = {}
        for target_address, target_information in next, original_table, nil do
            table_copy[deepCopy(target_address)] = deepCopy(target_information)
        end
        setmetatable(table_copy, deepCopy(getmetatable(original_table)))
    else 
        table_copy = original_table -- only if we need to copy another structures types...
    end
    return table_copy
end

-- main functions
-- startup the game
local function initializeGame()
    -- load the game rom
    local directory = emu.getdir() .. "\\ROMs\\Bomberman (U).nes"
    emu.loadrom(directory)

    for i = 1, 35 do
        emu.frameadvance() -- wait 35 frames
    end

    joypad.set(1, {
        start = true       -- press start on the main menu
    })

    for i = 1, 200 do
        emu.frameadvance() -- wait 200 frames
    end

    joypad.set(1, {
        start = false      -- release the start button
    })
end

-- function to set the way our character have to move
local function movePlayer(dx, dy)
    if dy == -1 then
        joypad.set(1, {
            left = true     -- move left
        })
    elseif dy == 1 then
        joypad.set(1, {
            right = true    -- move right
        })
    end

    if dx == -1 then
        joypad.set(1, {
            up = true       -- move up
        })
    elseif dx == 1 then
        joypad.set(1, {
            down = true     -- move down
        })
    end

    if dx == 0 and dy == 0 then
        joypad.set(1, {
            up      = false,
            right   = false,    -- stop the character
            down    = false,
            left    = false
        })
    end
end

-- node structure
local function createNode(value, coordinates, left, up, right, down)
    return {
        TILE_INFO       = value,        -- tile value attribute
        COORDINATES     = coordinates,  -- tile coordinates value attribute
        LEFT_NEIGHBOR   = left,         -- left neighbor coordinates attribute
        UP_NEIGHBOR     = up,           -- up neighbor coordinates attribute
        RIGHT_NEIGHBOR  = right,        -- right neighbor coordinates attribute
        DOWN_NEIGHBOR   = down          -- down neighbor coordinates attribute
    }
end

-- starts a stage in the game, generating a board to travel
local function initializeStage()
    -- clear the board for the new stage
    BOARD_MAP               = {}    -- a new board to travel
    local tile_address      = BOARD_START_ADDRESS
    local coordinates       = {}
    local left              = {}
    local up                = {}
    local right             = {}
    local down              = {}

    for x = 1, BOARD_HEIGHT do
        BOARD_MAP[x] = {}       -- create a new line for the board
        for y = 1, BOARD_WIDTH do
            local value = memory.readbyte(tile_address)     -- current tile value

            if value == 4 or value == 8 then
                EXIT_DOOR_ADDRESS = tile_address
                EXIT_DOOR_COORD = {x, y}
            elseif value == 5 or value == 6 then
                BONUS_ADDRESS = tile_address
                BONUS_COORD = {x, y}
            end

            -- left neighbor
            if y > 1 then
                left = {x, y - 1}
            else
                left = nil
            end

            -- up neighbor
            if x > 1 then
                up = {x - 1, y}
            else
                up = nil
            end

            -- right neighbor
            if y < BOARD_WIDTH then
                right = {x, y + 1}
            else
                right = nil
            end

            -- down neighbor
            if x < BOARD_HEIGHT then
                down = {x + 1, y}
            else
                down = nil
            end

            -- tile coordinates
            coordinates = {x, y}
            
            BOARD_MAP[x][y] = createNode(value, coordinates, left, up, right, down)   -- create a node
            tile_address = tile_address + 1
        end
    end
end

-- the B button works to detonate the bomb whenever we want, but we have to take the powerup first
function pressB()
    joypad.set(1, {
        B = true
    })

    for i = 1, 5 do
        emu.frameadvance() -- wait 5 frames
    end

    joypad.set(1, {
        B = false
    })
end

-- put a bomb on the floor. 
-- ATTENTION: this function always will be called twice, the buffer from the NES is limited, sometimes is too fast and don't recognize the command
-- this occur with the detonator function too
function putBomb()
    joypad.set(1, {
        A = true
    })

    for i = 1, 5 do
        emu.frameadvance() -- wait 5 frames
    end

    joypad.set(1, {
        A = false
    })
end

-- updating the exit door danger area (to not explode next it)
-- updating left exit door area
local function boardUpdateExitDoorLeft(bomb_power)
    local player_coord = BOARD_MAP[memory.readbyte(PLAYER_POSITION_X_ADDRESS)+1][memory.readbyte(PLAYER_POSITION_Y_ADDRESS)+1].COORDINATES
    for x = 1, bomb_power do
        if EXIT_DOOR_COORD[2]-x > 0 then
            if BOARD_MAP[EXIT_DOOR_COORD[1]][EXIT_DOOR_COORD[2]-x].COORDINATES == player_coord then
                BOARD_MAP[EXIT_DOOR_COORD[1]][EXIT_DOOR_COORD[2]-x].TILE_INFO = 9
            elseif BOARD_MAP[EXIT_DOOR_COORD[1]][EXIT_DOOR_COORD[2]-x].TILE_INFO == 0 then     
                BOARD_MAP[EXIT_DOOR_COORD[1]][EXIT_DOOR_COORD[2]-x].TILE_INFO = 9
            else
                return    -- if the first space isn't empty we don't have updates to do
            end
        end
    end
end

-- updating up exit door area
local function boardUpdateExitDoorUp(bomb_power)
    local player_coord = BOARD_MAP[memory.readbyte(PLAYER_POSITION_X_ADDRESS)+1][memory.readbyte(PLAYER_POSITION_Y_ADDRESS)+1].COORDINATES
    for x = 1, bomb_power do
        if EXIT_DOOR_COORD[1]-x > 0 then
            if BOARD_MAP[EXIT_DOOR_COORD[1]-x][EXIT_DOOR_COORD[2]].COORDINATES == player_coord then
                BOARD_MAP[EXIT_DOOR_COORD[1]-x][EXIT_DOOR_COORD[2]].TILE_INFO = 9
                return
            elseif BOARD_MAP[EXIT_DOOR_COORD[1]-x][EXIT_DOOR_COORD[2]].TILE_INFO == 0 then     
                BOARD_MAP[EXIT_DOOR_COORD[1]-x][EXIT_DOOR_COORD[2]].TILE_INFO = 9
            else
                return    -- if the first space isn't empty we don't have updates to do
            end
        end
    end
end

-- updating right exit door area
local function boardUpdateExitDoorRight(bomb_power)
    local player_coord = BOARD_MAP[memory.readbyte(PLAYER_POSITION_X_ADDRESS)+1][memory.readbyte(PLAYER_POSITION_Y_ADDRESS)+1].COORDINATES
    for x = 1, bomb_power do
        if EXIT_DOOR_COORD[2]+x < BOARD_WIDTH then
            if BOARD_MAP[EXIT_DOOR_COORD[1]][EXIT_DOOR_COORD[2]+x].COORDINATES == player_coord then
                BOARD_MAP[EXIT_DOOR_COORD[1]][EXIT_DOOR_COORD[2]+x].TILE_INFO = 9
                return
            elseif BOARD_MAP[EXIT_DOOR_COORD[1]][EXIT_DOOR_COORD[2]+x].TILE_INFO == 0 then     
                BOARD_MAP[EXIT_DOOR_COORD[1]][EXIT_DOOR_COORD[2]+x].TILE_INFO = 9
            else
                return    -- if the first space isn't empty we don't have updates to do
            end
        end
    end
end

-- updating down exit door area
local function boardUpdateExitDoorDown(bomb_power)
    local player_coord = BOARD_MAP[memory.readbyte(PLAYER_POSITION_X_ADDRESS)+1][memory.readbyte(PLAYER_POSITION_Y_ADDRESS)+1].COORDINATES
    for x = 1, bomb_power do
        if EXIT_DOOR_COORD[1]+x < BOARD_HEIGHT then
            if BOARD_MAP[EXIT_DOOR_COORD[1]+x][EXIT_DOOR_COORD[2]].COORDINATES == player_coord then
                BOARD_MAP[EXIT_DOOR_COORD[1]+x][EXIT_DOOR_COORD[2]].TILE_INFO = 9
                return
            elseif BOARD_MAP[EXIT_DOOR_COORD[1]+x][EXIT_DOOR_COORD[2]].TILE_INFO == 0 then     
                BOARD_MAP[EXIT_DOOR_COORD[1]+x][EXIT_DOOR_COORD[2]].TILE_INFO = 9
            else
                return    -- if the first space isn't empty we don't have updates to do
            end
        end
    end
end

-- updating our board to navigate
local function boardUpdate()
    -- remapping the stage
    initializeStage()
    
    -- depending the time we found the exit door it will be a big problem... because it's can't receive some damage, else 10 enemies will spawn from there
    if memory.readbyte(EXIT_DOOR_ADDRESS) == 8 then
        local bomb_power = memory.readbyte(BOMB_POWER_LEVEL_ADDRESS)/16
        boardUpdateExitDoorLeft(bomb_power)     -- updating left side
        boardUpdateExitDoorUp(bomb_power)       -- updating up side
        boardUpdateExitDoorRight(bomb_power)    -- updating right side
        boardUpdateExitDoorDown(bomb_power)     -- updating down side
    end
end

-- search for a place to avoid the danger
local function goToSafetyPlace(safety_path)
    if #safety_path > 0 then
        local dx = safety_path[1][1] - (memory.readbyte(PLAYER_POSITION_X_ADDRESS)+1)
        local dy = safety_path[1][2] - (memory.readbyte(PLAYER_POSITION_Y_ADDRESS)+1)
        movePlayer(dx, dy)
    else
        if memory.readbyte(BOMB_DETONATOR_ADDRESS) == 1 then
            pressB()
            pressB()
            movePlayer(0, 0)
        else
            movePlayer(0, 0)
        end
    end
    if memory.readbyte(ENEMIES_DEFEATED_ADDRESS) > ENEMIES_CONTROLLER then
        ENEMIES_CONTROLLER = memory.readbyte(ENEMIES_DEFEATED_ADDRESS)
        BOMB_COUNT = 0
    end
    if BOARD_MAP[memory.readbyte(PLAYER_POSITION_X_ADDRESS)+1][memory.readbyte(PLAYER_POSITION_Y_ADDRESS)+1].TILE_INFO == 0 then
        EXIT_DOOR_IS_NEARBY = 0
    end
end

-- it's a small step for a man, but a huge step for the progress
local function goTakeToRightPlace(prize_path)
    if #prize_path > 0 then
        local dx = prize_path[1][1] - (memory.readbyte(PLAYER_POSITION_X_ADDRESS)+1)
        local dy = prize_path[1][2] - (memory.readbyte(PLAYER_POSITION_Y_ADDRESS)+1)
        movePlayer(dx, dy)
    else
        if memory.readbyte(BONUS_ADDRESS) == 6 then
            while memory.readbyte(BONUS_ADDRESS) == 6 do
                movePlayer(PRIZE_MOVEMENT_BUFFER[1], PRIZE_MOVEMENT_BUFFER[2])  -- the buffer works to move 1 block ahead, the bot is pixel perfect
                emu.frameadvance()                                              -- but the game only checks if the player walks to the center of the tile
            end
        else
            movePlayer(PRIZE_MOVEMENT_BUFFER[1], PRIZE_MOVEMENT_BUFFER[2])
        end
    end
end

-- just fool around, braking some bricks, the life's beautiful
local function goBreakBricks(breaking_path)
    if #breaking_path > 1 then
        local dx = breaking_path[1][1] - (memory.readbyte(PLAYER_POSITION_X_ADDRESS)+1)
        local dy = breaking_path[1][2] - (memory.readbyte(PLAYER_POSITION_Y_ADDRESS)+1)
        movePlayer(dx, dy)
    elseif BOARD_MAP[memory.readbyte(PLAYER_POSITION_X_ADDRESS)+1][memory.readbyte(PLAYER_POSITION_Y_ADDRESS)+1].TILE_INFO ~= 9 then
        putBomb()
        BOMB_FRAME_COUNT = 0
    else
        EXIT_DOOR_IS_NEARBY = 1
    end
end

-- move in the enemy direction and cleaning the path along the way
local function goKillEnemyBehindTheWall(enemy_position)
    local enemy_distance = 2
    if #enemy_position > enemy_distance then     -- make sure to not touch the enemy... 
        local dx = enemy_position[1][1] - (memory.readbyte(PLAYER_POSITION_X_ADDRESS)+1)
        local dy = enemy_position[1][2] - (memory.readbyte(PLAYER_POSITION_Y_ADDRESS)+1)
        movePlayer(dx, dy)
    elseif memory.readbyte(BOMB[memory.readbyte(BOMB_QUANTITY_ADDRESS)+1].ACTIVE_INFO) == 0 then
        if BOARD_MAP[memory.readbyte(PLAYER_POSITION_X_ADDRESS)+1][memory.readbyte(PLAYER_POSITION_Y_ADDRESS)+1].TILE_INFO ~= 9 then
            putBomb()
            BOMB_FRAME_COUNT = 0
        else
            EXIT_DOOR_IS_NEARBY = 1
        end
    end
end

-- move in the enemy direction and try to kill it, but segurance in first place
local function goKillEnemy(enemy_position)
    local enemy_distance = 1
    if BOMB_COUNT == 5 then
        for i = 0, 5 do
            emu.frameadvance()  -- wait 5 frames to break the enemy path
        end 
        BOMB_COUNT = 0
    end
    if #enemy_position > enemy_distance then     -- make sure to not touch the enemy... 
        local dx = enemy_position[1][1] - (memory.readbyte(PLAYER_POSITION_X_ADDRESS)+1)
        local dy = enemy_position[1][2] - (memory.readbyte(PLAYER_POSITION_Y_ADDRESS)+1)
        movePlayer(dx, dy)
        -- if the enemy is too nearby put a bomb to them don't reach us
        for i = 1, 10 do
            if memory.readbyte(ENEMY[i].ENEMY_TYPE) > 0 and memory.readbyte(ENEMY[i].ENEMY_TYPE) < 9 then
                local target_value = {memory.readbyte(ENEMY[i].POSITION_X_ADDRESS)+1, memory.readbyte(ENEMY[i].POSITION_Y_ADDRESS)+1}
                if enemy_position[2][1] and enemy_position[2][1] == target_value[1] and enemy_position[2][2] == target_value[2] and memory.readbyte(BOMB[memory.readbyte(BOMB_QUANTITY_ADDRESS)+1].ACTIVE_INFO) == 0 then
                    if BOARD_MAP[memory.readbyte(PLAYER_POSITION_X_ADDRESS)+1][memory.readbyte(PLAYER_POSITION_Y_ADDRESS)+1].TILE_INFO ~= 9 then
                        putBomb()
                        BOMB_FRAME_COUNT = 0
                        BOMB_COUNT = BOMB_COUNT + 1
                    else
                        EXIT_DOOR_IS_NEARBY = 1
                    end
                end
            end
        end
    end
end

-- check the vality of the neighbor, to access only non-nil values and if we've already searched in this tile
local function checkNeighborToHide(current_node, visited, custom_map)   -- can move only in danger zones and in free zones
    if current_node[1] and not visited[current_node] and (custom_map[current_node[1]][current_node[2]].TILE_INFO == 0 or custom_map[current_node[1]][current_node[2]].TILE_INFO == 3 or custom_map[current_node[1]][current_node[2]].TILE_INFO == 9) then
        return current_node[1], current_node[2]
    end
end

-- check the vality of the neighbor, to access only non-nil values and if we've already searched in this tile
local function checkNeighborToBonus(current_node, visited)   -- can move only in free zones
    if current_node[1] and not visited[current_node] and (BOARD_MAP[current_node[1]][current_node[2]].TILE_INFO == 0 or BOARD_MAP[current_node[1]][current_node[2]].TILE_INFO == 6) then
        return current_node[1], current_node[2]
    end
end

-- search all the board for an bonus, to access only non-nil values and if we've already searched in this tile
local function checkTheWholeBoardForBonus(current_node, visited)    -- ignores all blocks that aren't concrate tiles
    if current_node[1] and not visited[current_node] and BOARD_MAP[current_node[1]][current_node[2]].TILE_INFO ~= 1 and BOARD_MAP[current_node[1]][current_node[2]].TILE_INFO ~= 8 and BOARD_MAP[current_node[1]][current_node[2]].TILE_INFO ~= 9 then 
        return current_node[1], current_node[2]
    end
end

-- search all the board for the exit door, to access only non-nil values and if we've already searched in this tile
local function checkTheWholeBoardForExit(current_node, visited)    -- ignores all blocks searching for the shortest path
    if current_node[1] and not visited[current_node] and (BOARD_MAP[current_node[1]][current_node[2]].TILE_INFO == 0 or BOARD_MAP[current_node[1]][current_node[2]].TILE_INFO == 8 or BOARD_MAP[current_node[1]][current_node[2]].TILE_INFO == 9) then 
        return current_node[1], current_node[2]
    end
end

-- check the vality of the neighbor, to access only non-nil values and if we've already searched in this tile
local function checkNeighborAbleToChaseEnemies(current_node, visited)   -- can move only in free zones
    if current_node[1] and not visited[current_node] and (BOARD_MAP[current_node[1]][current_node[2]].TILE_INFO == 0 or BOARD_MAP[current_node[1]][current_node[2]].TILE_INFO == 9) then 
        return current_node[1], current_node[2]
    end
end

-- search all the board for a target, to access only non-nil values and if we've already searched in this tile
local function checkTheWholeBoardToChaseEnemies(current_node, visited)  -- this function search the entire board, so what defines this purposes is the condition who call it
    if current_node[1] and not visited[current_node] and BOARD_MAP[current_node[1]][current_node[2]].TILE_INFO ~= 1 and BOARD_MAP[current_node[1]][current_node[2]].TILE_INFO ~= 9 then 
        return current_node[1], current_node[2]
    end
end

-- updating the enemy left path to danger zones
local function leftEnemyDangerZone(custom_map, enemy_spot, enemy_type, danger_range)
    for i = 1, danger_range do
        if enemy_spot[2] - i > 0 then
            if custom_map[enemy_spot[1]] and custom_map[enemy_spot[1]][enemy_spot[2] - i] and (custom_map[enemy_spot[1]][enemy_spot[2] - i].TILE_INFO == 0 or enemy_type == 5 or enemy_type == 6 or enemy_type == 8) then
                custom_map[enemy_spot[1]][enemy_spot[2] - i].TILE_INFO = 3  -- marking oly places we can really move to
            elseif custom_map[enemy_spot[1]] and custom_map[enemy_spot[1]][enemy_spot[2] - i] and custom_map[enemy_spot[1]][enemy_spot[2] - i].TILE_INFO > 0 and custom_map[enemy_spot[1]][enemy_spot[2] - i].TILE_INFO ~= 3 then
                return custom_map   -- the danger spreads only on places the enemy can reach
            end
        end
    end
    return custom_map
end

-- updating the enemy right path to danger zones
local function rightEnemyDangerZone(custom_map, enemy_spot, enemy_type, danger_range)
    for i = 1, danger_range do
        if custom_map[enemy_spot[1]] and custom_map[enemy_spot[1]][enemy_spot[2] + i] and (custom_map[enemy_spot[1]][enemy_spot[2] + i].TILE_INFO == 0 or enemy_type == 5 or enemy_type == 6 or enemy_type == 8) then
            custom_map[enemy_spot[1]][enemy_spot[2] + i].TILE_INFO = 3  -- marking oly places we can really move to
        elseif custom_map[enemy_spot[1]] and custom_map[enemy_spot[1]][enemy_spot[2] + i] and custom_map[enemy_spot[1]][enemy_spot[2] + i].TILE_INFO > 0 and custom_map[enemy_spot[1]][enemy_spot[2] + i].TILE_INFO ~= 3 then
            return custom_map       -- the danger spreads only on places the enemy can reach
        end
    end
    return custom_map
end

-- updating the enemy up path to danger zones
local function upEnemyDangerZone(custom_map, enemy_spot, enemy_type, danger_range)
    for i = 1, danger_range do
        if enemy_spot[1] - i > 0 then
            if custom_map[enemy_spot[1] - i] and custom_map[enemy_spot[1] - i][enemy_spot[2]] and (custom_map[enemy_spot[1] - i][enemy_spot[2]].TILE_INFO == 0 or enemy_type == 5 or enemy_type == 6 or enemy_type == 8) then
                custom_map[enemy_spot[1] - i][enemy_spot[2]].TILE_INFO = 3  -- marking oly places we can really move to
            elseif custom_map[enemy_spot[1] - i] and custom_map[enemy_spot[1] - i][enemy_spot[2]] and custom_map[enemy_spot[1] - i][enemy_spot[2]].TILE_INFO > 0 and custom_map[enemy_spot[1] - i][enemy_spot[2]].TILE_INFO ~= 3 then
                return custom_map   -- the danger spreads only on places the enemy can reach
            end
            enemy_spot[1] = enemy_spot[1] - i
            custom_map = rightEnemyDangerZone(custom_map, enemy_spot, enemy_type, danger_range - i)
            custom_map = leftEnemyDangerZone(custom_map, enemy_spot, enemy_type, danger_range - i)
            enemy_spot[1] = enemy_spot[1] + i
        end
    end
    return custom_map
end

-- updating the enemy down path to danger zones
local function downEnemyDangerZone(custom_map, enemy_spot, enemy_type, danger_range)
    for i = 1, danger_range do
        if custom_map[enemy_spot[1] + i] and custom_map[enemy_spot[1] + i][enemy_spot[2]] and (custom_map[enemy_spot[1] + i][enemy_spot[2]].TILE_INFO == 0 or enemy_type == 5 or enemy_type == 6 or enemy_type == 8) then
            custom_map[enemy_spot[1] + i][enemy_spot[2]].TILE_INFO = 3  -- marking oly places we can really move to
        elseif custom_map[enemy_spot[1] + i] and custom_map[enemy_spot[1] + i][enemy_spot[2]] and custom_map[enemy_spot[1] + i][enemy_spot[2]].TILE_INFO > 0 and custom_map[enemy_spot[1] + i][enemy_spot[2]].TILE_INFO ~= 3 then
            return custom_map   -- the danger spreads only on places the enemy can reach
        end
        enemy_spot[1] = enemy_spot[1] + i
        custom_map = rightEnemyDangerZone(custom_map, enemy_spot, enemy_type, danger_range - i)
        custom_map = leftEnemyDangerZone(custom_map, enemy_spot, enemy_type, danger_range - i)
        enemy_spot[1] = enemy_spot[1] - i
    end
    return custom_map
end

-- create a copy of the board map to manipulate some values, as brick values and creating momentary danger zones 
local function createDangerZonesBoard()
    local danger_board = deepCopy(BOARD_MAP)

    -- spotting the bomb location and it's power
    local bomb_location = {memory.readbyte(BOMB[memory.readbyte(BOMB_QUANTITY_ADDRESS)+1].POSITION_X_ADDRESS)+1, memory.readbyte(BOMB[memory.readbyte(BOMB_QUANTITY_ADDRESS)+1].POSITION_Y_ADDRESS)+1}
    local bomb_power = memory.readbyte(BOMB_POWER_LEVEL_ADDRESS)/16
    
    -- changing the zone that are dangerous by putting a bomb
    danger_board[bomb_location[1]][bomb_location[2]].TILE_INFO = 1
    for x = 1, bomb_power do
        for y = 1, bomb_power do
            if bomb_location[1]+x < BOARD_HEIGHT and danger_board[bomb_location[1]+x][bomb_location[2]] and (danger_board[bomb_location[1]+x][bomb_location[2]].TILE_INFO == 0 or danger_board[bomb_location[1]+x][bomb_location[2]].TILE_INFO == 9) then
                danger_board[bomb_location[1]+x][bomb_location[2]].TILE_INFO = 3      -- marking the down direction as a danger zone
            end
            if bomb_location[1]-x > 0 and danger_board[bomb_location[1]-x][bomb_location[2]] and (danger_board[bomb_location[1]-x][bomb_location[2]].TILE_INFO == 0 or danger_board[bomb_location[1]-x][bomb_location[2]].TILE_INFO == 9) then
                danger_board[bomb_location[1]-x][bomb_location[2]].TILE_INFO = 3      -- marking the up direction as a danger zone
            end
            if bomb_location[2]+y < BOARD_WIDTH and danger_board[bomb_location[1]][bomb_location[2]+y] and (danger_board[bomb_location[1]][bomb_location[2]+y].TILE_INFO == 0 or danger_board[bomb_location[1]][bomb_location[2]+y].TILE_INFO == 9) then
                danger_board[bomb_location[1]][bomb_location[2]+y].TILE_INFO = 3      -- marking the right direction as a danger zone
            end
            if bomb_location[2]-y > 0 and danger_board[bomb_location[1]][bomb_location[2]-y] and (danger_board[bomb_location[1]][bomb_location[2]-y].TILE_INFO == 0 or danger_board[bomb_location[1]][bomb_location[2]-y].TILE_INFO == 9) then
                danger_board[bomb_location[1]][bomb_location[2]-y].TILE_INFO = 3      -- marking the left direction as a danger zone
            end 
        end
    end
    
    -- marking our enemies with danger zones
    for i = 1, 10 do
        if memory.readbyte(ENEMY[i].ENEMY_TYPE) > 0 and memory.readbyte(ENEMY[i].ENEMY_TYPE) < 9 then
            local enemy_spot, enemy_type = {memory.readbyte(ENEMY[i].POSITION_X_ADDRESS)+1, memory.readbyte(ENEMY[i].POSITION_Y_ADDRESS)+1}, ENEMY[i].ENEMY_TYPE                
            danger_board[enemy_spot[1]][enemy_spot[2]].TILE_INFO = 1

            danger_board = leftEnemyDangerZone(danger_board, enemy_spot, enemy_type, 3)    -- marking on map the danger zones, left neighbors
            danger_board = rightEnemyDangerZone(danger_board, enemy_spot, enemy_type, 3)   -- marking on map the danger zones, right neighbors
            danger_board = upEnemyDangerZone(danger_board, enemy_spot, enemy_type, 3)      -- marking on map the danger zones, up neighbors
            danger_board = downEnemyDangerZone(danger_board, enemy_spot, enemy_type, 3)    -- marking on map the danger zones, down neighbors
        end
    end

    if memory.readbyte(BOMB_ANIMATION_ADDRESS_1) ~= 0 or memory.readbyte(BOMB_ANIMATION_ADDRESS_2) ~= 0 then
        for x = 1, bomb_power do
            for y = 1, bomb_power do
                if bomb_location[1]+x < BOARD_HEIGHT and danger_board[bomb_location[1]+x][bomb_location[2]] and (danger_board[bomb_location[1]+x][bomb_location[2]].TILE_INFO == 0 or danger_board[bomb_location[1]+x][bomb_location[2]].TILE_INFO == 9) then
                    danger_board[bomb_location[1]+x][bomb_location[2]].TILE_INFO = 1      -- marking the down direction as a danger zone
                end
                if bomb_location[1]-x > 0 and danger_board[bomb_location[1]-x][bomb_location[2]] and (danger_board[bomb_location[1]-x][bomb_location[2]].TILE_INFO == 0 or danger_board[bomb_location[1]-x][bomb_location[2]].TILE_INFO == 9) then
                    danger_board[bomb_location[1]-x][bomb_location[2]].TILE_INFO = 1      -- marking the up direction as a danger zone
                end
                if bomb_location[2]+y < BOARD_WIDTH and danger_board[bomb_location[1]][bomb_location[2]+y] and (danger_board[bomb_location[1]][bomb_location[2]+y].TILE_INFO == 0 or danger_board[bomb_location[1]][bomb_location[2]+y].TILE_INFO == 9) then
                    danger_board[bomb_location[1]][bomb_location[2]+y].TILE_INFO = 1      -- marking the right direction as a danger zone
                end
                if bomb_location[2]-y > 0 and danger_board[bomb_location[1]][bomb_location[2]-y] and (danger_board[bomb_location[1]][bomb_location[2]-y].TILE_INFO == 0 or danger_board[bomb_location[1]][bomb_location[2]-y].TILE_INFO == 9) then
                    danger_board[bomb_location[1]][bomb_location[2]-y].TILE_INFO = 1      -- marking the left direction as a danger zone
                end 
            end
        end
    end

    if memory.readbyte(FIREPROOF_ADDRESS) == 1 then
        danger_board[bomb_location[1]][bomb_location[2]].TILE_INFO = 0      -- if we have fireproof we are invencible
    end
    
    return danger_board
end

-- we call this function everytime we need to search for anything, generating a new path to possibly reach our goal
local function createNewPath(current_path)
    local new_path = {}
    for _, coord in ipairs(current_path) do
        table.insert(new_path, coord)
    end
    return new_path
end

-- inserts possibly paths to our queue
local function exploringBfs(queue, current_board, current_path, coord_x, coord_y)
    if coord_x and coord_y then
        local new_path = createNewPath(current_path)
        table.insert(new_path, current_board[coord_x][coord_y].COORDINATES)
        table.insert(queue, {node = current_board[coord_x][coord_y], path = new_path})
    end
end

-- this function makes the possibility to choose a better side to avoid an enemy
local function exploreToAvoid(first, second, third, fourth, visited, danger_board, queue, current_path)
    local coord_x, coord_y

    -- call the verification to the first neighbor
    coord_x, coord_y = checkNeighborToHide(first, visited, danger_board)
    exploringBfs(queue, danger_board, current_path, coord_x, coord_y)

    -- call the verification to the second neighbor
    coord_x, coord_y = checkNeighborToHide(second, visited, danger_board)
    exploringBfs(queue, danger_board, current_path, coord_x, coord_y)

    -- call the verification to the third neighbor
    coord_x, coord_y = checkNeighborToHide(third, visited, danger_board)
    exploringBfs(queue, danger_board, current_path, coord_x, coord_y)

    -- call the verification to the fourth neighbor
    coord_x, coord_y = checkNeighborToHide(fourth, visited, danger_board)
    exploringBfs(queue, danger_board, current_path, coord_x, coord_y)
end

-- #=======================#
-- # STARTING UP THE STAGE #
-- #=======================#
local function stageStartUp()
    for i = 0, 250 do
        emu.frameadvance()  -- time to wait the stage start up
    end
    initializeStage()
    LIFE_CONTROLLER     = memory.readbyte(LIFE_LEFT_ADDRESS)            -- this counts how much lives we have remaining
    ENEMIES_CONTROLLER  = memory.readbyte(ENEMIES_DEFEATED_ADDRESS)     -- a controller to help us to predict some enemies
end


-- #===============================#
-- # SEARCHING FOR A PLACE TO HIDE #
-- #===============================#
local function searchForSafePlace()
    -- first we create a board we can write over, will help so much to search for safety places to hide
    local danger_board = createDangerZonesBoard()
    
    -- if no enemies are remaining in map we can clear the buffer
    if memory.readbyte(ENEMIES_REMAINING_ADDRESS) == 0 then
        ENEMY_COORD_BUFFER = {}
    end

    -- now let's search for a safety place to hide and waits the bomb explodes
    local start_node = danger_board[memory.readbyte(PLAYER_POSITION_X_ADDRESS)+1][memory.readbyte(PLAYER_POSITION_Y_ADDRESS)+1]
    local queue = {{node = start_node, path = {start_node.COORDINATES}}}
    local visited = {} -- table with all the visited nodes already

    while #queue > 0 do
        -- remove the first element from the queue
        local current = table.remove(queue, 1)
        local current_node = current.node
        local current_path = current.path

        -- verify if the node was already visited
        if not visited[current_node] then
            visited[current_node] = true

            -- verify if the current node is our goal (a place free of danger)
            if current_node.TILE_INFO ~= 1 and current_node.TILE_INFO ~= 3 then
                table.remove(current_path, 1)
                goToSafetyPlace(current_path, danger_board)
                return true     -- if the safe place was found returns true
            end

            -- check if the enemy position is valid (not nil)
            if ENEMY_COORD_BUFFER[1] then
                -- calc if the position x from the target enemy is greater than our x position
                if current_path[1][1] - ENEMY_COORD_BUFFER[1] < 0 then
                    -- call the verification to the up, lef, right then down neighbor
                    exploreToAvoid(current_node.UP_NEIGHBOR, current_node.LEFT_NEIGHBOR, 
                                   current_node.RIGHT_NEIGHBOR, current_node.DOWN_NEIGHBOR,
                                   visited, danger_board, queue, current_path)
                end

                -- calc if the position x from the target enemy is smaller than our x position
                if current_path[1][1] - ENEMY_COORD_BUFFER[1] > 0 then
                    -- call the verification to the down, left, right then up neighbor
                    exploreToAvoid(current_node.DOWN_NEIGHBOR, current_node.LEFT_NEIGHBOR, 
                                   current_node.RIGHT_NEIGHBOR, current_node.UP_NEIGHBOR,
                                   visited, danger_board, queue, current_path)
                end

                -- calc if the position y from the target enemy is greater than our y position
                if current_path[1][2] - ENEMY_COORD_BUFFER[2] < 0 then
                    -- call the verification to the left, up, down then right neighbor
                    exploreToAvoid(current_node.LEFT_NEIGHBOR, current_node.UP_NEIGHBOR, 
                                   current_node.DOWN_NEIGHBOR, current_node.RIGHT_NEIGHBOR,
                                   visited, danger_board, queue, current_path)
                end

                -- calc if the position y from the target enemy is smaller than our y position
                if current_path[1][2] - ENEMY_COORD_BUFFER[2] > 0 then
                    -- call the verification to the right, up, down, left neighbor
                    exploreToAvoid(current_node.RIGHT_NEIGHBOR, current_node.UP_NEIGHBOR, 
                                   current_node.DOWN_NEIGHBOR, current_node.LEFT_NEIGHBOR,
                                   visited, danger_board, queue, current_path)
                end
            else
                exploreToAvoid(current_node.UP_NEIGHBOR, current_node.DOWN_NEIGHBOR, 
                               current_node.RIGHT_NEIGHBOR, current_node.LEFT_NEIGHBOR, --default search to break bricks
                               visited, danger_board, queue, current_path)
            end
        end
    end
    return false     -- if don't reach a safe place returns false
end


-- #===========================================#
-- # LOOKING FOR A BONUS, THEN I FOUND A BONUS #
-- #===========================================#
local function searchForBonus()
    -- starts the queue with the position of our player (a node) and his coordinates
    local start_node = BOARD_MAP[memory.readbyte(PLAYER_POSITION_X_ADDRESS)+1][memory.readbyte(PLAYER_POSITION_Y_ADDRESS)+1]
    local queue = {{node = start_node, path = {start_node.COORDINATES}}}
    local visited = {} -- table with all the visited nodes already
    
    while #queue > 0 do
        -- remove the first element from the queue
        local current = table.remove(queue, 1)
        local current_node = current.node
        local current_path = current.path

        -- verify if the node was already visited
        if not visited[current_node] then
            visited[current_node] = true

            -- verify if the current node is our goal (any bonus in the map)
            if current_node.TILE_INFO == 6 then -- searching for the bonus location
                if #current_path > 1 then
                    local pseudo_move_x = current_path[#current_path-1]     -- the buffer works to move 1 block ahead, the bot is pixel perfect
                    local pseudo_move_y = current_path[#current_path]       -- but the game only checks if the player walks to the center of the tile
                    PRIZE_MOVEMENT_BUFFER = {pseudo_move_y[1] - pseudo_move_x[1], pseudo_move_y[2] - pseudo_move_x[2]}
                end
                table.remove(current_path, 1)
                goTakeToRightPlace(current_path)
                return true     -- if the bonus is available returns true
            end

            -- our current node coordinates
            local coord_x, coord_y

            -- call the verification to the left neighbor
            coord_x, coord_y = checkNeighborToBonus(current_node.LEFT_NEIGHBOR, visited)
            exploringBfs(queue, BOARD_MAP, current_path, coord_x, coord_y)

            -- call the verification to the up neighbor
            coord_x, coord_y = checkNeighborToBonus(current_node.UP_NEIGHBOR, visited)
            exploringBfs(queue, BOARD_MAP, current_path, coord_x, coord_y)

            -- call the verification to the right neighbor
            coord_x, coord_y = checkNeighborToBonus(current_node.RIGHT_NEIGHBOR, visited)
            exploringBfs(queue, BOARD_MAP, current_path, coord_x, coord_y)

            -- call the verification to the down neighbor
            coord_x, coord_y = checkNeighborToBonus(current_node.DOWN_NEIGHBOR, visited)
            exploringBfs(queue, BOARD_MAP, current_path, coord_x, coord_y)
        end
    end
    return false    -- if the bonus is already taken returns false
end


-- #==============================#
-- # BREAKING BRICKS GIVES POWERS #
-- #==============================#
local function searchForBrick()
    -- starts the queue with the position of our player (a node) and his coordinates
    local start_node = BOARD_MAP[memory.readbyte(PLAYER_POSITION_X_ADDRESS)+1][memory.readbyte(PLAYER_POSITION_Y_ADDRESS)+1]
    local queue = {{node = start_node, path = {start_node.COORDINATES}}}
    local visited = {} -- table with all the visited nodes already

    while #queue > 0 do
        -- remove the first element from the queue
        local current = table.remove(queue, 1)
        local current_node = current.node
        local current_path = current.path

        -- verify if the node was already visited
        if not visited[current_node] then
            visited[current_node] = true

            -- verify if the current node is our goal (any brick in the map)
            if current_node.TILE_INFO > 1 and current_node.TILE_INFO < 6 then
                table.remove(current_path, 1)
                goBreakBricks(current_path)
                return true     -- until all objectives isn't complete return true
            end

            -- our current node coordinates
            local coord_x, coord_y

            -- call the verification to the left neighbor
            coord_x, coord_y = checkTheWholeBoardForBonus(current_node.LEFT_NEIGHBOR, visited)
            exploringBfs(queue, BOARD_MAP, current_path, coord_x, coord_y)

            -- call the verification to the up neighbor
            coord_x, coord_y = checkTheWholeBoardForBonus(current_node.UP_NEIGHBOR, visited)
            exploringBfs(queue, BOARD_MAP, current_path, coord_x, coord_y)

            -- call the verification to the right neighbor
            coord_x, coord_y = checkTheWholeBoardForBonus(current_node.RIGHT_NEIGHBOR, visited)
            exploringBfs(queue, BOARD_MAP, current_path, coord_x, coord_y)

            -- call the verification to the down neighbor
            coord_x, coord_y = checkTheWholeBoardForBonus(current_node.DOWN_NEIGHBOR, visited)
            exploringBfs(queue, BOARD_MAP, current_path, coord_x, coord_y)
        end
    end
    if BOARD_MAP[memory.readbyte(PLAYER_POSITION_X_ADDRESS)+1][memory.readbyte(PLAYER_POSITION_Y_ADDRESS)+1].TILE_INFO == 9 then
        EXIT_DOOR_IS_NEARBY = 1
    end
    return false     -- if don't need to break bricks more returns false
end


-- #=========================#
-- # LET'S GET OUT FROM HERE #
-- #=========================#
local function searchForExit()
    -- starts the queue with the position of our player (a node) and his coordinates
    local start_node = BOARD_MAP[memory.readbyte(PLAYER_POSITION_X_ADDRESS)+1][memory.readbyte(PLAYER_POSITION_Y_ADDRESS)+1]
    local queue = {{node = start_node, path = {start_node.COORDINATES}}}
    local visited = {} -- table with all the visited nodes already

    while #queue > 0 do
        -- remove the first element from the queue
        local current = table.remove(queue, 1)
        local current_node = current.node
        local current_path = current.path

        -- verify if the node was already visited
        if not visited[current_node] then
            visited[current_node] = true

            -- verify if the current node is our goal (exit door)
            if current_node.TILE_INFO == 8 then -- searching for the exit door location
                if #current_path > 1 then
                    local pseudo_move_x = current_path[#current_path-1]     -- the buffer works to move 1 block ahead, the bot is pixel perfect
                    local pseudo_move_y = current_path[#current_path]       -- but the game only checks if the player walks to the center of the tile
                    PRIZE_MOVEMENT_BUFFER = {pseudo_move_y[1] - pseudo_move_x[1], pseudo_move_y[2] - pseudo_move_x[2]}
                end
                table.remove(current_path, 1)
                goTakeToRightPlace(current_path)
                return true     -- if the exit is open and no enemies are around returns true
            end

            -- our current node coordinates
            local coord_x, coord_y

            -- call the verification to the left neighbor
            coord_x, coord_y = checkTheWholeBoardForExit(current_node.LEFT_NEIGHBOR, visited)
            exploringBfs(queue, BOARD_MAP, current_path, coord_x, coord_y)

            -- call the verification to the up neighbor
            coord_x, coord_y = checkTheWholeBoardForExit(current_node.UP_NEIGHBOR, visited)
            exploringBfs(queue, BOARD_MAP, current_path, coord_x, coord_y)

            -- call the verification to the right neighbor
            coord_x, coord_y = checkTheWholeBoardForExit(current_node.RIGHT_NEIGHBOR, visited)
            exploringBfs(queue, BOARD_MAP, current_path, coord_x, coord_y)

            -- call the verification to the down neighbor
            coord_x, coord_y = checkTheWholeBoardForExit(current_node.DOWN_NEIGHBOR, visited)
            exploringBfs(queue, BOARD_MAP, current_path, coord_x, coord_y)
        end
    end
    return false     -- if we can't go on returns false
end


--  #=======================#
--  # SEARCHING FOR ENEMIES #
--  #=======================#
local function searchForEnemy()
    -- starts the queue with the position of our player (a node) and his coordinates
    local start_node = BOARD_MAP[memory.readbyte(PLAYER_POSITION_X_ADDRESS)+1][memory.readbyte(PLAYER_POSITION_Y_ADDRESS)+1]
    local queue = {{node = start_node, path = {start_node.COORDINATES}}}
    local visited = {}  -- table with all the visited nodes already

    while #queue > 0 do
        -- remove the first element from the queue
        local current = table.remove(queue, 1)
        local current_node = current.node
        local current_path = current.path

        -- verify if the node was already visited
        if not visited[current_node] then
            visited[current_node] = true -- mark as verificated

            -- verify if the current node is our goal
            for i = 1, 10 do
                if memory.readbyte(ENEMY[i].ENEMY_TYPE) > 0 and memory.readbyte(ENEMY[i].ENEMY_TYPE) < 9 then
                    local target_value = {memory.readbyte(ENEMY[i].POSITION_X_ADDRESS)+1, memory.readbyte(ENEMY[i].POSITION_Y_ADDRESS)+1}
                    if current_node.COORDINATES[1] == target_value[1] and current_node.COORDINATES[2] == target_value[2] then
                        table.remove(current_path, 1)
                        if #current_path > 0 then
                            ENEMY_COORD_BUFFER = {target_value[1], target_value[2]}
                        end
                        if #current_path > 0 and current_path[1][1] == target_value[1] and current_path[1][2] == target_value[2] then
                            if BOARD_MAP[memory.readbyte(PLAYER_POSITION_X_ADDRESS)+1][memory.readbyte(PLAYER_POSITION_Y_ADDRESS)+1].TILE_INFO ~= 9 then
                                putBomb()
                                BOMB_FRAME_COUNT = 0
                                BOMB_COUNT = BOMB_COUNT + 1
                            else
                                EXIT_DOOR_IS_NEARBY = 1
                            end
                        end
                        goKillEnemy(current_path)   -- move the player to the enemy, to kill it
                        return true     -- if reached a enemy returns true
                    end
                end
            end
            
            -- our current node coordinates
            local coord_x, coord_y

            -- call the verification to the left neighbor
            coord_x, coord_y = checkNeighborAbleToChaseEnemies(current_node.LEFT_NEIGHBOR, visited)
            exploringBfs(queue, BOARD_MAP, current_path, coord_x, coord_y)

            -- call the verification to the up neighbor
            coord_x, coord_y = checkNeighborAbleToChaseEnemies(current_node.UP_NEIGHBOR, visited)
            exploringBfs(queue, BOARD_MAP, current_path, coord_x, coord_y)

            -- call the verification to the right neighbor
            coord_x, coord_y = checkNeighborAbleToChaseEnemies(current_node.RIGHT_NEIGHBOR, visited)
            exploringBfs(queue, BOARD_MAP, current_path, coord_x, coord_y)
            
            -- call the verification to the down neighbor
            coord_x, coord_y = checkNeighborAbleToChaseEnemies(current_node.DOWN_NEIGHBOR, visited)
            exploringBfs(queue, BOARD_MAP, current_path, coord_x, coord_y)
        end
    end
    return false     -- if don't reached a enemy returns false
end


-- #==================================#
-- # BREAKING BRICKS TO REACH ENEMIES #
-- #==================================#
local function searchForEnemyInWholeBoard()
    -- starts the queue with the position of our player (a node) and his coordinates
    local start_node = BOARD_MAP[memory.readbyte(PLAYER_POSITION_X_ADDRESS)+1][memory.readbyte(PLAYER_POSITION_Y_ADDRESS)+1]
    local queue = {{node = start_node, path = {start_node.COORDINATES}}}
    local visited = {}  -- table with all the visited nodes already

    -- if the enemy is too nearby put a bomb to them don't reach us
    for i = 1, 10 do
        if memory.readbyte(ENEMY[i].ENEMY_TYPE) > 0 and memory.readbyte(ENEMY[i].ENEMY_TYPE) < 9 then
            local target_value = {memory.readbyte(ENEMY[i].POSITION_X_ADDRESS)+1, memory.readbyte(ENEMY[i].POSITION_Y_ADDRESS)+1}
            if math.abs(start_node.COORDINATES[1] - target_value[1]) < 2 and math.abs(start_node.COORDINATES[2] - target_value[2]) < 2 and memory.readbyte(BOMB[memory.readbyte(BOMB_QUANTITY_ADDRESS)+1].ACTIVE_INFO) == 0 then
                if BOARD_MAP[memory.readbyte(PLAYER_POSITION_X_ADDRESS)+1][memory.readbyte(PLAYER_POSITION_Y_ADDRESS)+1].TILE_INFO ~= 9 then
                    putBomb()
                    BOMB_FRAME_COUNT = 0
                else
                    EXIT_DOOR_IS_NEARBY = 1
                end
            end
        end
    end

    while #queue > 0 do
        -- remove the first element from the queue
        local current = table.remove(queue, 1)
        local current_node = current.node
        local current_path = current.path

        -- verify if the node was already visited
        if not visited[current_node] then
            visited[current_node] = true -- mark as verificated

            -- verify if the current node is our goal
            for i = 1, 10 do
                if memory.readbyte(ENEMY[i].ENEMY_TYPE) > 0 and memory.readbyte(ENEMY[i].ENEMY_TYPE) < 9 then
                    local target_value = {memory.readbyte(ENEMY[i].POSITION_X_ADDRESS)+1, memory.readbyte(ENEMY[i].POSITION_Y_ADDRESS)+1}
                    if current_node.COORDINATES[1] == target_value[1] and current_node.COORDINATES[2] == target_value[2] then
                        local next_brick = current_path[2]
                        if BOARD_MAP[next_brick[1]][next_brick[2]].TILE_INFO > 1 and BOARD_MAP[next_brick[1]][next_brick[2]].TILE_INFO < 6 and memory.readbyte(BOMB[memory.readbyte(BOMB_QUANTITY_ADDRESS)+1].ACTIVE_INFO) == 0 then   
                            if BOARD_MAP[memory.readbyte(PLAYER_POSITION_X_ADDRESS)+1][memory.readbyte(PLAYER_POSITION_Y_ADDRESS)+1].TILE_INFO ~= 9 then
                                putBomb()
                                BOMB_FRAME_COUNT = 0
                            else
                                EXIT_DOOR_IS_NEARBY = 1
                            end
                        end
                        table.remove(current_path, 1)
                        goKillEnemyBehindTheWall(current_path)   -- move the player to the enemy, to kill it
                        return true     -- if reached a enemy returns true
                    end
                end
            end
            
            -- our current node coordinates
            local coord_x, coord_y

            -- call the verification to the left neighbor
            coord_x, coord_y = checkTheWholeBoardToChaseEnemies(current_node.LEFT_NEIGHBOR, visited)
            exploringBfs(queue, BOARD_MAP, current_path, coord_x, coord_y)

            -- call the verification to the up neighbor
            coord_x, coord_y = checkTheWholeBoardToChaseEnemies( current_node.UP_NEIGHBOR, visited)
            exploringBfs(queue, BOARD_MAP, current_path, coord_x, coord_y)

            -- call the verification to the right neighbor
            coord_x, coord_y = checkTheWholeBoardToChaseEnemies(current_node.RIGHT_NEIGHBOR, visited)
            exploringBfs(queue, BOARD_MAP, current_path, coord_x, coord_y)

            -- call the verification to the down neighbor
            coord_x, coord_y = checkTheWholeBoardToChaseEnemies(current_node.DOWN_NEIGHBOR, visited)
            exploringBfs(queue, BOARD_MAP, current_path, coord_x, coord_y)
        end
    end
    return false     -- if don't reached a enemy returns false
end

-- breadth-first search
local function bfs()
    -- every new stage we check for a new board to travel
    if memory.readbyte(STAGE_START_ADDRESS) == 0 or memory.readbyte(LIFE_LEFT_ADDRESS) ~= LIFE_CONTROLLER then
        local reached = stageStartUp()
        if reached then
            return
        end
    end

    -- if exists any bomb on the map the character have to search a place to hide
    if memory.readbyte(BOMB[memory.readbyte(BOMB_QUANTITY_ADDRESS)+1].ACTIVE_INFO) == 1 or memory.readbyte(BOMB_ANIMATION_ADDRESS_1) ~= 0 or memory.readbyte(BOMB_ANIMATION_ADDRESS_2) ~= 0 or memory.readbyte(BOMB_ANIMATION_ADDRESS_3) ~= 0 or EXIT_DOOR_IS_NEARBY == 1 then
        local reached = searchForSafePlace()
        if reached then
            return
        end
    end

    -- good news, is time to upgrade our skills
    if memory.readbyte(BONUS_ADDRESS) == 6 then
        local reached = searchForBonus()
        if reached then
            return
        end
    end

    -- now let's search for a brick to explode
    if memory.readbyte(ENEMIES_REMAINING_ADDRESS) == 0 and (memory.readbyte(BONUS_ADDRESS) ~= 0 or memory.readbyte(EXIT_DOOR_ADDRESS) == 4) then
        local reached = searchForBrick()
        if reached then
            return
        end
    end

    -- if there's a open door to enter, there's where we go
    if memory.readbyte(EXIT_DOOR_ADDRESS) == 8 and memory.readbyte(ENEMIES_REMAINING_ADDRESS) == 0 then
        local reached = searchForExit()
        if reached then
            return
        end
    end

    -- if there's no danger in map, gonna cause some trouble. Searching for the nearest enemy
    if memory.readbyte(ENEMIES_REMAINING_ADDRESS) > 0 then
        local reached = searchForEnemy()
        if reached then
            return
        end
    end

    -- if don't have enemies we can reach, let's break some bricks to open the map
    if memory.readbyte(ENEMIES_REMAINING_ADDRESS) > 0 then
        local reached = searchForEnemyInWholeBoard()
        if reached then
            return
        end
    end
end

-- main function
initializeGame()
initializeStage()
LIFE_CONTROLLER = memory.readbyte(LIFE_LEFT_ADDRESS)

-- loop to advance through frames
while true do
    boardUpdate()
    bfs()
    if memory.readbyte(BOMB[memory.readbyte(BOMB_QUANTITY_ADDRESS)+1].ACTIVE_INFO) == 1 then
        BOMB_FRAME_COUNT = BOMB_FRAME_COUNT + 1
    end
    FRAME_COUNTER = emu.framecount()
    emu.message("BFS: " .. emu.framecount())
    emu.frameadvance()  -- make the emulation on going, ATTENTION: this call is extremely important, without it the FCEUX will stop
end