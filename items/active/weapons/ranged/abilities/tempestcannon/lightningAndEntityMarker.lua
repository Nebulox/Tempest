require "/scripts/vec2.lua"
require "/scripts/util.lua"

lighting = {

    drawLightning = function(startLine, endLine, displacement, minDisplacement, forks, forkAngleRange, width, color)
      if displacement < minDisplacement then
        local position = startLine
        endLine = vec2.sub(endLine, startLine)
        startLine = {0,0}
        localAnimator.addDrawable({line = {startLine, endLine}, width = width, color = color, position = position, fullbright = true})
      else
        local mid = {(startLine[1] + endLine[1]) / 2, (startLine[2] + endLine[2]) / 2}
        mid = vec2.add(mid, lighting.randomOffset(displacement))
        lighting.drawLightning(startLine, mid, displacement / 2, minDisplacement, forks - 1, forkAngleRange, width, color)
        lighting.drawLightning(mid, endLine, displacement / 2, minDisplacement, forks - 1, forkAngleRange, width, color)

        if forks > 0 then
          local direction = vec2.sub(mid, startLine)
          local length = vec2.mag(direction) / 2
          local angle = math.atan(direction[2], direction[1]) + lighting.randomInRange(forkAngleRange)
          forkEnd = vec2.mul({math.cos(angle), math.sin(angle)}, length)
          lighting.drawLightning(mid, vec2.add(mid, forkEnd), displacement / 2, minDisplacement, forks - 1, forkAngleRange, width, color)
        end
      end
    end,

    randomInRange = function(range)
      return -range + math.random() * 2 * range
    end,

    randomOffset = function(range)
      return {lighting.randomInRange(range), lighting.randomInRange(range)}
    end,

    update = function()
      local tickRate = animationConfig.animationParameter("lightningTickRate") or 25

      local lightningSeed = animationConfig.animationParameter("lightningSeed")
      if not lightningSeed then
    local millis = math.floor((os.time() + (os.clock() % 1)) * 1000)
    lightningSeed = math.floor(millis / tickRate)
      end
      math.randomseed(lightningSeed)

      local getLinePosition = function(bolt, positionType)
    return bolt["world"..positionType.."Position"]
      or (bolt["item"..positionType.."Position"] and vec2.add(activeItemAnimation.ownerPosition(), activeItemAnimation.handPosition(bolt["item"..positionType.."Position"])))
      or (bolt["part"..positionType.."Position"] and vec2.add(activeItemAnimation.ownerPosition(),
        activeItemAnimation.handPosition(animationConfig.partPoint(bolt["part"..positionType.."Position"][1], bolt["part"..positionType.."Position"][2]))))
      end

      local lightningBolts = animationConfig.animationParameter("lightning")
      if lightningBolts then
        for _, bolt in pairs(lightningBolts) do
          local startPosition = getLinePosition(bolt, "Start")
          local endPosition = getLinePosition(bolt, "End")
          endPosition = vec2.add(startPosition, world.distance(endPosition, startPosition))
          if bolt.endPointDisplacement then
            endPosition = vec2.add(endPosition, lighting.randomOffset(bolt.endPointDisplacement))
          end
          lighting.drawLightning(startPosition, endPosition, bolt.displacement, bolt.minDisplacement, bolt.forks, bolt.forkAngleRange, bolt.width, bolt.color)
        end
      end
    end

}


function update()
    localAnimator.clearDrawables()
  
    local markerImage = animationConfig.animationParameter("markerImage")
    if markerImage then
      local entities = animationConfig.animationParameter("entities") or {}
      entities = util.filter(entities, world.entityExists)
      for _,entityId in pairs(entities) do
        localAnimator.addDrawable({image = markerImage, position = world.entityPosition(entityId)}, "overlay")
      end
    end

    lighting.update()
end

--[[
{
  lighting1 = {
    worldStartPosition = {0,0},
    worldEndPosition = {0,0},
    --
    itemStartPosition = {0,0}
    itemEndPosition = {0,0}
    --
    partStartPosition = {"part", "tag"}
    partEndPosition = {"part", "tag"}
    --
    displacement = 2,
    minDisplacement = 1,
    forks = 1,
    forkAngleRange = 2,
    width = 2,
    color = {0,255,255}
  }
}
]]

