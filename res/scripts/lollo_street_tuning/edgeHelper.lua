local arrayUtils = require('lollo_street_tuning.arrayUtils')
local matrixUtils = require('lollo_street_tuning.matrix')
local quadrangleUtils = require('lollo_street_tuning.quadrangleUtils')
local transfUtils = require('lollo_street_tuning.transfUtils')
local transfUtilUG = require('transf')

if math.atan2 == nil then
    math.atan2 = function(dy, dx)
        local result = 0
        if dx == 0 then
            result = math.pi * 0.5
        else
            result = math.atan(dy / dx)
        end

        if dx > 0 then
            return result
        elseif dx < 0 and dy >= 0 then
            return result + math.pi
        elseif dx < 0 and dy < 0 then
            return result - math.pi
        elseif dy > 0 then
            return result
        elseif dy < 0 then
            return - result
        else return false
        end
    end
end

local helper = {}

helper.isValidId = function(id)
    return type(id) == 'number' and id > 0
end

helper.getVectorLength = function(xyz)
    if type(xyz) ~= 'table' then return nil end
    local x = xyz.x or xyz[1] or 0.0
    local y = xyz.y or xyz[2] or 0.0
    local z = xyz.z or xyz[3] or 0.0
    return math.sqrt(x * x + y * y + z * z)
end

helper.getNearbyEntities = function(transf)
    if type(transf) ~= 'table' then return {} end

    -- debugger()
    local edgeSearchRadius = 0.0
    local squareCentrePosition = transfUtils.getVec123Transformed({0, 0, 0}, transf)
    local results = game.interface.getEntities(
        {pos = squareCentrePosition, radius = edgeSearchRadius},
        {includeData = true}
        -- {includeData = true}
    )

    return results
end

local function swap(num1, num2)
    local swapTemp = num1
    num1 = num2
    num2 = swapTemp
end

