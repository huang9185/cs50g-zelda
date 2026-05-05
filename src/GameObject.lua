--[[
    GD50
    Legend of Zelda

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

GameObject = Class{}

function GameObject:init(def, x, y)
    
    -- string identifying this object type
    self.type = def.type
    self.texture = def.texture
    self.frame = def.frame or 1

    -- whether it acts as an obstacle or not
    self.solid = def.solid

    self.defaultState = def.defaultState
    self.state = self.defaultState
    self.states = def.states

    -- dimensions
    self.x = x
    self.y = y
    self.width = def.width
    self.height = def.height
    self.test = self.x > self.width

    -- default empty collision callback
    self.collidable = def.collidable
    self.onCollide = function() end

    -- default empty consume callback
    self.consumable = def.consumable or false
    self.onConsume = function() end

    -- for heart
    self.spawningTimer = 1

    -- for pot
    self.lifted = def.lifted
    self.travelSpeed = def.travelSpeed
end

function GameObject:update(dt)

    -- for heart
    if self.spawning then
        Timer.tween(1, {
            [self] = {x = math.random(MAP_RENDER_OFFSET_X + TILE_SIZE, VIRTUAL_WIDTH - TILE_SIZE * 2 - 16),
                        y = math.random(MAP_RENDER_OFFSET_Y + TILE_SIZE,
                        VIRTUAL_HEIGHT - (VIRTUAL_HEIGHT - MAP_HEIGHT * TILE_SIZE) + MAP_RENDER_OFFSET_Y - TILE_SIZE - 16)}
        }):finish(function()
            self.spawning = false
        end)
    end 

    -- when pot is thrown
    if self.onFire then
        -- update pot position according to player direction
        if self.onFireDirection == 'left' then
            self.x = self.x - self.travelSpeed * dt
        elseif self.onFireDirection == 'right' then
            self.x = self.x + self.travelSpeed * dt
        elseif self.onFireDirection == 'down' then
            self.y = self.y + self.travelSpeed * dt
        else
            self.y = self.y - self.travelSpeed * dt
        end
    end
end

function GameObject:render(adjacentOffsetX, adjacentOffsetY)
    if self.spawning then
        love.graphics.setColor(1, 1, 1, 64/255)
    end

    love.graphics.draw(gTextures[self.texture], gFrames[self.texture][self.states[self.state].frame or self.frame],
        self.x + adjacentOffsetX, self.y + adjacentOffsetY)
end