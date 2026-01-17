CreateThread(function()
    Wait(500)

    exports.pd_core:RegisterCallout({
        name = 'traffic_stop',
        code = '10-11',
        title = 'Traffic Stop',
        description = 'Unit requested assistance during a traffic stop.',
        department = 'LSPD',
        minRank = 0,
        startEvent = 'pd_callouts:client:start',
        locations = {
            vector3(425.1, -1026.2, 28.9),
            vector3(1852.6, 3678.4, 33.3),
            vector3(-450.3, 6016.1, 30.7)
        }
    })

    exports.pd_core:RegisterCallout({
        name = 'stolen_vehicle',
        code = '10-60',
        title = 'Stolen Vehicle',
        description = 'A vehicle was reported stolen nearby.',
        department = 'LSPD',
        minRank = 0,
        startEvent = 'pd_callouts:client:start',
        locations = {
            vector3(250.3, -794.2, 30.5),
            vector3(-1079.8, -847.6, 4.9),
            vector3(1215.5, -1287.7, 35.2)
        }
    })

    exports.pd_core:RegisterCallout({
        name = 'store_robbery',
        code = '10-31',
        title = 'Store Robbery',
        description = 'Robbery in progress. Respond code 3.',
        department = 'LSPD',
        minRank = 1,
        startEvent = 'pd_callouts:client:start',
        locations = {
            vector3(24.4, -1345.7, 29.5),
            vector3(-1221.9, -908.3, 12.3),
            vector3(1729.2, 6414.2, 35.0)
        }
    })

    PDLib.debug('pd_callouts', 'registered basic callouts')
end)


