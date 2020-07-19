--[[
    GD50
    Breakout Remake

    -- StartState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents the state that the game is in when we've just completed a level.
    Very similar to the ServeState, except here we increment the level
]]

VictoryState = Class{__includes = BaseState}

function VictoryState:enter(params)
    self.level = params.level
    self.score = params.score
    self.highScores = params.highScores
    self.paddle = params.paddle
    self.health = params.health
    self.balls = params.balls
    self.recoverPoints = params.recoverPoints
    self.upgradePaddleScore = params.upgradePaddleScore
end

function VictoryState:update(dt)
    self.paddle:update(dt)

    -- have the ball track the player
    for l, ball in pairs(self.balls) do
      ball.x = self.paddle.x + (self.paddle.width / 2) - 4
      ball.y = self.paddle.y - 8
    end

    -- go to play screen if the player presses Enter
    if love.keyboard.wasPressed('enter') or love.keyboard.wasPressed('return') then
        gStateMachine:change('serve', {
            level = self.level + 1,
            bricks = LevelMaker.createMap(self.level + 1),
            paddle = self.paddle,
            health = self.health,
            score = self.score,
            highScores = self.highScores,
            recoverPoints = self.recoverPoints,
            upgradePaddleScore = self.upgradePaddleScore,
        })
    end
end

function VictoryState:render()
    self.paddle:render()
    for l, ball in pairs(self.balls) do
      ball:render()
    end

    renderHealth(self.health)
    renderScore(self.score)

    -- level complete text
    love.graphics.setFont(gFonts['large'])
    love.graphics.printf("Level " .. tostring(self.level) .. " complete!",
        0, VIRTUAL_HEIGHT / 4, VIRTUAL_WIDTH, 'center')

    -- instructions text
    love.graphics.setFont(gFonts['medium'])
    love.graphics.printf('Press Enter to serve!', 0, VIRTUAL_HEIGHT / 2,
        VIRTUAL_WIDTH, 'center')
end
