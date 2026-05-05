PlayerThrowPotState = Class{__includes = BaseState}

function PlayerThrowPotState:init(player, dungeon)
    self.player = player
    self.dungeon = dungeon
    self.timer = 0.465

    self.player:changeAnimation('throw-pot-' .. self.player.direction)
    self.dungeon.currentRoom:firePot()
end

function PlayerThrowPotState:update(dt)
    if self.timer <= 0 then
        self.player:changeState('idle')
    end

    self.timer = self.timer - dt
end

function PlayerThrowPotState:render()
    local anim = self.player.currentAnimation
    love.graphics.draw(gTextures[anim.texture], gFrames[anim.texture][anim:getCurrentFrame()],
        math.floor(self.player.x - self.player.offsetX), math.floor(self.player.y - self.player.offsetY))
end