----------------------------------------------------------------------
-- the default offset
Offset = 4


----------------------------------------------------------------------
-- some helper functions
function MainWindow(model)
   if model.ui.win == nil then
      return model.ui
   else
      return model.ui:win()
   end
end

function GetString(model, message)
   local str
   if ipeui.getString ~= nil then
      str = ipeui.getString(model.ui, message)
   else
      str = model:getString(message)
   end
   return str
end

function GetInt(model, message)
   local str = GetString(model, message)
   if not str or str:match("^%s*$)") then return 0 end
   return tonumber(str)
end

function ReportProblem(model, text)
   ipeui.messageBox(MainWindow(model), "warning", text, nil, nil)
end


----------------------------------------------------------------------
-- the actual code

function SetOffset(model)
   local new_offset = GetInt(model, "Enter the offset")
   Offset = new_offset
end

function RunQuickLink(model)
   local link = GetString(model, "Enter the link")
   if not link then
      return
   end

   local p = model:page()
   local prim = p:primarySelection()

   -- make sure something is selected
   if (not prim) then
      ReportProblem(model, "You must select somethings.")
      return
   end

   -- collect selected elements and compute their bounding box
   local selection = model:selection()
   local elements = {}
   local bbox = p:bbox(p:primarySelection())
   for _, obj in ipairs(selection) do
      elements[#elements + 1] = p[obj]:clone()
      bbox:add(p:bbox(obj))
   end

   -- creating the shape for the offset
   local shape = {{type="curve", closed=true,
                   {type="segment",
                    bbox:bottomLeft() - ipe.Vector(Offset, Offset),
                    bbox:topRight() + ipe.Vector(Offset, Offset),
   }}}
   local attributes = {fill="white", pathmode="filled"}
   local offset_shape = ipe.Path(attributes, shape)
   table.insert(elements, 1, offset_shape)

   local final = ipe.Group(elements)
   final:setText(link)

   p:deselectAll()
   local t = { label="quicklink",
   	      pno = model.pno,
	      vno = model.vno,
	      original = p:clone(),
	      selection = selection,
	      layer = p:active(model.vno),
	      final = final,
	      undo = _G.revertOriginal,
   }
   t.redo = function(t, doc)
      local p = doc[t.pno]
      for i = #t.selection, 1, -1 do
         p:remove(t.selection[i])
      end
      p:insert(nil, t.final, 1, t.layer)
   end
   model:register(t)
end

label = "QuickLink"
methods = {
   {label = "create link", run=RunQuickLink},
   {label = "set offset", run=SetOffset},
}