helper.getNearestEdgeId = function(transf)
    if type(transf) ~= 'table' then return nil end

    local _position = transfUtils.getVec123Transformed({0, 0, 0}, transf)
    local _searchRadius = 0.5
    local _box0 = api.type.Box3.new(
        api.type.Vec3f.new(_position[1] - _searchRadius, _position[2] - _searchRadius, -9999),
        api.type.Vec3f.new(_position[1] + _searchRadius, _position[2] + _searchRadius, 9999)
    )
    local baseEdgeIds = {}
    local callback0 = function(entity, boundingVolume)
        -- print('callback0 found entity', entity)
        -- print('boundingVolume =')
        -- debugPrint(boundingVolume)
        if not(entity) then return end

        if not(api.engine.getComponent(entity, api.type.ComponentType.BASE_EDGE)) then return end
        -- print('the entity is a BASE_EDGE')

        baseEdgeIds[#baseEdgeIds+1] = entity
    end
    api.engine.system.octreeSystem.findIntersectingEntities(_box0, callback0)

    if #baseEdgeIds == 0 then
        return nil
    elseif #baseEdgeIds == 1 then
        return baseEdgeIds[1]
    else
        -- print('multiple base edges found')
        -- choose one edge and return its id
        for i = 1, #baseEdgeIds do
            local baseEdge = api.engine.getComponent(baseEdgeIds[i], api.type.ComponentType.BASE_EDGE)
            local baseEdgeStreet = api.engine.getComponent(baseEdgeIds[i], api.type.ComponentType.BASE_EDGE_STREET)
            if baseEdge ~= nil and baseEdgeStreet ~= nil then -- false when there is a modded road that underwent a breaking change
                local node0 = api.engine.getComponent(baseEdge.node0, api.type.ComponentType.BASE_NODE)
                local node1 = api.engine.getComponent(baseEdge.node1, api.type.ComponentType.BASE_NODE)
                local streetTypeProperties = api.res.streetTypeRep.get(baseEdgeStreet.streetType)
                local halfStreetWidth = (streetTypeProperties.streetWidth or 0) * 0.5 + (streetTypeProperties.sidewalkWidth or 0)
                local alpha = math.atan2(node1.position.y - node0.position.y, node1.position.x - node0.position.x)
                local xPlus = - math.sin(alpha) * halfStreetWidth
                local yPlus = math.cos(alpha) * halfStreetWidth
                local vertices = {
                    [1] = {
                        x = node0.position.x - xPlus,
                        y = node0.position.y - yPlus
                    },
                    [2] = {
                        x = node0.position.x + xPlus,
                        y = node0.position.y + yPlus
                    },
                    [3] = {
                        x = node1.position.x + xPlus,
                        y = node1.position.y + yPlus
                    },
                    [4] = {
                        x = node1.position.x - xPlus,
                        y = node1.position.y - yPlus
                    },
                }
                -- check if the _position falls within the quadrangle approximating the edge
                -- LOLLO NOTE I could get a more accurate polygon (not necessarily a quadrangle!) getIsPointWithin
                -- api.engine.getComponent(entity, api.type.ComponentType.LOT_LIST)
                -- but it returns nothing with bridges and tunnels
                if quadrangleUtils.getIsPointWithin(quadrangleUtils.getVerticesSortedClockwise(vertices), _position) then
                    return baseEdgeIds[i]
                end
            end
        end
        -- print('falling back')
        return baseEdgeIds[1] -- fallback
    end
end

helper.getNearestObjectIds = function(transf, searchRadius, componentType)
    if type(transf) ~= 'table' then return nil end

    if not(componentType) then componentType = api.type.ComponentType.BASE_EDGE end

    local _position = transfUtils.getVec123Transformed({0, 0, 0}, transf)
    local _searchRadius = searchRadius or 0.5
    local _box0 = api.type.Box3.new(
        api.type.Vec3f.new(_position[1] - _searchRadius, _position[2] - _searchRadius, -9999),
        api.type.Vec3f.new(_position[1] + _searchRadius, _position[2] + _searchRadius, 9999)
    )
    local baseEdgeIds = {}
    local callback0 = function(entity, boundingVolume)
        -- print('callback0 found entity', entity)
        -- print('boundingVolume =')
        -- debugPrint(boundingVolume)
        if not(entity) then return end

        if not(api.engine.getComponent(entity, componentType)) then return end
        -- print('the entity has the right component type')

        baseEdgeIds[#baseEdgeIds+1] = entity
    end
    api.engine.system.octreeSystem.findIntersectingEntities(_box0, callback0)

    return baseEdgeIds
end

local function sign(num1)
    if type(num1) ~= 'number' then return nil end

    if num1 == 0 then return 0 end
    if num1 > 0 then return 1 end
    return -1
end

helper.getNodeBetween = function(position0, tangent0, position1, tangent1, betweenPosition)
    if not(position0) or not(position1) or not(tangent0) or not(tangent1) then return nil end

    local node01Distance = helper.getVectorLength({
        position1.x - position0.x,
        position1.y - position0.y,
        position1.z - position0.z
    })
    if node01Distance == 0 then return nil end

    local node01DistanceXY = helper.getVectorLength({
        position1.x - position0.x,
        position1.y - position0.y,
        0.0
    })
    local x20Shift = type(betweenPosition) ~= 'table'
        and
            0.5
        or
            (helper.getVectorLength({
                betweenPosition.x - position0.x,
                betweenPosition.y - position0.y,
                -- betweenPosition.z - position0.z
                -- 0.0
            }) / node01Distance)
    -- print('x20Shift =', x20Shift or 'NIL')
    -- shift everything around betweenPosition to avoid large numbers being summed and subtracted
    local x0 = position0.x - betweenPosition.x
    local x1 = position1.x - betweenPosition.x
    local y0 = position0.y - betweenPosition.y
    local y1 = position1.y - betweenPosition.y
    local ypsilon0 = math.atan2(tangent0.y, tangent0.x)
    local ypsilon1 = math.atan2(tangent1.y, tangent1.x)
    local z0 = position0.z - betweenPosition.z
    local z1 = position1.z - betweenPosition.z
    -- rotate the edges around the Z axis so that y0 = y1
    local zRotation = -math.atan2(y1 - y0, x1 - x0)
    local x0I = x0
    local x1I = x0 + node01DistanceXY
    local y0I = y0
    local ypsilon0I = ypsilon0 + zRotation
    local ypsilon1I = ypsilon1 + zRotation
    local z0I = z0
    local z1I = z1

    local invertedXMatrix = matrixUtils.invert(
        {
            {1, x0I, x0I * x0I, x0I * x0I * x0I},
            {1, x1I, x1I * x1I, x1I * x1I * x1I},
            {0, 1, 2 * x0I, 3 * x0I * x0I},
            {0, 1, 2 * x1I, 3 * x1I * x1I}
        }
    )

    if not(invertedXMatrix) then return nil end -- if x0 == x1 the system cannot be solved, this is why I rotated it. If it still fails, reject.

    local _maxTangent = 3 -- node01DistanceXY * 0.3 -- 5 -- this is tricky. In edge cases, I will be approximating a U or a J with a polynom.
    -- That means, the bottom tip of the U or the bottom tip of the J will be infinitely far away from its top.
    -- This factor keeps the curve in shape, but it must have the right sign. Beyond that, I can reject or bodge.
    -- Also, tangents have a discontinuity at +/- PI/2: bodging could get tricky
    -- AN idea could be: replace the equation with the large tangent with one based on the position the user clicked.
    local tan0I = math.tan(ypsilon0I)
    if math.abs(tan0I) > _maxTangent then return nil end
    local tan1I = math.tan(ypsilon1I)
    if math.abs(tan1I) > _maxTangent then return nil end

    -- Now I solve the system for y:
    -- a + b x0' + c x0'^2 + d x0'^3 = y0'
    -- a + b x1' + c x1'^2 + d x1'^3 = y0' .. y0' == y1' by construction
    -- b + 2 c x0' + 3 d x0'^2 = sin0' / cos0'
    -- b + 2 c x1' + 3 d x1'^2 = sin1' / cos1'
    local abcdY = matrixUtils.mul(
        invertedXMatrix,
        {
            {y0I},
            {y0I},
            {tan0I},
            {tan1I}
        }
    )
    local aY = abcdY[1][1]
    local bY = abcdY[2][1]
    local cY = abcdY[3][1]
    local dY = abcdY[4][1]

    -- Now I solve the system for z:
    -- a + b x0' + c x0'^2 + d x0'^3 = z0'
    -- a + b x1' + c x1'^2 + d x1'^3 = z1'
    -- b + 2 c x0' + 3 d x0'^2 = sin0' / cos0'
    -- b + 2 c x1' + 3 d x1'^2 = sin1' / cos1'
    local abcdZ = matrixUtils.mul(
        invertedXMatrix,
        {
            {z0I},
            {z1I},
            {tangent0.z / helper.getVectorLength({tangent0.x, tangent0.y, 0.0})},
            {tangent1.z / helper.getVectorLength({tangent1.x, tangent1.y, 0.0})},
        }
    )
    local aZ = abcdZ[1][1]
    local bZ = abcdZ[2][1]
    local cZ = abcdZ[3][1]
    local dZ = abcdZ[4][1]

    -- Now I take x2' between x0' and x1',
    local x2I = x0I + (x1I - x0I) * x20Shift
    local y2I = aY + bY * x2I + cY * x2I * x2I + dY * x2I * x2I * x2I
    local z2I = aZ + bZ * x2I + cZ * x2I * x2I + dZ * x2I * x2I * x2I
    -- calculate its y derivative:
    local DYOnDX2I = bY + 2 * cY * x2I + 3 * dY * x2I * x2I
    local ypsilon2I = math.atan(DYOnDX2I)
    -- calculate its z derivative:
    local DZOnDX2I = bZ + 2 * cZ * x2I + 3 * dZ * x2I * x2I
    local zeta2I = math.atan(DZOnDX2I)

    -- Now I undo the rotation and the traslation I did at the beginning
    local ro2 = helper.getVectorLength({x2I - x0I, y2I - y0I, 0.0})
    local alpha2I = math.atan2(y2I - y0I, x2I - x0I)

    local nodeBetween = {
        position = {
            x0I + ro2 * math.cos(alpha2I - zRotation) + betweenPosition.x,
            y0I + ro2 * math.sin(alpha2I - zRotation) + betweenPosition.y,
            z2I + betweenPosition.z
        },
        tangent = {
            math.cos(ypsilon2I - zRotation),
            math.sin(ypsilon2I - zRotation),
            math.sin(zeta2I)
        }
    }

    -- normalise tangent
    local tangentLength = helper.getVectorLength(nodeBetween.tangent)
    if tangentLength ~= 0 and tangentLength ~= 1 then
        nodeBetween.tangent[1] = nodeBetween.tangent[1] / tangentLength
        nodeBetween.tangent[2] = nodeBetween.tangent[2] / tangentLength
        nodeBetween.tangent[3] = nodeBetween.tangent[3] / tangentLength
    end

    return nodeBetween
end

helper.getEdgeObjectsWithModelId = function(edgeObjects, refModelId)
    local results = {}
    for i = 1, #edgeObjects do
        local modelInstanceList = api.engine.getComponent(edgeObjects[i][1], api.type.ComponentType.MODEL_INSTANCE_LIST)
        if modelInstanceList
        and modelInstanceList.fatInstances
        and modelInstanceList.fatInstances[1]
        and modelInstanceList.fatInstances[1].modelId == refModelId then
            results[#results+1] = edgeObjects[i][1]
        end
    end
    return results
end

helper.getLastBuiltEdge = function(entity2tn)
    local nodeIds = {}
    for id, _ in pairs(entity2tn) do
        if api.engine.getComponent(id, api.type.ComponentType.BASE_NODE) ~= nil then nodeIds[#nodeIds+1] = id end
    end
    if #nodeIds ~= 2 then return nil end

    for id, _ in pairs(entity2tn) do
        local baseEdge = api.engine.getComponent(id, api.type.ComponentType.BASE_EDGE)
        if baseEdge ~= nil
        and ((baseEdge.node0 == nodeIds[1] and baseEdge.node1 == nodeIds[2])
        or (baseEdge.node0 == nodeIds[2] and baseEdge.node1 == nodeIds[1])) then
            return {
                id = id,
                objects = baseEdge.objects
            }
        end
    end

    return nil
end

helper.getNodeIdsBetweenEdgeIds = function(edgeIds)
    if type(edgeIds) ~= 'table' then return {} end

    local allNodeIds = {}
    local sharedNodeIds = {}
    for _, edgeId in pairs(edgeIds) do
        local baseEdge = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE)
        if baseEdge ~= nil then
            if arrayUtils.arrayHasValue(allNodeIds, baseEdge.node0) then
                arrayUtils.addUnique(sharedNodeIds, baseEdge.node0)
            end
            if arrayUtils.arrayHasValue(allNodeIds, baseEdge.node1) then
                arrayUtils.addUnique(sharedNodeIds, baseEdge.node1)
            end
            allNodeIds[#allNodeIds+1] = baseEdge.node0
            allNodeIds[#allNodeIds+1] = baseEdge.node1
        end
    end

    return sharedNodeIds
end

helper.getObjectPosition = function(objectId)
    print('getObjectPosition starting')
    if type(objectId) ~= 'number' or objectId < 0 then return nil end

    local modelInstanceList = api.engine.getComponent(objectId, api.type.ComponentType.MODEL_INSTANCE_LIST)
    if not(modelInstanceList) then return nil end

    local fatInstances = modelInstanceList.fatInstances
    if not(fatInstances) or not(fatInstances[1]) or not(fatInstances[1].transf) or not(fatInstances[1].transf.cols) then return nil end

    local objectTransf = transfUtilUG.new(
        fatInstances[1].transf:cols(0),
        fatInstances[1].transf:cols(1),
        fatInstances[1].transf:cols(2),
        fatInstances[1].transf:cols(3)
    )
    -- print('fatInstances[1]', fatInstances[1] and true)
    -- print('fatInstances[2]', fatInstances[2] and true) -- always nil
    -- print('fatInstances[3]', fatInstances[3] and true) -- always nil
    -- print('objectTransf =')
    -- debugPrint(objectTransf)
    return {
        [1] = objectTransf[13],
        [2] = objectTransf[14],
        [3] = objectTransf[15]
    }
end

helper.track = {}
helper.track.getContiguousEdges = function(edgeId, trackType)
    local _calcContiguousEdges = function(firstEdgeId, firstNodeId, map, isInsertFirst, results)
        local refEdgeId = firstEdgeId
        local refNodeId = firstNodeId
        local edgeIds = map[firstNodeId] -- userdata
        local isExit = false
        while not(isExit) do
            if not(edgeIds) or #edgeIds ~= 2 then
                isExit = true
            else
                for _, _edgeId in pairs(edgeIds) do -- cannot use edgeIds[index] here
                    print('edgeId =')
                    debugPrint(_edgeId)
                    if _edgeId ~= refEdgeId then
                        local baseEdgeTrack = api.engine.getComponent(_edgeId, api.type.ComponentType.BASE_EDGE_TRACK)
                        print('baseEdgeTrack =')
                        debugPrint(baseEdgeTrack)
                        if not(baseEdgeTrack) or baseEdgeTrack.trackType ~= trackType then
                            isExit = true
                            break
                        else
                            if isInsertFirst then
                                table.insert(results, 1, _edgeId)
                            else
                                table.insert(results, _edgeId)
                            end
                            local edgeData = api.engine.getComponent(_edgeId, api.type.ComponentType.BASE_EDGE)
                            if edgeData.node0 ~= refNodeId then
                                refNodeId = edgeData.node0
                            else
                                refNodeId = edgeData.node1
                            end
                            refEdgeId = _edgeId
                            break
                        end
                    end
                end
                edgeIds = map[refNodeId]
            end
        end
    end

    print('getContiguousEdges starting, edgeId =')
    debugPrint(edgeId)
    print('track type =')
    debugPrint(trackType)

    if not(edgeId) or not(trackType) then return {} end

    local _baseEdgeTrack = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE_TRACK)
    if not(_baseEdgeTrack) or _baseEdgeTrack.trackType ~= trackType then return {} end

    local _baseEdge = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE)
    local _edgeId = edgeId
    local _map = api.engine.system.streetSystem.getNode2SegmentMap()
    local results = { edgeId }

    _calcContiguousEdges(_edgeId, _baseEdge.node0, _map, true, results)
    _calcContiguousEdges(_edgeId, _baseEdge.node1, _map, false, results)

    return results
end

helper.track.getEdgeIdsBetweenEdgeIds = function(_edge1Id, _edge2Id)
    print('one')
    if type(_edge1Id) ~= 'number' or _edge1Id < 1 then return {} end
    if type(_edge2Id) ~= 'number' or _edge2Id < 1 then return {} end
    print('two')
    if _edge1Id == _edge2Id then return { _edge1Id } end
    print('three')
    local _baseEdge1 = api.engine.getComponent(
        _edge1Id,
        api.type.ComponentType.BASE_EDGE
    )
    local _baseEdge2 = api.engine.getComponent(
        _edge2Id,
        api.type.ComponentType.BASE_EDGE
    )
    if _baseEdge1 == nil or _baseEdge2 == nil then return {} end
    print('four')
    local _baseEdgeTrack2 = api.engine.getComponent(_edge2Id, api.type.ComponentType.BASE_EDGE_TRACK)
    if not(_baseEdgeTrack2) then return {} end
    print('five')
    local _trackType2 = _baseEdgeTrack2.trackType

    local _isTrackEdgeContiguousTo2 = function(baseEdge1)
        if baseEdge1.node0 == _baseEdge2.node0 or baseEdge1.node0 == _baseEdge2.node1
        or baseEdge1.node1 == _baseEdge2.node0 or baseEdge1.node1 == _baseEdge2.node1 then
            return true
        end

        return false
    end

    local _isTrackEdgesSameTypeAs2 = function(edge1Id)
        local baseEdgeTrack1 = api.engine.getComponent(edge1Id, api.type.ComponentType.BASE_EDGE_TRACK)
        if not(baseEdgeTrack1) or baseEdgeTrack1.trackType ~= _trackType2 then return false end

        return true
    end

    if _isTrackEdgeContiguousTo2(_baseEdge1) then
        if _isTrackEdgesSameTypeAs2(_edge1Id) then print('six') return { _edge1Id, _edge2Id } end
        print('seven')
        return {}
    end

    -- LOLLO TODO test this function from here on, we don't know how good it is
    local _map = api.engine.system.streetSystem.getNode2SegmentMap()
    local _getEdgesBetween = function(node0Or1FieldName)
        local baseEdge1 = _baseEdge1
        local baseEdges = { _baseEdge1, _baseEdge2 }
        local edge1Id = _edge1Id
        local edgeIds = { _edge1Id, _edge2Id }
        local counter = 0
        while counter < 20 do
            counter = counter + 1
            print('eight')
            local nodeId = baseEdge1[node0Or1FieldName]
            local adjacentEdgeIds = _map[nodeId] -- userdata
            if not(adjacentEdgeIds) or #adjacentEdgeIds ~= 2 then
                print('nine')
                return false
            else
                for _, edgeId in pairs(adjacentEdgeIds) do -- cannot use adjacentEdgeIds[index] here
                    print('ten')
                    if edgeId ~= edge1Id then
                        print('eleven')
                        edge1Id = edgeId
                        edgeIds[#edgeIds-1] = edgeId
                        baseEdge1 = api.engine.getComponent(
                            edgeId,
                            api.type.ComponentType.BASE_EDGE
                        )
                        baseEdges[#baseEdges-1] = baseEdge1
                        if _isTrackEdgeContiguousTo2(baseEdge1) then
                            print('twelve')
                            if _isTrackEdgesSameTypeAs2(edge1Id) then print('thirteen') return edgeIds end
                            print('fourteen')
                            return false
                        end

                        break
                    end
                end
            end
        end

        return false
    end

    local node0Results = _getEdgesBetween('node0')
    print('node0results =')
    debugPrint(node0Results)
    if node0Results then return node0Results end

    local node1Results = _getEdgesBetween('node1')
    print('node1results =')
    debugPrint(node1Results)
    if node1Results then return node1Results end

    return {}
end

helper.track.getTrackEdgeIdsBetweenEdgeIdsBROKEN = function(edge1Id, edge2Id)
    print('edge1Id =')
    debugPrint(edge1Id)
    print('edge2Id =')
    debugPrint(edge2Id)
    local edge1IdTyped = api.type.EdgeId.new()
    edge1IdTyped.entity = edge1Id
    local edge2IdTyped = api.type.EdgeId.new()
    edge2IdTyped.entity = edge2Id
    print('edge1IdTyped =')
    debugPrint(edge1IdTyped)
    print('edge2IdTyped =')
    debugPrint(edge2IdTyped)
    local edgeIdDir1 = api.type.EdgeIdDirAndLength.new(edge1IdTyped, true, 10)
    -- local edgeIdDir2 = api.type.EdgeIdDirAndLength.new(edge2IdTyped, true, 10)
    print('edgeIdDir1 =')
    debugPrint(edgeIdDir1)
    local baseEdge1 = api.engine.getComponent(
        edge1Id,
        api.type.ComponentType.BASE_EDGE
    )
    local baseEdge2 = api.engine.getComponent(
        edge2Id,
        api.type.ComponentType.BASE_EDGE
    )
    print('baseEdge1 =')
    debugPrint(baseEdge1)
    print('baseEdge2 =')
    debugPrint(baseEdge2)
    local node1Typed = api.type.NodeId.new()
    node1Typed.entity = baseEdge2.node0
    local node2Typed = api.type.NodeId.new()
    node2Typed.entity = baseEdge2.node1

    print('edgeIdDir1 =')
    debugPrint(edgeIdDir1)
    print('node1Typed =')
    debugPrint(node1Typed)
    print('node2Typed =')
    debugPrint(node2Typed)
    -- LOLLO TODO this dumps without useful messages
    local path = api.engine.util.pathfinding.findPath(
        { edgeIdDir1 },
        { node1Typed },
        {
            api.type.enum.TransportMode.TRAIN,
            api.type.enum.TransportMode.ELECTRIC_TRAIN
        },
        500.0
    )
    print('path =')
    debugPrint(path)
    return {}
end

helper.track.getTrackEdgeIdsBetweenNodeIds = function(_node1Id, _node2Id)
    print('ONE')
    if type(_node1Id) ~= 'number' or _node1Id < 1 then return {} end
    if type(_node2Id) ~= 'number' or _node2Id < 1 then return {} end
    print('TWO')
    if _node1Id == _node2Id then return {} end
    print('THREE')

    local adjacentEdge1Ids = {}
    local adjacentEdge2Ids = {}
    local _fetchAdjacentEdges = function()
        local _map = api.engine.system.streetSystem.getNode2SegmentMap()
        local adjacentEdge1IdsUserdata = _map[_node1Id] -- userdata
        local adjacentEdge2IdsUserdata = _map[_node2Id] -- userdata
        if not(adjacentEdge1IdsUserdata) then
            print('FOUR')
            return false
        else
            for _, edgeId in pairs(adjacentEdge1IdsUserdata) do -- cannot use adjacentEdgeIds[index] here
                adjacentEdge1Ids[#adjacentEdge1Ids+1] = edgeId
            end
            print('FIVE')
        end
        if not(adjacentEdge2IdsUserdata) then
            print('SIX')
            return false
        else
            for _, edgeId in pairs(adjacentEdge2IdsUserdata) do -- cannot use adjacentEdgeIds[index] here
                adjacentEdge2Ids[#adjacentEdge2Ids+1] = edgeId
            end
            print('SEVEN')
        end

        return true
    end

    _fetchAdjacentEdges()
    if #adjacentEdge1Ids < 1 or #adjacentEdge2Ids < 1 then print('EIGHT') return {} end

    if #adjacentEdge1Ids == 1 and #adjacentEdge2Ids == 1 then
        if adjacentEdge1Ids[1] == adjacentEdge2Ids[1] then
            print('NINE')
            return { adjacentEdge1Ids[1] }
        else
            print('TEN')
            return {}
        end
    end

    local trackEdgeIdsBetweenEdgeIds = helper.track.getEdgeIdsBetweenEdgeIds(adjacentEdge1Ids[1], adjacentEdge2Ids[1])
    -- remove edges adjacent to but outside node1 and node2
    local isExit = false
    while not(isExit) do
        if #trackEdgeIdsBetweenEdgeIds > 1
        and arrayUtils.arrayHasValue(adjacentEdge1Ids, trackEdgeIdsBetweenEdgeIds[2]) then
            print('ELEVEN')
            table.remove(trackEdgeIdsBetweenEdgeIds, 1)
        else
            print('TWELVE')
            isExit = true
        end
    end
    isExit = false
    while not(isExit) do
        if #trackEdgeIdsBetweenEdgeIds > 1
        and arrayUtils.arrayHasValue(adjacentEdge2Ids, trackEdgeIdsBetweenEdgeIds[#trackEdgeIdsBetweenEdgeIds-1]) then
            print('THIRTEEN')
            table.remove(trackEdgeIdsBetweenEdgeIds, #trackEdgeIdsBetweenEdgeIds)
        else
            print('FOURTEEN')
            isExit = true
        end
    end

    return trackEdgeIdsBetweenEdgeIds
end

return helper
