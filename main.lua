local map = require 'map'
local intro = require 'Intro'

local groundColour = {0, 98, 255}
local backColour = {25,25,25}--{84, 0, 153, 1}

local player = {x=400, y=100, w=40, s=40, r=8, xV=0, yV=0, squish = true}
local screenShake = {x=0,y=0,xV=0,yV=0}

local ConnectedController = false
local holdingJump = false

local hit = love.audio.newSource("hit.ogg", "static")
local jump = love.audio.newSource("jump.ogg", "static")
local respawn = love.audio.newSource("respawn.wav", "static")

function love.load()
	intro:load()
	love.graphics.setBackgroundColour(backColour[1]/255, backColour[2]/255, backColour[3]/255)
end

function love.update(dt)
	intro:update(dt)

	if intro.timer > 0.5 then
		screenShake.xV = screenShake.xV + (0-screenShake.x)*0.2
		screenShake.yV = screenShake.yV + (0-screenShake.y)*0.2
		screenShake.yV = screenShake.yV*0.7
		screenShake.xV = screenShake.xV*0.7

		screenShake.x = screenShake.x + screenShake.xV
		screenShake.y = screenShake.y + screenShake.yV

		do -- Player Update
			local moving = false
			local controllerDirection = (ConnectedController and ConnectedController:getGamepadAxis("leftx")) or 0
			if love.keyboard.isDown("left") or love.keyboard.isDown("a") or controllerDirection < -0.3 then
				player.xV = player.xV - 1
				moving = true
			end
			if love.keyboard.isDown("right") or love.keyboard.isDown("d") or controllerDirection > 0.3 then
				player.xV = player.xV + 1
				moving = true
			end

			if love.keyboard.isDown("r") or (ConnectedController and ConnectedController:isGamepadDown("dpleft", "dpright", "dpup", "dpdown")) or player.y > 2000 then
				player = {x=400, y=100, w=40, s=40, r=8, xV=0, yV=0, squish = true}
				respawn:setVolume(0.3)
				respawn:play()
			end
			if not moving then
				player.xV = player.xV*0.9
			end
			player.xV = player.xV*0.9
			player.x = player.x + player.xV

			for i=1, #map do
				if map[i]['type'] == 'ground' then
					local top = player.y-player.s/2
					local bottom = player.y+player.s/2
					local right = player.x-player.s/2
					local left = player.x+player.s/2
					if bottom > map[i].y and top < map[i].y+map[i].h and left > map[i].x and right < map[i].x+map[i].w and 1
					and bottom-player.yV > map[i].y and top-player.yV < map[i].y+map[i].h	then
						screenShake.xV = screenShake.xV+player.xV
						if math.abs(player.xV) > 1 then
							hit:setVolume((math.abs(player.xV)-1)/10)
							hit:setPitch(0.8 + love.math.random()*0.8)
							hit:stop() hit:play()
						end


						player.x = (right < map[i].x and map[i].x-player.s/2) or map[i].x+map[i].w+player.s/2
						player.xV = 0

						local keyRight = love.keyboard.isDown("right") or love.keyboard.isDown("d") or controllerDirection > 0.3
						local keyLeft = love.keyboard.isDown("left") or love.keyboard.isDown("a") or controllerDirection < -0.3
						if ((keyRight) and right < map[i].x)
						or ((keyLeft) and not (right < map[i].x)) then
							player.yV = math.min(player.yV, 2)

							if love.keyboard.isDown("space") or love.keyboard.isDown("up") or love.keyboard.isDown("w") 
							or (ConnectedController and ConnectedController:isGamepadDown("a", "y")) then
								player.yV = -15
								if keyRight then
									player.xV = -10
								else
									player.xV = 10
								end
								screenShake.yV = screenShake.yV-player.yV
								jump:setVolume(0.1)
								jump:setPitch(1.05)
								jump:stop() jump:play()
							end
						end
					end
				end
			end

			player.squish = true
			player.yV = player.yV + 1
			player.y = player.y + player.yV

			for i=1, #map do
				if map[i]['type'] == 'ground' then
					local top = player.y-player.s/2
					local bottom = player.y+player.s/2
					local right = player.x-player.s/2
					local left = player.x+player.s/2
					if bottom > map[i].y and top < map[i].y+map[i].h and left > map[i].x and right < map[i].x+map[i].w then
						player.squish = false
						player.w = (math.abs(player.yV) > 5 and player.s+math.abs(player.yV)*0.5) or player.w
						screenShake.yV = screenShake.yV+player.yV
						if math.abs(player.yV) > 1 then
							hit:setVolume((math.abs(player.xV)-1)/10)
							hit:setPitch(0.8 + love.math.random()*0.8)
							hit:stop() hit:play()
						end


						player.y = (top < map[i].y and map[i].y-player.s/2) or map[i].y+map[i].h+player.s/2
						player.yV = 0

						if top < map[i].y and (love.keyboard.isDown("space") or love.keyboard.isDown("up") or love.keyboard.isDown("w") 
						or (ConnectedController and ConnectedController:isGamepadDown("a", "y"))) then
							player.yV = -15
							screenShake.yV = screenShake.yV-player.yV
							jump:setVolume(0.1)
							jump:setPitch(1.05)
							jump:stop() jump:play()
						end
					end
				end
			end
		end
	end
end

function love.draw()
	if player.squish == true and player.yV < 0 then
		player.w= player.w + ((player.s-math.abs(player.yV))-player.w)*0.4
	else
		player.w = player.w + (player.s-player.w)*0.4
	end

	love.graphics.translate(screenShake.x, screenShake.y)
	love.graphics.translate(love.graphics.getWidth()/2-400, love.graphics.getHeight()/2-300)

	love.graphics.setColour(1,1,1, 0.3)
	love.graphics.rectangle('fill', player.x-player.w/2-player.r, player.y-player.s/2-player.r, player.w+player.r*2, player.s+player.r*2, player.r*2)
	love.graphics.setColour(1,1,1)
	love.graphics.rectangle('fill', player.x-player.w/2, player.y-player.s/2, player.w, player.s, player.r)

	love.graphics.setColour(groundColour[1]/255, groundColour[2]/255, groundColour[3]/255)
	for i=1, #map do
		if map[i]['type'] == 'ground' then
			love.graphics.rectangle('fill', map[i]['x'], map[i]['y'], map[i]['w'], map[i]['h'])
		end
	end

	intro:draw()
end

function love.joystickadded(j)
	ConnectedController = j
end
function love.joystickremoved(j)
	if j == ConnectedController then
		ConnectedController = false
	end
end
-- function love.gamepadpressed(j, b)
-- 	if j == ConnectedController then
-- 		if b == "y" or b == "a" then
-- 			holdingJump = true
-- 		end
-- 	end
-- end