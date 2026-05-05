PlayerIdleWithPotState = Class{__includes = BaseState}

function PlayerIdleWithPotState:init(player, dungeon)
    self.player = player

    self.player:changeAnimation('idle-' .. self.player.direction .. '-with-pot')
end

function PlayerIdleWithPotState:update(dt)
    if love.keyboard.isDown('left') or love.keyboard.isDown('right') or
       love.keyboard.isDown('up') or love.keyboard.isDown('down') then
        self.player:changeState('walk-with-pot')
    end

    if love.keyboard.wasPressed('return') or love.keyboard.wasPressed('enter') then
        self.player:changeState('throw-pot')
    end
end

function PlayerIdleWithPotState:render()
    local anim = self.player.currentAnimation
    love.graphics.draw(gTextures[anim.texture], gFrames[anim.texture][anim:getCurrentFrame()],
        math.floor(self.player.x - self.player.offsetX), math.floor(self.player.y - self.player.offsetY))
end