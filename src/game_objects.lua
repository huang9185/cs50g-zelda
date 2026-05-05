--[[
    GD50
    Legend of Zelda

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

GAME_OBJECT_DEFS = {
    ['switch'] = {
        type = 'switch',
        texture = 'switches',
        frame = 2,
        width = 16,
        height = 16,
        solid = false,
        collidable = true,
        consumable = false,
        defaultState = 'unpressed',
        collidable = true,
        states = {
            ['unpressed'] = {
                frame = 2
            },
            ['pressed'] = {
                frame = 1
            }
        }
    },
    ['heart'] = {
        type = 'heart',
        texture = 'hearts',
        frame = 5,
        width = 16,
        height = 16,
        solid = false,
        collidable = false,
        consumable = true,
        defaultState = 'unpicked',
        states = {
            ['unpicked'] = {
                frame = 5
            }
        }
    },
    ['pot'] = {
        type = 'pot',
        texture = 'pots',
        width = 16,
        height = 16,
        solid = true,
        collidable = true,
        defaultState = 'unpicked',
        lifted = false,
        travelSpeed = 60,
        states = {
            ['unpicked'] = {
                frame = math.random(14, 16)
            }
        }
    }
}