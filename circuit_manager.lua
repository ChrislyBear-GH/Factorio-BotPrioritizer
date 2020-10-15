-- I thought this class would become bigger... meh.

local circ_mgr = {}
local hlp = require("helpers")



-- Go through all connected entities connect THEM to the new one,
-- NOT the other way around!
function circ_mgr.copy_circuit_connections(from_old, to_new)

    if from_old.circuit_connection_definitions then 
        for _, con_def in ipairs(from_old.circuit_connection_definitions) do -- Connections from entity in question
            local c_d_to_new = hlp.tbl_deep_copy(con_def) -- copy ConnectionDefinition
            c_d_to_new.target_entity = hlp.tbl_deep_copy(to_new) -- copy a new reference to the cloned entity as "target_entity"
            con_def.target_entity.connect_neighbour(c_d_to_new) -- Connect the former target (not the old entity) to the new one!
        end
    end
end

return circ_mgr