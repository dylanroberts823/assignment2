--[[
    GD50
    Breakout Remake

    -- ServeState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    The state in which we are waiting to serve the ball; here, we are
    basically just moving the paddle left and right with the ball until we
    press Enter, though everything in the actual game now should render in
    preparation for the serve, including our current health and score, as
    well as the level we're on.
]]

ServeState = Class{__includes = BaseState}

function ServeState:enter(params)
    -- grab game state from params
    self.paddle = params.paddle
    self.bricks = params.bricks
    self.health = params.health
    self.score = params.score
    self.highScores = params.highScores
    self.level = params.level
    self.recoverPoints = params.recoverPoints
    self.hasKey = params.hasKey

    self.balls = {}

    -- init new ball (random color for fun)
    self.ball = Ball()
    self.ball.skin = math.random(7)

    -- add the ball to the balls table
    table.insert(self.balls, self.ball)

    -- if the powerup doesn't exist, init it and the powerBrick
    if params.powerup == nil then
      self.powerup = Powerup({powerupIndex = 1})
      -- assign the powerup to a random brick
      self.powerBrick = self.bricks[math.random(1, #self.bricks)]

      -- place the powerup's location in the center of the powerBrick
      self.powerup.x = self.powerBrick.x + (self.powerBrick.width / 2) - 8
      self.powerup.y = self.powerBrick.y
    -- since the powerup exists, assign it
    else
      self.powerup = params.powerup
      self.powerBrick = params.powerBrick
    end
end

function ServeState:update(dt)
    -- have the ball track the player
    self.paddle:update(dt)
    self.ball.x = self.paddle.x + (self.paddle.width / 2) - 4
    self.ball.y = self.paddle.y - 8



    if love.keyboard.wasPressed('enter') or love.keyboard.wasPressed('return') then
        -- pass in all important state info to the PlayState
        gStateMachine:change('play', {
            paddle = self.paddle,
            bricks = self.bricks,
            health = self.health,
            score = self.score,
            highScores = self.highScores,
            balls = self.balls,
            level = self.level,
            recoverPoints = self.recoverPoints,
            powerup = self.powerup,
            powerBrick = self.powerBrick,
            hasKey = self.hasKey
        })
    end

    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end
end

function ServeState:render()
    self.paddle:render()
    self.ball:render()

    for k, brick in pairs(self.bricks) do
        brick:render()
    end

    -- render all powerups systems
    for k, brick in pairs(self.bricks) do
        if brick.power then
          brick.power:render()
        end
    end

    --render the powerup after the bricks so that it's visible
    self.powerup:render()

    renderScore(self.score)
    renderHealth(self.health)

    love.graphics.setFont(gFonts['large'])
    love.graphics.printf('Level ' .. tostring(self.level), 0, VIRTUAL_HEIGHT / 3,
        VIRTUAL_WIDTH, 'center')

    love.graphics.setFont(gFonts['medium'])
    love.graphics.printf('Press Enter to serve!', 0, VIRTUAL_HEIGHT / 2,
        VIRTUAL_WIDTH, 'center')
end
