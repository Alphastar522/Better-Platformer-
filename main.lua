local tileSize = 16
local terrain = {}
local terrainTileCount = 200
local screenWidth, screenHeight = 800, 600
baseY = 500 -- Make baseY global

function love.load()
    love.window.setTitle("Platformer Test")
    love.window.setMode(screenWidth, screenHeight, {resizable = false})

    groundTexture = love.graphics.newImage("assets/nature_ground.png")
    groundTexture:setWrap("repeat", "clamp")

    -- Flat terrain generation: no caves, no variation
    for i = 1, terrainTileCount do
        terrain[i] = { x = (i-1)*tileSize, y = baseY, width = tileSize, height = tileSize }
    end

    player = {
        x = 100,
        y = baseY - 37,
        idleFrames = {},
        walkFrames = {},
        runFrames = {},
        jumpFrames = {},
        punchFrames = {},
        kickFrames = {},
        crouchFrames = {},
        slideFrames = {},
        getUpFrames = {},
        fallFrames = {},
        currentFrames = nil,
        currentFrame = 1,
        idleFrameCount = 4,
        walkFrameCount = 6,
        runFrameCount = 6,
        jumpFrameCount = 4,
        punchFrameCount = 13,
        kickFrameCount = 8,
        crouchFrameCount = 4,
        slideFrameCount = 2,
        getUpFrameCount = 7,
        fallFrameCount = 2,
        animationTimer = 0,
        frameDuration = 0.1,
        walkFrameDuration = 0.2,
        runFrameDuration = 0.1,
        jumpFrameDuration = 0.16,
        punchFrameDuration = 0.1,
        kickFrameDuration = 0.1,
        crouchFrameDuration = 0.2,
        slideFrameDuration = 0.15,
        getUpFrameDuration = 0.12,
        fallFrameDuration = 0.18,
        idleFrameDuration = 0.3,
        speed = 75,
        runSpeed = 150,
        jumpSpeed = -250,
        gravity = 500,
        isMoving = false,
        isRunning = false,
        isJumping = false,
        isMidAir = false,
        isPunching = false,
        isKicking = false,
        isCrouching = false,
        isSliding = false,
        isGettingUp = false,
        isFalling = false,
        kickCycles = 0,
        velocityY = 0,
        grounded = true,
        punchClickCount = 0,
        slideVelocityX = 0,
        getUpJumpVelocityY = -100,
        facing = 1,
    }

    for i = 0, 3 do
        player.idleFrames[i + 1] = love.graphics.newImage(string.format("assets/adventurer-idle-%02d.png", i))
    end
    for i = 0, 5 do
        player.walkFrames[i + 1] = love.graphics.newImage(string.format("assets/adventurer-walk-%02d.png", i))
        player.runFrames[i + 1] = love.graphics.newImage(string.format("assets/adventurer-run2-%02d.png", i))
    end
    for i = 0, 3 do
        player.jumpFrames[i + 1] = love.graphics.newImage(string.format("assets/adventurer-jump-%02d.png", i))
    end
    for i = 0, 12 do
        player.punchFrames[i + 1] = love.graphics.newImage(string.format("assets/adventurer-punch-%02d.png", i))
    end
    for i = 0, 7 do
        player.kickFrames[i + 1] = love.graphics.newImage(string.format("assets/adventurer-kick-%02d.png", i))
    end
    for i = 0, 3 do
        player.crouchFrames[i + 1] = love.graphics.newImage(string.format("assets/adventurer-crouch-%02d.png", i))
    end
    for i = 0, 1 do
        player.slideFrames[i + 1] = love.graphics.newImage(string.format("assets/adventurer-slide-%02d.png", i))
    end
    for i = 0, 6 do
        player.getUpFrames[i + 1] = love.graphics.newImage(string.format("assets/adventurer-get-up-%02d.png", i))
    end
    for i = 0, 1 do
        player.fallFrames[i + 1] = love.graphics.newImage(string.format("assets/adventurer-fall-%02d.png", i))
    end

    player.currentFrames = player.idleFrames
    player.frameCount = player.idleFrameCount
end

