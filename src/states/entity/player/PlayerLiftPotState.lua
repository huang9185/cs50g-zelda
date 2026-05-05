PlayerLiftPotState = Class{__includes = BaseState}

function PlayerLiftPotState:init(player, dungeon)
    self.entity = player
    self.dungeon = dungeon

    self.entity.offsetY = 5
    self.entity.offsetX = 0
    self.timer = 0
end

function PlayerLiftPotState:update(dt)
    self.timer = self.timer + dt
    if self.entity.direction == 'left' then
        self.entity:changeAnimation('lift-pot-left')
    elseif self.entity.direction == 'right' then
        self.entity:changeAnimation('lift-pot-right')
    elseif self.entity.direction == 'down' then
        self.entity:changeAnimation('lift-pot-down')
    else
        self.entity:changeAnimation('lift-pot-up')
    end

    -- no collision detection when picking up a pot
    if self.timer > 0.465 then
        self.entity:changeState('idle-with-pot')
    end
end

function PlayerLiftPotState:render()
    local anim = self.entity.currentAnimation
    love.graphics.draw(gTextures[anim.texture], gFrames[anim.texture][anim:getCurrentFrame()],
        math.floor(self.entity.x - self.entity.offsetX), math.floor(self.entity.y - self.entity.offsetY))
    
    -- love.graphics.setColor(255, 0, 255, 255)
    -- love.graphics.rectangle('line', self.entity.x, self.entity.y, self.entity.width, self.entity.height)
    -- love.graphics.setColor(255, 255, 255, 255)
end