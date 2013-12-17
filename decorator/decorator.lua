
-- return a table of names associated with decorator symbols
function decorator_names(model)
   local sheets = model.doc:sheets()
   local symbols = sheets:allNames("symbol")
   local res = {}
   for _, name in pairs(symbols) do
      if name:find("deco/") == 1 then
	 res[#res + 1] = name
      end
   end
   return res
end

-- Decorate something given by its bounding box with a given deco
-- object, which needs to be a path.
function decorate(model, bbox, deco)
   if (deco:type() ~= "path") then
      model.ui:explain("The decoration needs to be a path.")
      return
   end

   local shape = deco:shape()
   for _,path in pairs(shape) do
      for _,subpath in ipairs(path) do	 
	 -- move all points
	 for i,point in ipairs(subpath) do
	    subpath[i] = translation(bbox, point) * point
	 end

	 -- for acs, the center must be translated separately
	 if (subpath["type"] == "arc") then
	    local arc = subpath["arc"]
	    local arc_pos = arc:matrix():translation()
	    subpath["arc"] = translation(bbox, arc_pos) * arc
	 end
      end
   end
   -- update model
   deco:setShape(shape)
   model:creation("create", deco)
end

-- The translation matrix that should be applied to a given point when
-- doing the decoration.
function translation(bbox, point)
   local dx = 0
   local dy = 0
   if (point.x > 0) then
      dx = dx + bbox:width()
   end
   if (point.y > 0) then
      dy = dy + bbox:height()
   end
   dx = dx + bbox:left()
   dy = dy + bbox:bottom()
   return ipe.Translation(dx, dy)
end

function mainWindow(model)
   if model.ui.win == nil then
      return model.ui
   else
      return model.ui:win()
   end
end

function run_decorator(model)
   -- get bbox of primary selection
   local p = model:page()
   local prim = p:primarySelection()
   if not prim then
      model.ui:explain("An object must be selected.")
      return
   end
   local bbox = p:bbox(prim)

   -- create decorator object
   local dialog = ipeui.Dialog(mainWindow(model), "Select a decorator.")
   local decorators = decorator_names(model)
   dialog:add("deco", "combo", decorators, 1, 1, 1, 2)
   dialog:add("ok", "button", { label="&Ok", action="accept" }, 2, 2)
   dialog:add("cancel", "button", { label="&Cancel", action="reject" }, 2, 1)
   local r = dialog:execute()
   if not r then return end
   local deco_name = decorators[dialog:get("deco")]
   local symbol = model.doc:sheets():find("symbol", deco_name)
   local deco = symbol:clone()

   -- run the decoration
   decorate(model, bbox, deco)
end

label = "Decorator"
methods = {
  { label = "Decorate", run=run_decorator},
}