function love.update(dt)
    if love.keyboard.isDown("d") then
        player.facing = 1
    elseif love.keyboard.isDown("a") then
        player.facing = -1
    end

    player.isMoving = love.keyboard.isDown("d") or love.keyboard.isDown("a")
    player.isRunning = (love.keyboard.isDown("d") or love.keyboard.isDown("a")) and love.keyboard.isDown("lshift")

    if player.isRunning and love.keyboard.isDown("s") and player.grounded and not player.isSliding and not player.isPunching and not player.isKicking and not player.isGettingUp then
        player.isSliding = true
        player.isCrouching = false
        player.currentFrames = player.slideFrames
        player.frameCount = player.slideFrameCount
        player.currentFrame = 1
        player.animationTimer = 0
        player.slideVelocityX = player.runSpeed * player.facing
    end

    if player.isSliding then
        player.x = player.x + player.slideVelocityX * dt
        if not love.keyboard.isDown("s") then
            player.isSliding = false
            player.isGettingUp = true
            player.currentFrames = player.getUpFrames
            player.frameCount = player.getUpFrameCount
            player.currentFrame = 1
            player.animationTimer = 0
            player.velocityY = player.getUpJumpVelocityY
        end
    end

    if player.isGettingUp then
        player.x = player.x + player.slideVelocityX * dt
        player.y = player.y + player.velocityY * dt
        player.velocityY = player.velocityY + player.gravity * dt
        local tileIndex = math.floor((player.x + tileSize/2) / tileSize) + 1
        local groundY = terrain[tileIndex] and terrain[tileIndex].y or 500
        if player.y >= groundY - 37 then
            player.y = groundY - 37
            player.velocityY = 0
            player.grounded = true
        end
        if player.currentFrame >= player.getUpFrameCount then
            player.isGettingUp = false
            player.slideVelocityX = 0
            if player.isRunning then
                player.currentFrames = player.runFrames
                player.frameCount = player.runFrameCount
            elseif player.isMoving then
                player.currentFrames = player.walkFrames
                player.frameCount = player.walkFrameCount
            else
                player.currentFrames = player.idleFrames
                player.frameCount = player.idleFrameCount
            end
            player.currentFrame = 1
            player.animationTimer = 0
        end
    end

    if not player.isSliding and not player.isGettingUp then
        if love.keyboard.isDown("s") and not player.isPunching and not player.isKicking and player.grounded then
            if not player.isCrouching then
                player.isCrouching = true
                player.currentFrames = player.crouchFrames
                player.frameCount = player.crouchFrameCount
                player.currentFrame = 1
                player.animationTimer = 0
            end
        else
            if player.isCrouching then
                player.isCrouching = false
                player.currentFrames = player.idleFrames
                player.frameCount = player.idleFrameCount
                player.currentFrame = 1
                player.animationTimer = 0
            end
        end
    end

-- Punch trigger (on mouse click, not hold)
if love.mouse.isDown(1) and not player.isPunching and not player.isKicking and not player.isSliding and not player.isGettingUp then
    player.isPunching = true
    player.currentFrames = player.punchFrames
    player.frameCount = player.punchFrameCount
    player.currentFrame = 1
    player.animationTimer = 0
end

-- After punch animation finishes, trigger kick ONCE
if player.isPunching then
    if player.currentFrame >= player.punchFrameCount then
        player.isPunching = false
        player.isKicking = true
        player.currentFrames = player.kickFrames
        player.frameCount = player.kickFrameCount
        player.currentFrame = 1
        player.animationTimer = 0
    end
end

-- After kick animation finishes, return to idle/movement
if player.isKicking then
    if player.currentFrame >= player.kickFrameCount then
        player.isKicking = false
        -- Return to idle or movement animation
        if player.isRunning then
            player.currentFrames = player.runFrames
            player.frameCount = player.runFrameCount
        elseif player.isMoving then
            player.currentFrames = player.walkFrames
            player.frameCount = player.walkFrameCount
        else
            player.currentFrames = player.idleFrames
            player.frameCount = player.idleFrameCount
        end
        player.currentFrame = 1
        player.animationTimer = 0
    end
