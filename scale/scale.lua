
--------------------------------------------------------------------------------
-- working with groups ---------------------------------------------------------

local function regroup(elem)
   local groupElem = {}
   for i, obj in ipairs(elem) do
      if obj[1] ~= nil then
	 groupElem[#groupElem + 1] =  regroup(obj)
      else 
	 groupElem[#groupElem + 1] = obj
      end
   end
   local res = ipe.Group(groupElem)
   res:setMatrix(elem["matrix"])
   return res
end

local function ungroup(group)
   local elem = group:elements()
   elem["matrix"] = group:matrix()
   local plainElem = {}
   for i, obj in ipairs(elem) do
      if (obj:type() == "group") then
	 local subElem, subPlainElem = ungroup(obj)
	 elem[i] = subElem;
	 for _, subObj in ipairs(subPlainElem) do
	    table.insert(plainElem, subObj)
	 end
      else
	 table.insert(plainElem, obj)
      end
   end
   return elem, plainElem
end

-- Applies the function func to the object page[obj_id].  If
-- page[obj_id] is a group, func is recursively applied to every
-- element in this group.
function apply_recursively(page, obj_id, funct)
   obj = page[obj_id]
   if obj:type() == "group" then
      local elem, plainElem = ungroup(obj)
      for _,subobj in pairs(plainElem) do
	 funct(subobj)
      end
      page:replace(obj_id, regroup(elem))
   else
      funct(obj)
   end	    
end




-- Helper for compatibility with different ipe-versions.
function mainWindow(model)
   if model.ui.win == nil then
      return model.ui
   else
      return model.ui:win()
   end
end

-- Show a warning to the user.
function report_problem(model, text)
   ipeui.messageBox(mainWindow(model), "warning", text, nil, nil)
end

function get_number(model, obj, property, kind)
   local res = obj:get(property)
   if (_G.type(res) == "number") then
      return res
   else
      local sheets = model.doc:sheets()
      return sheets:find(kind, res)
   end
end

function scale_property(model, obj, property, kind, factor)
   obj:set(property, get_number(model, obj, property, kind) * factor)
end

function scale_unscalable(model, obj, factor)
   if (obj:type() == "reference") then
      scale_property(model, obj, "symbolsize", "symbolsize", factor)
   end
   if (obj:type() == "path") then
      scale_property(model, obj, "pen", "pen", factor)
      scale_property(model, obj, "farrowsize", "arrowsize", factor)
      scale_property(model, obj, "rarrowsize", "arrowsize", factor)
   end
end

function scale_test (model)
   local p = model:page()
   local str = model:getString("Enter scale factor")
   if not str or str:match("^%s*$") or not str:match("^[%+%-%d%.]+$") then
      return
   end
   local factor = tonumber(str)
    
   local t = { label = "scaling",
	       pno = model.pno,
	       vno = model.vno,
	       selection = model:selection(),
	       original = model:page():clone(),
	       matrix = matrix,
	       undo = _G.revertOriginal,}
   t.redo = function (t, doc)
      local p = doc[t.pno]
      -- for _, i in ipairs(t.selection) do
      -- 	 p:setSelect(i, 2)
      -- end
      local p = doc[t.pno]
      for i, obj, sel, layer in p:objects() do
	 if sel then
	    apply_recursively(p, i, function (obj) scale_unscalable(model, obj, factor) end)
	 end	    
      end
   end
   model:register(t)
end



label = "scale_test"
methods = {
  { label = "scale_test", run=scale_test },
}
