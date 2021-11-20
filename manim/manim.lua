----------------------------------------------------------------------
-- helper functions
----------------------------------------------------------------------

-- helper for compatibility with different ipe-versions
function MainWindow(model)
   if model.ui.win == nil then
      return model.ui
   else
      return model.ui:win()
   end
end


-- showing error messages
function ReportProblem(model, text)
   ipeui.messageBox(MainWindow(model), "warning", text, nil, nil)
end



----------------------------------------------------------------------
-- labels for objects
----------------------------------------------------------------------

function OpacityToLabel(opacity)
   if string.sub(opacity, 0, 6) ~= "label:" then
      return nil
   end
   return string.sub(opacity, 7)
end


function LabelToOpacity(label)
   return "label:" .. label
end


function GetObjectLabel(obj)
   return OpacityToLabel(obj:get("opacity"))
end


function SetObjectLabel(obj, label)
   obj:set("opacity", LabelToOpacity(label))
end


-- user function for setting the label of selected objects
function SetLabel(model)
   local p = model:page()
   local prim = p:primarySelection()
   if (not prim) then
      ReportProblem(model, "You must select something.")
      return
   end

   local prev_label = GetObjectLabel(p[prim])
   local label = model:getString(
      "Enter label for the selected object(s)", "Enter label", prev_label)
   if not label or label:match("^%s*$") then return end
   label = label:gsub(" ", "_")

   for obj = 1, #p, 1 do
      if p:select(obj) then
         SetObjectLabel(p[obj], label)
      end
   end
end


-- return the style sheet for storing labels (and create it if it does
-- not exist yet)
function GetLabelSheet(model)
   local sheet_name = "labels_via_opacity"
   local doc = model.doc
   local sheets = doc:sheets()
   for i = 1, sheets:count() do
      local sheet = sheets:sheet(i)
      if (sheet:name() == sheet_name) then
         return sheet
      end
      sheet = ipe.Sheet()
      sheet:setName(sheet_name)
      sheets:insert(1, sheet)
      return sheet
   end
end


-- set of labels used for objects
function LabelsUsedForObjects(model)
   local doc = model.doc
   local labels = {}
   for _, p in doc:pages() do
      for _, obj, _, _ in p:objects() do
         local label = GetObjectLabel(obj)
         if label then
            labels[label] = true
         end
      end
   end
   return labels
end


-- set of labels defined in the label style sheet
function LabelsInStyleSheet(model)
   local doc = model.doc
   local labels = {}
   for _, opacity in pairs(doc:sheets():allNames("opacity")) do
      local label = OpacityToLabel(opacity)
      if label then
         labels[label] = true
      end
   end
   return labels
end


-- make sure the style sheet contains all required labels
function UpdateLabelSheet(model)
   -- collect the required labels
   local needed_labels = LabelsUsedForObjects(model)

   -- collect the labels existing in the style sheet
   local existing_labels = LabelsInStyleSheet(model)

   -- create missing labels
   local sheet = GetLabelSheet(model)
   for label, _ in pairs(needed_labels) do
      if not existing_labels[label] then
         sheet:add("opacity", LabelToOpacity(label), 1)
      end
   end
end



----------------------------------------------------------------------
-- creating the animation

function ObjectsByView(model, page)
   local obj_by_view = {}
   for view = 1, page:countViews() do
      obj_by_view[view] = {}
   end

   local unlabeled_id = 1
   for _, obj, _, layer in page:objects() do
      local label = GetObjectLabel(obj)
      if not label then
         label = "object_with_no_label" .. unlabeled_id
         unlabeled_id = unlabeled_id + 1
      end

      for view = 1, page:countViews() do
         if page:visible(view, layer) then
            if obj_by_view[view][label] then
               ReportProblem(model, "Multiple objects with the name " .. label .. " in view " .. view)
            end
            obj_by_view[view][label] = obj
         end
      end
   end

   return(obj_by_view)
end


function VariableName(label, view)
   local name = label .. "_v" .. view
   return name
end

AspectRatio = 16.0 / 9.0
Height = 8.0
Width = Height * AspectRatio
Scale = 0.02


function PointToManim(x, y)
   return {x = Scale * x - Width / 2, y = Scale * y - Height / 2}
end


function SizeToManim(r)
   return r * Scale
end


function Color(model, name)
   local rgb = model.doc:sheets():find("color", name)
   return "rgb_to_color([" .. rgb.r .. ", " .. rgb.g .. ", " .. rgb.b .. "])"
end


function Properties(model, obj)
   local result = ""
   if obj:get("pathmode") ~= "filled" then
      result = result .. "color = " .. Color(model, obj:get("stroke")) .. ","
   else
      result = result .. "stroke_opacity = 0.0, "
   end

   if obj:get("pathmode") ~= "stroked" then
      result = result .. "fill_color = " .. Color(model, obj:get("fill")) .. ", fill_opacity=1, "
   end

   return result