end

    if not player.isPunching and not player.isKicking and not player.isCrouching and not player.isSliding and not player.isGettingUp then
        if not player.grounded then
            player.velocityY = player.velocityY + player.gravity * dt
        end

        if love.keyboard.isDown("w") and player.grounded then
            player.velocityY = player.jumpSpeed
            player.grounded = false
            player.isJumping = true
            player.isMidAir = true
            if player.currentFrames ~= player.jumpFrames then
                player.currentFrames = player.jumpFrames
                player.frameCount = player.jumpFrameCount
                player.currentFrame = 1
                player.animationTimer = 0
            end
        end

        if not player.grounded and player.velocityY > 0 and not player.isFalling then
            player.isFalling = true
            player.currentFrames = player.fallFrames
            player.frameCount = player.fallFrameCount
            player.currentFrame = 1
            player.animationTimer = 0
        end

        player.y = player.y + player.velocityY * dt

        -- Terrain collision
        local tileIndex = math.floor((player.x + tileSize/2) / tileSize) + 1
        local groundY = terrain[tileIndex] and terrain[tileIndex].y or 500
        if player.y >= groundY - 37 then
            player.y = groundY - 37
            player.velocityY = 0
            player.grounded = true
            player.isJumping = false
            player.isMidAir = false
            player.isFalling = false

            if player.currentFrames ~= player.idleFrames and not player.isMoving and not player.isRunning then
                player.currentFrames = player.idleFrames
                player.frameCount = player.idleFrameCount
                player.currentFrame = 1
                player.animationTimer = 0
            end
        end

        if player.grounded then
            if player.isRunning then
                player.speed = player.runSpeed
                if player.currentFrames ~= player.runFrames then
                    player.currentFrames = player.runFrames
                    player.frameCount = player.runFrameCount
                    player.currentFrame = 1
                    player.animationTimer = 0
                end
            elseif player.isMoving then
                player.speed = 75
                if player.currentFrames ~= player.walkFrames then
                    player.currentFrames = player.walkFrames
                    player.frameCount = player.walkFrameCount
                    player.currentFrame = 1
                    player.animationTimer = 0
                end
            else
                player.speed = 75
                if player.currentFrames ~= player.idleFrames then
                    player.currentFrames = player.idleFrames
                    player.frameCount = player.idleFrameCount
                    player.currentFrame = 1
                    player.animationTimer = 0
                end
            end
        end

        if player.isMoving or player.isRunning then
            if love.keyboard.isDown("d") then
                player.x = player.x + player.speed * dt
            elseif love.keyboard.isDown("a") then
                player.x = player.x - player.speed * dt
            end
        end
    end

    -- Clamp player to terrain bounds
    if player.x > (terrainTileCount * tileSize) - 50 then
        player.x = (terrainTileCount * tileSize) - 50
    elseif player.x < 0 then
        player.x = 0
    end

    player.animationTimer = player.animationTimer + dt
    local frameDuration = player.frameDuration
    if player.currentFrames == player.runFrames then
        frameDuration = player.runFrameDuration
    elseif player.currentFrames == player.walkFrames then
        frameDuration = player.walkFrameDuration
    elseif player.currentFrames == player.jumpFrames then
        frameDuration = player.jumpFrameDuration
    elseif player.currentFrames == player.punchFrames then
        frameDuration = player.punchFrameDuration
    elseif player.currentFrames == player.kickFrames then
        frameDuration = player.kickFrameDuration
    elseif player.currentFrames == player.crouchFrames then
        frameDuration = player.crouchFrameDuration
    elseif player.currentFrames == player.slideFrames then
        frameDuration = player.slideFrameDuration
    elseif player.currentFrames == player.getUpFrames then
        frameDuration = player.getUpFrameDuration
    elseif player.currentFrames == player.fallFrames then
        frameDuration = player.fallFrameDuration
    else
        frameDuration = player.idleFrameDuration
    end

    if player.animationTimer >= frameDuration then
        player.animationTimer = player.animationTimer - frameDuration
        local nextFrame = (player.currentFrame % player.frameCount) + 1
        player.currentFrame = nextFrame
    end
end

function love.draw()
    local cameraX = math.floor(player.x + 25 - screenWidth / 2)
    cameraX = math.max(0, math.min(cameraX, terrainTileCount * tileSize - screenWidth))

    love.graphics.push()
    love.graphics.translate(-cameraX, 0)

    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.rectangle("fill", 0, 0, terrainTileCount * tileSize, screenHeight)
    love.graphics.setColor(1, 1, 1)

    for i = 1, terrainTileCount do
        local tile = terrain[i]
        love.graphics.draw(groundTexture, tile.x, tile.y, 0, tileSize / groundTexture:getWidth(), tileSize / groundTexture:getHeight())
    end

    -- Draw player (unchanged)
    if player.currentFrames and player.currentFrame then
        local img = player.currentFrames[player.currentFrame]
        local scaleX = player.facing
        local offsetX = 0
        if scaleX == -1 then
            offsetX = img:getWidth()
        end
        love.graphics.draw(img, player.x + offsetX, player.y, 0, scaleX, 1)
    else
        print("Error: currentFrames or currentFrame is nil")
    end

    love.graphics.pop()
end