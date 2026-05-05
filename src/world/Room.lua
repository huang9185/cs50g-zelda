--[[
    GD50
    Legend of Zelda

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

Room = Class{}

function Room:init(player)
    self.width = MAP_WIDTH
    self.height = MAP_HEIGHT

    self.tiles = {}
    self:generateWallsAndFloors()

    -- entities in the room
    self.entities = {}
    self:generateEntities()

    -- game objects in the room
    self.objects = {}
    self:generateObjects()

    -- doorways that lead to other dungeon rooms
    self.doorways = {}
    table.insert(self.doorways, Doorway('top', false, self))
    table.insert(self.doorways, Doorway('bottom', false, self))
    table.insert(self.doorways, Doorway('left', false, self))
    table.insert(self.doorways, Doorway('right', false, self))

    -- reference to player for collisions, etc.
    self.player = player

    -- used for centering the dungeon rendering
    self.renderOffsetX = MAP_RENDER_OFFSET_X
    self.renderOffsetY = MAP_RENDER_OFFSET_Y

    -- used for drawing when this room is the next room, adjacent to the active
    self.adjacentOffsetX = 0
    self.adjacentOffsetY = 0

    -- to track pot lifting (0.465)
    self.trackPotLiftingTimer = 0
    self.trackPlayer = false

    self.enemySpawnedHeart = {}
end

--[[
    Randomly creates an assortment of enemies for the player to fight.
]]
function Room:generateEntities()
    local types = {'skeleton', 'slime', 'bat', 'ghost', 'spider'}

    for i = 1, 10 do
        local type = types[math.random(#types)]

        table.insert(self.entities, Entity {
            animations = ENTITY_DEFS[type].animations,
            walkSpeed = ENTITY_DEFS[type].walkSpeed or 20,

            -- ensure X and Y are within bounds of the map
            x = math.random(MAP_RENDER_OFFSET_X + TILE_SIZE,
                VIRTUAL_WIDTH - TILE_SIZE * 2 - 16),
            y = math.random(MAP_RENDER_OFFSET_Y + TILE_SIZE,
                VIRTUAL_HEIGHT - (VIRTUAL_HEIGHT - MAP_HEIGHT * TILE_SIZE) + MAP_RENDER_OFFSET_Y - TILE_SIZE - 16),
            
            width = 16,
            height = 16,

            health = 1
        })

        self.entities[i].stateMachine = StateMachine {
            ['walk'] = function() return EntityWalkState(self.entities[i]) end,
            ['idle'] = function() return EntityIdleState(self.entities[i]) end
        }

        self.entities[i]:changeState('walk')
    end
end

--[[
    Randomly creates an assortment of obstacles for the player to navigate around.
]]
function Room:generateObjects()

    -- switch
    local switch_x = math.random(MAP_RENDER_OFFSET_X + TILE_SIZE, VIRTUAL_WIDTH - TILE_SIZE * 2 - 16)
    local switch_y = math.random(MAP_RENDER_OFFSET_Y + TILE_SIZE,
    VIRTUAL_HEIGHT - (VIRTUAL_HEIGHT - MAP_HEIGHT * TILE_SIZE) + MAP_RENDER_OFFSET_Y - TILE_SIZE - 16)

    local switch = GameObject(
        GAME_OBJECT_DEFS['switch'],
        switch_x,
        switch_y
    )

    -- define a function for the switch that will open all doors in the room
    switch.onCollide = function()
        if switch.state == 'unpressed' then
            switch.state = 'pressed'
            
            -- open every door in the room if we press the switch
            for k, doorway in pairs(self.doorways) do
                doorway.open = true
            end

            gSounds['door']:play()
        end
    end

    -- add to list of objects in scene (only one switch for now)
    table.insert(self.objects, switch)

    -- pot
    if math.random(1) == 2 then
        goto end_pot_generation
    end

    local pot_x = math.random(MAP_RENDER_OFFSET_X + TILE_SIZE, VIRTUAL_WIDTH - TILE_SIZE * 2 - 16)
    local pot_y = math.random(MAP_RENDER_OFFSET_Y + TILE_SIZE,
    VIRTUAL_HEIGHT - (VIRTUAL_HEIGHT - MAP_HEIGHT * TILE_SIZE) + MAP_RENDER_OFFSET_Y - TILE_SIZE - 16)

    while pot_x == switch_x and pot_y == switch_y do
        pot_x = math.random(MAP_RENDER_OFFSET_X + TILE_SIZE, VIRTUAL_WIDTH - TILE_SIZE * 2 - 16)
        pot_y = math.random(MAP_RENDER_OFFSET_Y + TILE_SIZE,
                            VIRTUAL_HEIGHT - (VIRTUAL_HEIGHT - MAP_HEIGHT * TILE_SIZE) + MAP_RENDER_OFFSET_Y - TILE_SIZE - 16)
    end

    local pot = GameObject(
        GAME_OBJECT_DEFS['pot'],
        pot_x,
        pot_y
    )

    -- stop player from walking into the pot
    table.insert(self.objects, pot)

    ::end_pot_generation::
end

--[[
    Generates the walls and floors of the room, randomizing the various varieties
    of said tiles for visual variety.
]]
function Room:generateWallsAndFloors()
    for y = 1, self.height do
        table.insert(self.tiles, {})

        for x = 1, self.width do
            local id = TILE_EMPTY

            if x == 1 and y == 1 then
                id = TILE_TOP_LEFT_CORNER
            elseif x == 1 and y == self.height then
                id = TILE_BOTTOM_LEFT_CORNER
            elseif x == self.width and y == 1 then
                id = TILE_TOP_RIGHT_CORNER
            elseif x == self.width and y == self.height then
                id = TILE_BOTTOM_RIGHT_CORNER
            
            -- random left-hand walls, right walls, top, bottom, and floors
            elseif x == 1 then
                id = TILE_LEFT_WALLS[math.random(#TILE_LEFT_WALLS)]
            elseif x == self.width then
                id = TILE_RIGHT_WALLS[math.random(#TILE_RIGHT_WALLS)]
            elseif y == 1 then
                id = TILE_TOP_WALLS[math.random(#TILE_TOP_WALLS)]
            elseif y == self.height then
                id = TILE_BOTTOM_WALLS[math.random(#TILE_BOTTOM_WALLS)]
            else
                id = TILE_FLOORS[math.random(#TILE_FLOORS)]
            end
            
            table.insert(self.tiles[y], {
                id = id
            })
        end
    end
end

function Room:firePot()
    for k, object in pairs(self.objects) do
        if object.type == 'pot' then

            -- set the flag to trigger updates in Game Object Class
            object.onFire = true
            object.onFireDirection = self.player.direction

            -- stop pot from clamping to player position
            object.trackPlayer = false

            -- record position before travel
            object.originX = object.x
            object.originY = object.y
        end
    end
end

function Room:potPlayerCollide(wallCheck)
    for k, object in pairs(self.objects) do
        if object.type == 'pot' and object.lifted == false and self.player:collides(object) then

            -- player must be facing the pot to collide
            if (self.player.direction == 'left' and object.x < self.player.x) or
                (self.player.direction == 'right' and object.x > self.player.x) or
                (self.player.direction == 'down' and object.y > self.player.y) or
                (self.player.direction == 'up' and object.y < self.player.y) then

                if not wallCheck then
                    object.lifted = true
                    self.trackPlayer = true
                    self.trackPotLiftingTimer = 0.465
                end
                return true
            end
        end
    end

    return false
end

function Room:update(dt)
    
    -- don't update anything if we are sliding to another room (we have offsets)
    if self.adjacentOffsetX ~= 0 or self.adjacentOffsetY ~= 0 then return end

    self.player:update(dt)

    -- update pot lifting timer
    if self.trackPlayer then
        self.trackPotLiftingTimer = self.trackPotLiftingTimer - dt
    end

    if self.trackPotLiftingTimer <= 0  and self.trackPlayer then
        self.trackPlayer = false
        self.trackPotLiftingTimer = 0.465
        for k, obj in pairs(self.objects) do
            if obj.type == 'pot' then
                obj.trackPlayer = true
            end
        end
    end

    for i = #self.entities, 1, -1 do
        local entity = self.entities[i]

        -- remove entity from the table if health is <= 0
        if entity.health <= 0 and (not entity.dead) then
            entity.dead = true

            if math.random(5) == 1 and not self.enemySpawnedHeart[entity] then

                gSounds['drop_heart']:play()
                local heart = GameObject(
                    GAME_OBJECT_DEFS['heart'],
                    entity.x+self.renderOffsetX,
                    entity.y+self.renderOffsetY
                )

                heart.spawning = true

                -- define a function for the heart that will add health to the player when picked up
                heart.onConsume = function()
                    gSounds['pickup']:play()
                    self.player.health = math.min(6, self.player.health+2)
                end

                table.insert(self.objects, heart)
                self.enemySpawnedHeart[entity] = true
                goto endFunction
            end

        elseif not entity.dead then
            entity:processAI({room = self}, dt)
            entity:update(dt)
        end

        -- collision between the player and entities in the room
        if not entity.dead and self.player:collides(entity) and not self.player.invulnerable then
            gSounds['hit-player']:play()
            self.player:damage(1)
            self.player:goInvulnerable(1.5)

            if self.player.health == 0 then
                gStateMachine:change('game-over')
            end
        end
    end

    for k, object in pairs(self.objects) do
        object:update(dt)

        -- for heart vanishing and spawning
        if object.spawning then
            goto end_object_update
        end

        -- for pot
        if object.trackPlayer then
            object.x = self.player.x
            object.y = self.player.y - 12
            goto end_object_update

        elseif object.onFire then

            -- calculate travel distance in terms of tiles
            local tilesTravelled = math.floor(math.abs(object.x - object.originX) / TILE_SIZE) + 
                        math.floor(math.abs(object.y - object.originY) / TILE_SIZE)
            local bottomEdge = VIRTUAL_HEIGHT - (VIRTUAL_HEIGHT - MAP_HEIGHT * TILE_SIZE) 
                        + MAP_RENDER_OFFSET_Y - TILE_SIZE

            -- check wall collision
            if (object.onFireDirection == 'left' and object.x <= MAP_RENDER_OFFSET_X + TILE_SIZE) or
                (object.onFireDirection == 'right' and object.x + object.width >= VIRTUAL_WIDTH - TILE_SIZE * 2) or
                (object.onFireDirection == 'down' and object.y + object.height >= bottomEdge) or
                (object.onFireDirection == 'up' and object.y <= MAP_RENDER_OFFSET_Y + TILE_SIZE - object.height / 2) then 

                -- play sounds and make pot disappear
                gSounds['hit-wall']:play()
                table.remove(self.objects, k)

            -- check travel distance
            elseif tilesTravelled >= 4 then
                gSounds['pot-break']:play()
                table.remove(self.objects, k)

            -- check enemies collision
            else
                for m, entity in pairs(self.entities) do
                    if not entity.dead and entity:collides(object) then
                        entity:damage(1)
                        object.onFire = false
                        table.remove(self.objects, k)
                        gSounds['hit-enemy']:play()
                        goto end_object_update
                    end
                end
            end
        end

        -- trigger collision callback on object
        if self.player:collides(object) then
            if object.solid then
                self.player.intoSolid = true
            end

            if object.collidable then
                object:onCollide()
            elseif object.consumable then
                object.onConsume(player, object)
                table.remove(self.objects,k)
            end
        end
        ::end_object_update::
    end
    ::endFunction::
end

function Room:render()
    for y = 1, self.height do
        for x = 1, self.width do
            local tile = self.tiles[y][x]
            love.graphics.draw(gTextures['tiles'], gFrames['tiles'][tile.id],
                (x - 1) * TILE_SIZE + self.renderOffsetX + self.adjacentOffsetX, 
                (y - 1) * TILE_SIZE + self.renderOffsetY + self.adjacentOffsetY)
        end
    end

    -- render doorways; stencils are placed where the arches are after so the player can
    -- move through them convincingly
    for k, doorway in pairs(self.doorways) do
        doorway:render(self.adjacentOffsetX, self.adjacentOffsetY)
    end

    for k, object in pairs(self.objects) do
        object:render(self.adjacentOffsetX, self.adjacentOffsetY)
    end

    for k, entity in pairs(self.entities) do
        if not entity.dead then entity:render(self.adjacentOffsetX, self.adjacentOffsetY) end
    end

    -- stencil out the door arches so it looks like the player is going through
    love.graphics.stencil(function()
        
        -- left
        love.graphics.rectangle('fill', -TILE_SIZE - 6, MAP_RENDER_OFFSET_Y + (MAP_HEIGHT / 2) * TILE_SIZE - TILE_SIZE,
            TILE_SIZE * 2 + 6, TILE_SIZE * 2)
        
        -- right
        love.graphics.rectangle('fill', MAP_RENDER_OFFSET_X + (MAP_WIDTH * TILE_SIZE),
            MAP_RENDER_OFFSET_Y + (MAP_HEIGHT / 2) * TILE_SIZE - TILE_SIZE, TILE_SIZE * 2 + 6, TILE_SIZE * 2)
        
        -- top
        love.graphics.rectangle('fill', MAP_RENDER_OFFSET_X + (MAP_WIDTH / 2) * TILE_SIZE - TILE_SIZE,
            -TILE_SIZE - 6, TILE_SIZE * 2, TILE_SIZE * 2 + 12)
        
        --bottom
        love.graphics.rectangle('fill', MAP_RENDER_OFFSET_X + (MAP_WIDTH / 2) * TILE_SIZE - TILE_SIZE,
            VIRTUAL_HEIGHT - TILE_SIZE - 6, TILE_SIZE * 2, TILE_SIZE * 2 + 12)
    end, 'replace', 1)

    love.graphics.setStencilTest('less', 1)
    
    if self.player then
        self.player:render()
    end

    love.graphics.setStencilTest()

    --
    -- DEBUG DRAWING OF STENCIL RECTANGLES
    --

    -- love.graphics.setColor(255, 0, 0, 100)
    
    -- -- left
    -- love.graphics.rectangle('fill', -TILE_SIZE - 6, MAP_RENDER_OFFSET_Y + (MAP_HEIGHT / 2) * TILE_SIZE - TILE_SIZE,
    -- TILE_SIZE * 2 + 6, TILE_SIZE * 2)

    -- -- right
    -- love.graphics.rectangle('fill', MAP_RENDER_OFFSET_X + (MAP_WIDTH * TILE_SIZE),
    --     MAP_RENDER_OFFSET_Y + (MAP_HEIGHT / 2) * TILE_SIZE - TILE_SIZE, TILE_SIZE * 2 + 6, TILE_SIZE * 2)

    -- -- top
    -- love.graphics.rectangle('fill', MAP_RENDER_OFFSET_X + (MAP_WIDTH / 2) * TILE_SIZE - TILE_SIZE,
    --     -TILE_SIZE - 6, TILE_SIZE * 2, TILE_SIZE * 2 + 12)

    -- --bottom
    -- love.graphics.rectangle('fill', MAP_RENDER_OFFSET_X + (MAP_WIDTH / 2) * TILE_SIZE - TILE_SIZE,
    --     VIRTUAL_HEIGHT - TILE_SIZE - 6, TILE_SIZE * 2, TILE_SIZE * 2 + 12)
    
    -- love.graphics.setColor(255, 255, 255, 255)
end