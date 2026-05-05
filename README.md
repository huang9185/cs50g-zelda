# Legend of Zelda - Interactive Objects Update ⚔️

## Overview
A top-down action RPG built in Lua and LÖVE2D, emulating the classic dungeon-crawling mechanics of the Legend of Zelda.

## Custom Features
* **Interactive Pots:** Added liftable and throwable pots into the dungeon rooms. 
  * Players can face a pot and lift it (tracking the pot to the player's head).
  * Once thrown, the pot travels as a projectile at high speed in the direction the player is facing, damaging any enemies it collides with.
* **Heart Drops & Spawning:** Defeated enemies have a 1-in-5 chance to drop a consumable heart to heal the player. 
* **Visual Polish:** Implemented a fade-in transparency effect during the heart spawning animation to make item drops feel natural.
