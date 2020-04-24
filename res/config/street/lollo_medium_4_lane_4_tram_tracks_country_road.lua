function data()
    return {
        --numLanes = 2,
        laneConfig = {
            {
                forward = false,
                transportModesLane = {'BUS', 'ELECTRIC_TRAM', 'PERSON', 'TRAM'},
                transportModes = {'BUS', 'ELECTRIC_TRAM', 'PERSON', 'TRAM'}
            },
            {
                forward = false,
                transportModesLane = {'BUS', 'CAR', 'ELECTRIC_TRAM', 'TRAM'},
                transportModes = {'BUS', 'CAR', 'ELECTRIC_TRAM', 'TRAM'}
            },
            {
                forward = false,
                transportModesLane = {'BUS', 'CAR', 'ELECTRIC_TRAM', 'TRAM', 'TRUCK'},
                transportModes = {'BUS', 'CAR', 'ELECTRIC_TRAM', 'TRAM', 'TRUCK'}
            },
            {
                forward = true,
                transportModesLane = {'BUS', 'CAR', 'ELECTRIC_TRAM', 'TRAM', 'TRUCK'},
                transportModes = {'BUS', 'CAR', 'ELECTRIC_TRAM', 'TRAM', 'TRUCK'}
            },
            {
                forward = true,
                transportModesLane = {'BUS', 'CAR', 'ELECTRIC_TRAM', 'TRAM'},
                transportModes = {'BUS', 'CAR', 'ELECTRIC_TRAM', 'TRAM'}
            },
            {
                forward = true,
                transportModesLane = {'BUS', 'ELECTRIC_TRAM', 'PERSON', 'TRAM'},
                transportModes = {'BUS', 'ELECTRIC_TRAM', 'PERSON', 'TRAM'}
            }
        },
        transportModesStreet = {'CAR', 'BUS', 'ELECTRIC_TRAM', 'TRAM', 'TRUCK'}, -- with this, tram tracks appear on all lanes, not only on the right one
        streetWidth = 12.0,
        sidewalkWidth = 2.0, -- was 4.0; 2 * sidewalkWidth + streetWidth must be 16
        sidewalkHeight = .00,
        yearFrom = 1925,
        yearTo = 0,
        upgrade = false,
        country = true,
        speed = 80.0,
        -- priority = this crashes 5, -- LOLLO NOTE this is copied from airports, it should give priority to this street
        type = 'lollo_medium_4_lane_4_tram_tracks_country_road',
        name = _('Medium country road with 4 lanes and 4 tram tracks'),
        desc = _('Medium country road with 4 lanes crammed in, each with a tram track. Speed limit is %2%.'),
        categories = {'country'},
        materials = {
            streetPaving = {
                name = 'street/country_new_medium_paving.mtl',
                size = {8.0, 8.0}
            },
            streetBorder = {
                name = 'street/country_new_large_border.mtl',
                size = {24, 0.459}
            },
            junctionBorder = {
                name = 'street/country_new_large_border.mtl',
                size = {24, 0.459}
            },
            streetLane = {
                name = 'street/new_medium_lane.mtl',
                size = {3.0, 3.0}
            },
            streetStripe = {
                name = 'street/country_new_medium_stripes.mtl',
                size = {32.0, .5}
            },
            streetStripeMedian = {
                name = 'street/country_new_large_median.mtl',
                size = {4.0, .5}
            },
            streetTram = {
                name = 'street/new_medium_tram_paving.mtl',
                size = {2.0, 2.0}
            },
            streetTramTrack = {
                name = 'street/new_medium_tram_track.mtl',
                size = {2.0, 2.0}
            },
            streetBus = {
                name = 'street/new_medium_bus.mtl',
                size = {12, 2.7}
            },
            crossingLane = {
                name = 'street/new_medium_lane.mtl',
                size = {3.0, 3.0}
            },
            crossingBus = {
                name = ''
            },
            crossingTram = {
                name = 'street/new_medium_tram_paving.mtl',
                size = {2.0, 2.0}
            },
            crossingTramTrack = {
                name = 'street/new_medium_tram_track.mtl',
                size = {2.0, 2.0}
            },
            sidewalkLane = {},
            sidewalkBorderInner = {}
        },
        borderGroundTex = 'street_border.lua',
        sidewalkFillGroundTex = 'country_sidewalk.lua',
        cost = 50.0
    }
end
