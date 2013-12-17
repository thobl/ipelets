
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

-- Changes the transformation matrix of a path object to the identitiy
-- matrix without canging the appearance of the object (i.e., the
-- transformation matrix is applied to the objects shape)
function cleanup_matrix(path_obj)
   local matrix = path_obj:matrix()
   local matrix_func = function (point) return matrix end
   local shape = path_obj:shape()
   transform_shape(shape, matrix_func)
   path_obj:setShape(shape)
   path_obj:setMatrix(ipe.Matrix())
end

-- Transform a shape by transforming every point using a matrix
-- returend by matrix_func.  The function matrix_func should take a
-- point and return a matrix (that is then used to transform this
-- point).
--
-- Arcs are also transformed.
function transform_shape(shape, matrix_func)
   for _,path in pairs(shape) do
      for _,subpath in ipairs(path) do
	 -- apply to every point
	 for i,point in ipairs(subpath) do
	    subpath[i] = matrix_func(point) * point
	 end

	 -- apply to arcs
	 if (subpath["type"] == "arc") then
	    local arc = subpath["arc"]
	    local center = arc:matrix():translation()
	    subpath["arc"] = matrix_func(center) * arc
	 end
      end
   end
end

-- Resizes a given shape such that the same transformation also
-- transforms bbox_source to bbox_target.  The transformation is done
-- by translating points of the shape such that all points in the same
-- quadrant with respect to center are translated in the same way.
--
-- Clearly, the center has to lie inside bbox_source.
function resize_shape(shape, center, bbox_source, bbox_target)
   -- assert that the center lies inside bbox_source
   assert(bbox_source:left() < center.x)
   assert(center.x < bbox_source:left() + bbox_source:width())
   assert(bbox_source:bottom() < center.y)
   assert(center.y < bbox_source:bottom() + bbox_source:height())

   -- translation of points to the left/right/top/bottom of the center
   local dx_left = bbox_target:left() - bbox_source:left()
   local dy_bottom = bbox_target:bottom() - bbox_source:bottom()
   local dx_right = bbox_target:width() - bbox_source:width()
   local dy_top = bbox_target:height() - bbox_source:height()

   -- transformation
   local matrix_func = function (point)
      local dx = dx_left
      local dy = dy_bottom
      if (center.x < point.x) then dx = dx + dx_right end
      if (center.y < point.y) then dy = dy + dy_top end
      return ipe.Translation(dx, dy)
   end
   transform_shape(shape, matrix_func)
end

function bbox(obj, page)
   local objno = #page + 1
   page:insert(objno, obj, nil, page:layers()[1])
   local bbox = page:bbox(objno)
   page:remove(objno)
   return bbox
end

function report_problem(model, text)
   ipeui.messageBox(mainWindow(model), "warning", text, nil, nil)
end

function run_fancy_decorator (model)
   local p = model:page()
   local prim = p:primarySelection()
   local bbox_target = p:bbox(prim)

   local deco_obj_group = ask_for_decorator(model)
   if (deco_obj_group:type() ~= "group") then
      report_problem(model, "The decoration must be a group.")
      return
   end

   local objects = deco_obj_group:elements()
   local last_obj = table.remove(objects, #objects)
   local bbox_source = bbox(last_obj, p)
   local center = ipe.Vector(bbox_source:left() + 0.5 * bbox_source:width(),
			     bbox_source:bottom() + 0.5 * bbox_source:height())
   
   for i,deco_obj in ipairs(objects) do
      if (deco_obj:type() ~= "path") then
	 report_problem(model, "Each decoration object needs to be a path.")
	 return
      end

      cleanup_matrix(deco_obj)
      local deco_shape = deco_obj:shape()
      
      resize_shape(deco_shape, center, bbox_source, bbox_target)

      deco_obj:setShape(deco_shape)
   end

   local group = ipe.Group(objects)

   model:creation("fancy decoration created", group)
end

-- Asks the user for a decorator and returns the chosen decorator
-- object or nil.
function ask_for_decorator(model)
   local dialog = ipeui.Dialog(mainWindow(model), "Select a decorator.")
   local decorators = decorator_names(model)
   dialog:add("deco", "combo", decorators, 1, 1, 1, 2)
   dialog:add("ok", "button", { label="&Ok", action="accept" }, 2, 2)
   dialog:add("cancel", "button", { label="&Cancel", action="reject" }, 2, 1)
   local r = dialog:execute()
   if not r then return end
   local deco_name = decorators[dialog:get("deco")]
   local symbol = model.doc:sheets():find("symbol", deco_name)
   return symbol:clone()
end

-- Decorate something given by its bounding box with a given deco
-- object, which needs to be a path.
function decorate(model, bbox, deco)
   if (deco:type() ~= "path") then
      report_problem(model, "The decoration needs to be a path.")
      return
   end

   local shape = deco:shape()
   local m = deco:matrix()
   for _,path in pairs(shape) do
      for _,subpath in ipairs(path) do	 
	 -- move all points
	 for i,point in ipairs(subpath) do
	    subpath[i] = translation(bbox, m*point) * m*point
	 end

	 -- for acs, the center must be translated separately
	 if (subpath["type"] == "arc") then
	    local arc = subpath["arc"]
	    local arc_pos = arc:matrix():translation()
	    subpath["arc"] = translation(bbox, m*arc_pos) * m * arc
	 end
      end
   end
   -- update model
   deco:setShape(shape)
   deco:setMatrix(ipe.Matrix())
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
  { label = "Fancy decorator", run=run_fancy_decorator},
}