end


function PrintCode(code, depth)
   local format_string = string.format("%%%ds", depth * 4)
   local space = string.format(format_string, "")
   print(space .. string.gsub(code, "\n", "\n" .. space))
end


function Create(model, obj, name)
   local props = Properties(model, obj)

   if obj:type() == "path" then
      local shape = obj:shape()
      -- TODO: assuming just one subpath
      local path = shape[1]
      if path.type == "ellipse" then

         local m = path[1]
         local c = obj:matrix() * m:translation()
         local v1 = obj:matrix():linear() * m:linear() * ipe.Vector(1, 0)
         local v2 = obj:matrix():linear() * m:linear() * ipe.Vector(0, 1)

         c = PointToManim(c.x, c.y)

         if v1:sqLen() == v2:sqLen() then
            -- circle
            local r = SizeToManim(v1:len())
            return string.format("%s = Circle(radius=%f, arc_center=[%f, %f, 0.0], %s)",
                                 name, r, c.x, c.y, props)
         else
            -- ellipse
            local r1 = SizeToManim(v1:len());
            local r2 = SizeToManim(v2:len());
            local angle = v1:angle();

            local create = string.format("%s = Ellipse(width=%f, height=%f, arc_center=[%f, %f, 0.0], %s)",
                                         name, 2 * r1, 2 * r2, c.x, c.y, props)
            local rotate = string.format("%s.rotate(%f)", name, angle)

            return create .. "\n" .. rotate
         end

      elseif path.type == "curve" then
         -- TODO: assuming a closed polygon
         local points = {obj:matrix() * path[1][1]}
         for segment = 1, #path do
            table.insert(points, obj:matrix() * path[segment][2])
         end
         local point_list = name .. "_points = [\n"
         for _, point in pairs(points) do
            local p = PointToManim(point.x, point.y)
            point_list = point_list .. "    [" .. p.x .. ", " .. p.y .. ", 0],\n"
         end
         point_list = point_list .. "]"
         local create = string.format("%s = Polygon(*%s_points, %s)", name, name, props)
         return point_list .. "\n" .. create
      end
   end
   return nil
end


function Export(model)
   PrintCode("from manim import *", 0)
   PrintCode("", 0)
   PrintCode("class AnimateExample(Scene):", 0)
   PrintCode("def construct(self):", 1)
   PrintCode("self.camera.background_color = WHITE", 2)

   local p = model:page()
   local obj_by_view = ObjectsByView(model, p)

   -- dummy entries ith no objects (so there has to be no special
   -- treatment for the first or last view)
   obj_by_view[0] = {}
   obj_by_view[#obj_by_view + 1] = {}

   -- variable name (in python) most recently used for an object
   local name_by_label = {}

   -- remembering objects to remove after the current view
   local to_be_removed = {}

   for view = 1, p:countViews() + 1 do
      PrintCode("## view " .. view, 2)

      -- collect animations occurring for this view
      local anims = {}
      local post_anim = {}

      -- deletion animations (objects from the previous view no longer
      -- existing here)
      for _, name in pairs(to_be_removed) do
         table.insert(anims, "FadeOut(" .. name .. ")")
         table.insert(post_anim, "self.remove(".. name .. ")")
      end
      to_be_removed = {}

      -- collect animations for existing objects in this view
      for label, obj in pairs(obj_by_view[view]) do
         local prev_obj = obj_by_view[view - 1][label]
         if not prev_obj then
            -- object with new label -> create
            local name = VariableName(label, view)
            PrintCode(Create(model, obj, name), 2)
            table.insert(anims, "Create(".. name .. ")")
            name_by_label[label] = name

         elseif prev_obj ~= obj then
            -- new object with existing label -> transform
            local name = VariableName(label, view)
            local prev_name = name_by_label[label]
            PrintCode(Create(model, obj, name), 2)
            table.insert(anims, "Transform(" .. prev_name .. ", " .. name .. ")")
            table.insert(post_anim, "self.remove(".. prev_name .. ")")
            name_by_label[label] = name
         end

         -- objects to be removed in the next view
         local next_obj = obj_by_view[view + 1][label]
         if not next_obj then
            table.insert(to_be_removed, name_by_label[label])
         end
      end

      -- do the animations
      PrintCode("self.play(", 2)
      for _, anim in pairs(anims) do
         PrintCode(anim .. ",", 3)
      end
      PrintCode(")", 2)

      -- post-animiation cleanup
      for _, post in pairs(post_anim) do
         PrintCode(post, 2)
      end
   end
end


label = "manim"
methods = {
  { label = "set label", run=SetLabel },
  { label = "update label sheet", run=UpdateLabelSheet },
  { label = "export", run=Export },
}

shortcuts.ipelet_1_manim = "tab,L"
shortcuts.ipelet_2_manim = "tab,S"
shortcuts.ipelet_3_manim = "tab,E"