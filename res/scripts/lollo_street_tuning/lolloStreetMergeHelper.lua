local arrayUtils = require('lollo_street_tuning/arrayUtils')
local pitchHelper = require('lollo_street_tuning/pitchHelper')
local streetUtils = require('lollo_street_tuning/streetUtils')

local helper = {
    getParams = function()
        -- print('globalBridgeData at getParams =') debugPrint(
        --     arrayUtils.map(
        --             streetUtils.getGlobalBridgeDataPlusNoBridge(),
        --             function(str)
        --                 return str
        --             end
        --     )
        -- )
        return {
            {
                key = 'mergingType',
                name = _('Street merging type'),
                values = {
                    '↑  ↑   -   ↑↑', -- 0
                    '↑    ↑   -   ↑↑', -- 1
                    '↓  ↑   -   ↓↑', -- 2
                    '↓    ↑   -   ↓↑', -- 3
                    '↑  ↑  ↑   -   ↑↑↑', -- 4
                    -- '↑    ↑    ↑   -   ↑↑↑', -- 5
                    '↑  ↑  ↑  ↑   -   ↑↑↑↑', -- 5
                    '↓  ↓  ↑  ↑   -   ↓↓↑↑', -- 6
                    '↓  ↓  ↑  ↑   -   ↓ ↓ ↑ ↑', -- 7
                    '↓↓   ↑↑   -   ↓ ↓ ↓ ↑ ↑ ↑', -- 8
                    '↓↓↓   ↑↑↑   -   ↓ ↓ ↓ ↑ ↑ ↑', -- 9
                    'M ↓↓↓   ↑↑↑   -   ↓ ↓ ↓ ↑ ↑ ↑', -- 10
                    'M ↓↓   ↑↑   -   ↓ ↓ ↓ ↑ ↑ ↑', -- 11
                    'M ↓↓   ↑↑   -   ↓ ↓ ↑ ↑', -- 12
                    'M ↑  ↑  ↑   -   ↑↑↑', -- 13
                    'M ↑  ↑   -   ↑↑', -- 14
                    'M ↓  ↑   -   ↓↑', -- 15
                },
                defaultIndex = 0
            },
            {
                key = 'direction',
                name = _('Direction (only one-way roads)'),
                values = {
                    _('↑'),
                    _('↓')
                },
                defaultIndex = 0
            },
            {
                key = 'bridgeType_',
                name = _('BridgeType'),
                values = arrayUtils.map(
                    streetUtils.getGlobalBridgeDataPlusNoBridge(),
                    function(str)
                        return str.name
                        -- return str.icon
                    end
                ),
                uiType = 'COMBOBOX',
                -- uiType = 'ICON_BUTTON',
            },
            -- {
            --     key = 'snapNodes_',
            --     name = _('Snap to neighbours'),
            --     values = {
            --         _('No'),
            --         _('Yes')
            --     },
            --     defaultIndex = 0
            -- },
            {
                key = 'snapNodes_',
                name = _('snapNodesName'),
                tooltip = _('snapNodesDesc'),
                values = {
                    _('No'),
                    _('Left'),
                    _('Right'),
                    _('Both')
                },
                defaultIndex = 3
            },
            {
                key = 'tramTrack_',
                name = _('Tram track type'),
                values = {
                    -- must be in this sequence
                    _('NO'),
                    _('YES'),
                    _('ELECTRIC')
                },
                defaultIndex = 2
            },
            -- {
            --     key = 'hasBus',
            --     name = _('Bus lane'),
            --     values = {
            --         _('No'),
            --         _('Yes')
            --     },
            --     defaultIndex = 0
            -- },
            {
                key = 'pitch',
                name = _('Pitch (adjust it with O and P while building)'),
                values = pitchHelper.getPitchParamValues(),
                defaultIndex = pitchHelper.getDefaultPitchParamValue(),
                uiType = 'SLIDER'
            }
        }
    end,
}

return helper