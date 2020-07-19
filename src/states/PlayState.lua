--[[
    GD50
    Breakout Remake

    -- PlayState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents the state of the game in which we are actively playing;
    player should control the paddle, with the ball actively bouncing between
    the bricks, walls, and the paddle. If the ball goes below the paddle, then
    the player should lose one point of health and be taken either to the Game
    Over screen if at 0 health or the Serve screen otherwise.
]]

PlayState = Class{__includes = BaseState}

--[[
    We initialize what's in our PlayState via a state table that we pass between
    states as we go from playing to serving.
]]
function PlayState:enter(params)
    self.paddle = params.paddle
    self.bricks = params.bricks
    self.health = params.health
    self.score = params.score
    self.highScores = params.highScores
    self.balls = params.balls
    self.level = params.level
    self.hasKey = params.hasKey
    self.upgradePaddleScore = params.upgradePaddleScore

    self.recoverPoints = 5000

    -- give ball random starting velocity
    for l, ball in pairs(self.balls) do
      ball.dx = math.random(-50, 50)
      ball.dy = math.random(100, 200)
    end

end

function PlayState:update(dt)

    if self.paused then
        if love.keyboard.wasPressed('space') then
            self.paused = false
            gSounds['pause']:play()
        else
            return
        end
    elseif love.keyboard.wasPressed('space') then
        self.paused = true
        gSounds['pause']:play()
        return
    end

    -- update positions based on velocity
    self.paddle:update(dt)

    --update all of the balls
    for l, ball in pairs(self.balls) do
      ball:update(dt)

      if ball:collides(self.paddle) then
          -- raise ball above paddle in case it goes below it, then reverse dy
          ball.y = self.paddle.y - 8
          ball.dy = -ball.dy

          --
          -- tweak angle of bounce based on where it hits the paddle
          --

          -- if we hit the paddle on its left side while moving left...
          if ball.x < self.paddle.x + (self.paddle.width / 2) and self.paddle.dx < 0 then
              ball.dx = -50 + -(8 * (self.paddle.x + self.paddle.width / 2 - ball.x))

          -- else if we hit the paddle on its right side while moving right...
          elseif ball.x > self.paddle.x + (self.paddle.width / 2) and self.paddle.dx > 0 then
              ball.dx = 50 + (8 * math.abs(self.paddle.x + self.paddle.width / 2 - ball.x))
          end

          gSounds['paddle-hit']:play()
      end

      -- detect collision across all bricks with the ball
      for k, brick in pairs(self.bricks) do

        -- only check collision if we're in play
        if brick.inPlay and ball:collides(brick) then

          -- trigger the brick's hit function, which removes it from play
          -- if it is either not a locked brick or it is but the user has the key
          if (brick.color == 6 and brick.tier == 3) == false or self.hasKey == true then
            -- add to score
            self.score = self.score + (brick.tier * 200 + brick.color * 25)
            brick:hit()
          end

          -- if we have enough points, recover a point of health
          if self.score > self.recoverPoints then
              -- can't go above 3 health
              self.health = math.min(3, self.health + 1)

              -- multiply recover points by 2
              self.recoverPoints = math.min(100000, self.recoverPoints * 2)

              -- play recover sound effect
              gSounds['recover']:play()
          end

          -- go to our victory screen if there are no more bricks left
          if self:checkVictory() then
              gSounds['victory']:play()

              gStateMachine:change('victory', {
                  level = self.level,
                  paddle = self.paddle,
                  health = self.health,
                  score = self.score,
                  highScores = self.highScores,
                  --reset the number of balls to 1
                  balls = {self.balls[1]},
                  recoverPoints = self.recoverPoints,
                  --reset hasKey to false
                  hasKey = false,
                  upgradePaddleScore = self.upgradePaddleScore,
              })
          end

          -- upgrade size code
          -- if the score reaches the critical amount
          if self.score >= self.upgradePaddleScore then
            -- upgrade the paddle if it's not already at max
            if self.paddle.size < 4 then
              self.paddle.size = self.paddle.size + 1
            end

            --increase the upgrade paddle score according to the current size
            self.upgradePaddleScore = self.score + self.paddle.size * 200
          end

          --
          -- collision code for bricks
          --d
          -- we check to see if the opposite side of our velocity is outside of the brick;
          -- if it is, we trigger a collision on that side. else we're within the X + width of
          -- the brick and should check to see if the top or bottom edge is outside of the brick,
          -- colliding on the top or bottom accordingly
          --

          -- left edge; only check if we're moving right, and offset the check by a couple of pixels
          -- so that flush corner hits register as Y flips, not X flips
          if ball.x + 2 < brick.x and ball.dx > 0 then

              -- flip x velocity and reset position outside of brick
              ball.dx = -ball.dx
              ball.x = brick.x - 8

          -- right edge; only check if we're moving left, , and offset the check by a couple of pixels
          -- so that flush corner hits register as Y flips, not X flips
          elseif ball.x + 6 > brick.x + brick.width and ball.dx < 0 then

              -- flip x velocity and reset position outside of brick
              ball.dx = -ball.dx
              ball.x = brick.x + 32

          -- top edge if no X collisions, always check
          elseif ball.y < brick.y then

              -- flip y velocity and reset position outside of brick
              ball.dy = -ball.dy
              ball.y = brick.y - 8

          -- bottom edge if no X collisions or top collision, last possibility
          else

              -- flip y velocity and reset position outside of brick
              ball.dy = -ball.dy
              ball.y = brick.y + 16
          end

          -- slightly scale the y velocity to speed up the game, capping at +- 150
          if math.abs(ball.dy) < 150 then
              ball.dy = ball.dy * 1.02
          end

          -- only allow colliding with one brick, for corners
          break
        end
      end

      -- if ball goes below bounds, revert to serve state and decrease health
      if ball.y >= VIRTUAL_HEIGHT then
        self.health = self.health - 1
        gSounds['hurt']:play()

        if self.health == 0 then
            gStateMachine:change('game-over', {
              score = self.score,
              highScores = self.highScores
            })
        else
          --If there are several balls in play, remove one
          if #self.balls > 1 then
            table.remove(self.balls)
          end

          --If the paddle size is greater than 1, decrease the size by one
          if self.paddle.size > 1 then
            self.paddle.size = self.paddle.size - 1
          end

          gStateMachine:change('serve', {
            paddle = self.paddle,
            bricks = self.bricks,
            health = self.health,
            score = self.score,
            highScores = self.highScores,
            level = self.level,
            recoverPoints = self.recoverPoints,
            hasKey = self.hasKey,
            upgradePaddleScore = self.upgradePaddleScore,
          })
        end
      end
    end

    --functions to continuously modify powers
    for l, brick in pairs(self.bricks) do
      --if the power is released from the brick
      if brick.power ~=nil and brick.inPlay == false then
        --update the position of the powerup, since it's brick is destroyed
        brick.power:update(dt)
        -- apply the power if the power collides with the paddle
        if brick.power:collides(self.paddle) then
          if brick.power:getName() == "Double" then
            --hide the powerup
            brick.power.y = brick.power.y + 100

            --bring in the second ball with a similar location as the initial ball
            local ball2 = Ball()
            ball2.skin = math.random(7)
            ball2.x = self.balls[1].x
            ball2.y = self.balls[1].y

            --but a different x velocity
            ball2.dx = self.balls[1].dx + math.random(-100, 100)
            ball2.dy = self.balls[1].dy

            table.insert(self.balls, ball2)
          elseif brick.power:getName() == "Key" then
            gSounds["paddle-hit"]:play()
            gSounds["score"]:play()
            brick.power.y = brick.power.y + 100
            self.hasKey = true
            self.score = self.score + 500

            --change the locked brick into a normal brick
            for l, brick in pairs(self.bricks) do
              if brick.color == 6 and brick.tier == 3 then
                brick.color = 1
                brick.tier = math.random(3)
              end
            end
          end

        end
      end
    end



    -- for rendering particle systems
    for k, brick in pairs(self.bricks) do
        brick:update(dt)
    end

    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end
end

function PlayState:render()
    -- render bricks
    for k, brick in pairs(self.bricks) do
        brick:render()
    end

    -- render all particle systems
    for k, brick in pairs(self.bricks) do
        brick:renderParticles()
    end

    -- render all powerups systems
    for k, brick in pairs(self.bricks) do
        if brick.power then
          brick.power:render()
        end
    end

    self.paddle:render()

    for l, ball in pairs(self.balls) do
      ball:render()
    end

    renderScore(self.score)
    renderHealth(self.health)

    -- pause text, if paused
    if self.paused then
        love.graphics.setFont(gFonts['large'])
        love.graphics.printf("PAUSED", 0, VIRTUAL_HEIGHT / 2 - 16, VIRTUAL_WIDTH, 'center')
    end
end

function PlayState:checkVictory()
    for k, brick in pairs(self.bricks) do
        if brick.inPlay then
            return false
        end
    end
    return true
end
