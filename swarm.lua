local bit = require("bit")
local Memory = require("memory")

return function()
    local Swarm = {}
    local PCOUNT = 10000
    local target_state = 0
    local gravity_blend = 1.0
    local metal_blend = 0.0    -- Restored!
    local paradox_blend = 0.0  -- Restored!
    local space_pressed_last = false

    function Swarm.Init()
        local A = Memory.Arrays
        local mem = Memory.RenderStruct -- <-- NEW: Access the C struct directly for the buffers

        local swarm_obj_id, _ = Memory.ClaimObjects(1)
        local vStart, tStart = Memory.ClaimGeometry(PCOUNT * 4, PCOUNT * 4)

        local id = swarm_obj_id
        A.Obj_X[id], A.Obj_Y[id], A.Obj_Z[id] = 0, 0, 0
        A.Obj_Radius[id] = 999999
        A.Obj_FWX[id], A.Obj_FWY[id], A.Obj_FWZ[id] = 0, 0, 1
        A.Obj_RTX[id], A.Obj_RTY[id], A.Obj_RTZ[id] = 1, 0, 0
        A.Obj_UPX[id], A.Obj_UPY[id], A.Obj_UPZ[id] = 0, 1, 0

        A.Obj_VertStart[id] = vStart; A.Obj_VertCount[id] = PCOUNT * 4
        A.Obj_TriStart[id] = tStart;  A.Obj_TriCount[id] = PCOUNT * 4

        -- =======================================================
        -- [THE DUAL-CORE SEEDING]
        -- =======================================================
        for i = 0, PCOUNT - 1 do
            -- 1. Generate the random starting values once
            local start_px = (math.random() - 0.5) * 20000
            local start_py = (math.random() - 0.5) * 10000 + 5000
            local start_pz = (math.random() - 0.5) * 20000
            local start_vx = (math.random() - 0.5) * 5000
            local start_vy = (math.random() - 0.5) * 5000
            local start_vz = (math.random() - 0.5) * 5000
            local seed = i / (PCOUNT - 1)

            -- 2. Write to BOTH buffers so Core 1 and Core 2 have valid starting data!
            mem.Swarm_PX[0][i] = start_px; mem.Swarm_PX[1][i] = start_px;
            mem.Swarm_PY[0][i] = start_py; mem.Swarm_PY[1][i] = start_py;
            mem.Swarm_PZ[0][i] = start_pz; mem.Swarm_PZ[1][i] = start_pz;

            mem.Swarm_VX[0][i] = start_vx; mem.Swarm_VX[1][i] = start_vx;
            mem.Swarm_VY[0][i] = start_vy; mem.Swarm_VY[1][i] = start_vy;
            mem.Swarm_VZ[0][i] = start_vz; mem.Swarm_VZ[1][i] = start_vz;

            -- Seed is still a single static array
            mem.Swarm_Seed[i] = seed
        end

        -- =======================================================
        -- [GEOMETRY BINDING]
        -- =======================================================
        local tIdx = tStart
        local col1 = bit.bor(0xFF000000, bit.lshift(255, 16), 0, 0)
        local col2 = bit.bor(0xFF000000, 0, bit.lshift(255, 8), 0)
        local col3 = bit.bor(0xFF000000, 0, 0, 255)
        local col4 = bit.bor(0xFF000000, 0, bit.lshift(255, 8), 255)

        for i = 0, PCOUNT - 1 do
            local base = vStart + (i * 4)
            A.Tri_V1[tIdx] = base+0; A.Tri_V2[tIdx] = base+1; A.Tri_V3[tIdx] = base+2; A.Tri_BakedColor[tIdx] = col1; tIdx = tIdx + 1
            A.Tri_V1[tIdx] = base+0; A.Tri_V2[tIdx] = base+2; A.Tri_V3[tIdx] = base+3; A.Tri_BakedColor[tIdx] = col2; tIdx = tIdx + 1
            A.Tri_V1[tIdx] = base+0; A.Tri_V2[tIdx] = base+3; A.Tri_V3[tIdx] = base+1; A.Tri_BakedColor[tIdx] = col3; tIdx = tIdx + 1
            A.Tri_V1[tIdx] = base+1; A.Tri_V2[tIdx] = base+3; A.Tri_V3[tIdx] = base+2; A.Tri_BakedColor[tIdx] = col4; tIdx = tIdx + 1
        end
    end

    function Swarm.Tick(dt)
        local space_down = love.keyboard.isDown("space")
        if space_down and not space_pressed_last then
            target_state = target_state + 1
            if target_state > 6 then target_state = 0 end -- Restored back to 6!
        end
        space_pressed_last = space_down

        if target_state == 0 then gravity_blend = math.min(1.0, gravity_blend + dt * 2.0)
        else gravity_blend = math.max(0.0, gravity_blend - dt * 2.0) end

        -- Restored Morph lerping!
        if target_state == 5 then metal_blend = math.min(1.0, metal_blend + dt * 0.5)
        else metal_blend = math.max(0.0, metal_blend - dt * 2.0) end

        if target_state == 6 then paradox_blend = math.min(1.0, paradox_blend + dt * 0.5)
        else paradox_blend = math.max(0.0, paradox_blend - dt * 2.0) end

        local mem = Memory.RenderStruct
        mem.Swarm_State = target_state
        mem.Swarm_GravityBlend = gravity_blend
        mem.Swarm_MetalBlend = metal_blend
        mem.Swarm_ParadoxBlend = paradox_blend
        mem.Swarm_Explode1 = love.mouse.isDown(1)
        mem.Swarm_Explode2 = love.mouse.isDown(2)
    end

    return Swarm
end
