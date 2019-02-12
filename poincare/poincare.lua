
label = "Poincaré Disk Model"

about = [[ The Poincaré disk model for the hyperbolic plane. ]]

local poincare_disk = { radius = 64, center = ipe.Vector(64, 64) }

----------------------------------------------------------------------
-- overwriting the original function
----------------------------------------------------------------------
function _G.MODEL:poincare_backup_startModeTool (modifiers) end
_G.MODEL.poincare_backup_startModeTool = _G.MODEL.startModeTool

function _G.MODEL:startModeTool(modifiers)
   if self.mode:sub(1, 13) == "poincare_line" then
      POINCARE_LINETOOL:new(self, self.mode)
   elseif self.mode:sub(1, 15) == "poincare_circle" then
      POINCARE_CIRCLETOOL:new(self, self.mode)
   else
      self:poincare_backup_startModeTool(modifiers)
   end
end

setmetatable = _G.setmetatable
type = _G.type

----------------------------------------------------------------------
-- basic stuff from  goodies.lua
----------------------------------------------------------------------
function checkPrimaryIsCircle(model, arc_ok)
   local p = model:page()
   local prim = p:primarySelection()
   if not prim then model.ui:explain("no selection") return end
   local obj = p[prim]
   if obj:type() == "path" then
      local shape = obj:shape()
      if #shape == 1 then
	 local s = shape[1]
	 if s.type == "ellipse" then
	    return prim, obj, s[1]:translation(), shape
	 end
	 if arc_ok and s.type == "curve" and #s == 1 and s[1].type == "arc" then
	    return prim, obj, s[1].arc:matrix():translation(), shape
	 end
      end
   end
   if arc_ok then
      model:warning("Primary selection is not an arc, a circle, or an ellipse")
   else
      model:warning("Primary selection is not a circle or an ellipse")
   end
end

----------------------------------------------------------------------
-- basic shapes from tools.lua
----------------------------------------------------------------------
local function segmentshape(v1, v2)
   return { type="curve", closed=false; { type="segment"; v1, v2 } }
end

local function circleshape(center, radius)
   return { type="ellipse";
	    ipe.Matrix(radius, 0, 0, radius, center.x, center.y) }
end

local function arcshape(center, radius, alpha, beta)
   local a = ipe.Arc(ipe.Matrix(radius, 0, 0, radius, center.x, center.y),
		     alpha, beta)
   local v1 = center + radius * ipe.Direction(alpha)
   local v2 = center + radius * ipe.Direction(beta)
   return { type="curve", closed=false; { type="arc", arc=a; v1, v2 } }
end

local function rarcshape(center, radius, alpha, beta)
   local a = ipe.Arc(ipe.Matrix(radius, 0, 0, -radius, center.x, center.y),
		     alpha, beta)
   local v1 = center + radius * ipe.Direction(alpha)
   local v2 = center + radius * ipe.Direction(beta)
   return { type="curve", closed=false; { type="arc", arc=a; v1, v2 } }
end

----------------------------------------------------------------------
-- some other basic stuff
----------------------------------------------------------------------
function arcshape_by_endpoints(center, radius, v1, v2)
   local r1 = v1 - center
   local r2 = v2 - center
   local alpha = r1:angle()
   local beta = r2:angle()
   if ((beta - alpha >= 0) and (beta - alpha < math.pi) or
       (beta - alpha <= 0) and (alpha - beta > math.pi)) then
      return arcshape(center, radius, alpha, beta)
   else
      return rarcshape(center, radius, alpha, beta)
   end
end

function circle_intersect(c1, r1, c2, r2)
   local R = (c1 - c2):sqLen()
   local tmp1 = 0.5 * (c1 + c2)
   tmp1 = tmp1 + (r1^2 - r2^2)/(2 * R) * (c2 - c1)
   local tmp2 = 0.5 * math.sqrt(2 * (r1^2 + r2^2)/R - (r1^2 - r2^2)^2/(R^2) - 1)
   tmp2 = tmp2 * ipe.Vector(c2.y - c1.y, c1.x - c2.x)
   return tmp1 + tmp2, tmp1 - tmp2
end

----------------------------------------------------------------------
-- poincaré disk computations
----------------------------------------------------------------------
function distance(v1, v2)
   v1 = transform_to_unit_disk(v1)
   v2 = transform_to_unit_disk(v2)
   local res = 1 + 2 * (v1 - v2):sqLen() / ((1 - v1:sqLen()) * (1 - v2:sqLen()))
   return math.log(res + math.sqrt(res^2 - 1))
end

function radius_hyperbolic_to_euclidean(radius)
   return (math.exp(radius) - 1) / (math.exp(radius) + 1)
end

function transform_to_unit_disk(v)
   if type(v) == "number" then
      return v / poincare_disk.radius
   else
      return 1 / poincare_disk.radius * (v - poincare_disk.center)
   end
end

function transform_from_unit_disk(v)
   if type(v) == "number" then
      return  poincare_disk.radius * v
   else 
      return poincare_disk.radius * v + poincare_disk.center
   end
end

-- assumes the stadard Poincaré with center (0, 0) and radius 1
function ideal_points(center, radius, v1, v2)
   local ideal_point1 = ipe.Vector()
   local ideal_point2 = ipe.Vector()
   if radius == math.huge then
      if v1:len() == 0 then v1 = v2 end
      ideal_point1 = v1:normalized()
      ideal_point2 = -ideal_point1
   else
      ideal_point1, ideal_point2 =
	 circle_intersect(center, radius, ipe.Vector(0, 0), 1)
   end
   return ideal_point1, ideal_point2
end

function poincare_line(v1, v2)
   local v1 = transform_to_unit_disk(v1)
   local v2 = transform_to_unit_disk(v2)

   local center = ipe.Vector()
   local denominator = 2 * (v1.x * v2.y - v2.x * v1.y)
   if denominator == 0 then
      center = ipe.Vector(math.huge, math.huge)
   else 
      local center_x = (v1.x^2 * v2.y + v1.y^2 * v2.y + v2.y - 
			v2.x^2 * v1.y - v2.y^2 * v1.y - v1.y) / denominator
      local center_y = 0
      if math.abs(v1.y) > math.abs(v2.y) then
	 center_y = (v1.x^2 + v1.y^2 + 1 - 2 * v1.x * center_x)/(2 * v1.y);
      else
	 center_y = (v2.x^2 + v2.y^2 + 1 - 2 * v2.x * center_x)/(2 * v2.y);
      end
      center = ipe.Vector(center_x, center_y);
   end

   local radius = (v1 - center):len()

   local ideal_point1, ideal_point2 = ideal_points(center, radius, v1, v2)

   center = transform_from_unit_disk(center)
   radius = transform_from_unit_disk(radius)
   ideal_point1 = transform_from_unit_disk(ideal_point1)
   ideal_point2 = transform_from_unit_disk(ideal_point2)

   return center, radius, ideal_point1, ideal_point2
end

-- line perpendicular to line through v1 and v2 containing v2
function perpendicular_line(v1, v2, v3)
   local c, r = poincare_line(v1, v2)
   c = transform_to_unit_disk(c)
   r = transform_to_unit_disk(r)

   v1 = transform_to_unit_disk(v1)
   v2 = transform_to_unit_disk(v2)
   v3 = transform_to_unit_disk(v3)

   local center = ipe.Vector()

   if r == math.huge then
      local center_y = (v3.y + v3.x^2 * v3.y + v3.y^3) / (2 * v3.x^2 + 2 * v3.y^2)
      local center_x = v3.x / v3.y * center_y
      if v3.y == 0 then
	 center_x = (v3.x^2 + v3.y^2 - 2 * v3.y * center_y + 1) / (2 * v3.x)
      end
      center = ipe.Vector(center_x, center_y)
   else
      local center_y = (c.x^2 * v3.x - c.x * v3.x^2 +
			c.y^2 * v3.x - c.x * v3.y^2 +
			v3.x - r^2 * v3.x - c.x) / (2 * c.y * v3.x - 2 * c.x * v3.y)
      local center_x = (v3.x^2 + v3.y^2 - 2 * v3.y * center_y + 1) / (2 * v3.x)
      if v3.x == 0 then
	 center_x = (c.x^2 + c.y^2 - 2 * c.y * center_y - r^2 + 1) / (2 * c.x)
      end
      center = ipe.Vector(center_x, center_y)
   end

   local radius = (center - v3):len()
   
   local tmp = ipe.Vector()
   if radius~=radius or radius > 1e+10 then
      if r == math.huge then
	 tmp = (v1 - v2):orthogonal()
      else
	 tmp = c:normalized()
      end
      center = ipe.Vector(math.huge, math.huge)
      radius = math.huge
   end
   local ideal_point1, ideal_point2 = ideal_points(center, radius, tmp, ipe.Vector())
   
   radius = transform_from_unit_disk(radius)
   center = transform_from_unit_disk(center)
   ideal_point1 = transform_from_unit_disk(ideal_point1)
   ideal_point2 = transform_from_unit_disk(ideal_point2)
   return center, radius, ideal_point1, ideal_point2
end

-- line through v2 tangent to ouclidean line through v1 and v2
function line_by_tangent(v1, v2)
   v1 = transform_to_unit_disk(v1)
   v2 = transform_to_unit_disk(v2)
   
   -- local center_y = (a * u^2 - a * v^2 - a + 2 * b * u * v - u^3 - u * v^2 + u) / (2 * b * u - 2 * a * v)
   local center_y = (v1.x * v2.x^2 - v1.x * v2.y^2 - v1.x +
		     2 * v1.y * v2.x * v2.y
		     - v2.x^3 - v2.x * v2.y^2 + v2.x) / (2 * v1.y * v2.x - 2 * v1.x * v2.y)
   local center_x = (v2.x^2 - 2 * v2.y * center_y + v2.y^2 + 1) / (2 * v2.x)
   if v2.x == 0 then
      center_x = (v1.y * v2.y - v2.y^2 + (v2.y - v1.y) * center_y) /  v1.x
   end
   local center = ipe.Vector(center_x, center_y)
   local radius = (center - v2):len()

   if (radius ~= radius or radius > 1e+10) then
      center = ipe.Vector(math.huge, math.huge)
      radius = math.huge
   end
   
   local ideal_point1, ideal_point2 = ideal_points(center, radius, v1, v2)

   radius = transform_from_unit_disk(radius)
   center = transform_from_unit_disk(center)
   ideal_point1 = transform_from_unit_disk(ideal_point1)
   ideal_point2 = transform_from_unit_disk(ideal_point2)
   return center, radius, ideal_point1, ideal_point2
end

----------------------------------------------------------------------
-- the drawing tools
----------------------------------------------------------------------
POINCARE_LINETOOL = {}
POINCARE_LINETOOL.__index = POINCARE_LINETOOL

function POINCARE_LINETOOL:new(model, mode)
   local tool = {}
   setmetatable(tool, POINCARE_LINETOOL)
   tool.model = model
   tool.mode = mode
   local v = model.ui:pos()
   tool.v = { v, v}
   tool.cur = 2
   model.ui:shapeTool(tool)
   tool.setColor(1.0, 0, 0)
   return tool
end

function POINCARE_LINETOOL:compute()
   local v1 = self.v[1]
   local v2 = self.v[2]
   self.shape = {}
   self.model.ui:explain("hyperbolic length: " .. tostring(distance(v1, v2)), 0)

   local center, radius, ideal_point1, ideal_point2 = poincare_line(v1, v2)

   if self.mode == "poincare_line_tangent" and v1 ~= v2 then
      center, radius, ideal_point1, ideal_point2 = line_by_tangent(v1, v2)
      self.shape[#self.shape + 1] = segmentshape(v1, v2)
   end

   if self.mode == "poincare_line" or self.mode == "poincare_line_tangent" then
      v1 = ideal_point1
      v2 = ideal_point2
   end

   if radius == math.huge then
      self.shape[#self.shape + 1] = segmentshape(v1, v2) 
   else
      self.shape[#self.shape + 1] = arcshape_by_endpoints(center, radius, v1, v2)
   end

   if self.mode == "poincare_line_right_angle" then
      local v3 = v2
      if (self.cur == 3) then v3 = self.v[3] end
      local center, radius, ideal_point1, ideal_point2 = perpendicular_line(v1, v2, v3)
      if radius == math.huge then
	 self.shape[#self.shape + 1] = segmentshape(ideal_point1, ideal_point2)
      else
	 self.shape[#self.shape + 1] = arcshape_by_endpoints(center, radius, ideal_point1, ideal_point2)
      end
   end
end

function POINCARE_LINETOOL:mouseButton(button, modifiers, press)
   if not press then return end
   local v = self.model.ui:pos()
   -- refuse point identical to previous
   if v == self.v[self.cur - 1] then return end
   self.v[self.cur] = v
   self:compute()
   if self.cur == 3 or button == 2 or 
      (self.mode ~= "poincare_line_right_angle" and self.cur == 2) then
      -- if self.mode == "poincare_line_right_angle" then
      -- 	 table.remove(self.shape, 1)
      -- end
      self.shape = { self.shape[#self.shape] }
      self.model.ui:finishTool()
      local obj = ipe.Path(self.model.attributes, self.shape, true)
      self.model:creation("create line", obj)
   else
      self.cur = self.cur + 1
      self.model.ui:update(false)
   end
end

function POINCARE_LINETOOL:mouseMove()
   self.v[self.cur] = self.model.ui:pos()
   self:compute()
   self.setShape(self.shape)
   self.model.ui:update(false) -- update tool
end

function POINCARE_LINETOOL:key(text, modifiers)
   if text == "\027" then
      self.model.ui:finishTool()
      return true
   else
      return false
   end
end

----------------------------------------------------------------------

POINCARE_CIRCLETOOL = {}
POINCARE_CIRCLETOOL.__index = POINCARE_CIRCLETOOL

function POINCARE_CIRCLETOOL:new(model, mode)
   local tool = {}
   setmetatable(tool, POINCARE_CIRCLETOOL)
   tool.model = model
   tool.mode = mode
   local v = model.ui:pos()
   tool.v = { v, v, v}
   tool.cur = 2
   model.ui:shapeTool(tool)
   tool.setColor(1.0, 0, 0)
   return tool
end

function POINCARE_CIRCLETOOL:compute()
   local center = self.v[1]
   local radius_h = distance(center, self.v[2])
   
   if self.mode == "poincare_circle2" and self.cur == 2 then
      self.model.ui:explain("specify a radius by klicking two points (their distance is used as radius)", 0)
      self.shape = circleshape(center, 1)
      return
   end
   if self.mode == "poincare_circle3" and self.cur == 2 then
      self.shape = circleshape(center, 1)
      self.model.ui:explain("hyperbolic radius: " .. tostring(radius_h), 0)
      return
   end
   
   if self.mode == "poincare_circle2" and self.cur == 3 then
      radius_h = distance(self.v[2], self.v[3])
   end
   if self.mode == "poincare_circle3" and self.cur == 3 then
      center = self.v[3]
   end

   self.model.ui:explain("hyperbolic radius: " .. tostring(radius_h), 0)
   
   if radius_h == 0 then
      self.shape = circleshape(center, 0)
      return
   end
   
   local center_dist_h = distance(poincare_disk.center, center)
   local boundary1_dist_h = center_dist_h - radius_h
   local boundary2_dist_h = center_dist_h + radius_h

   local boundary1_dist_e = radius_hyperbolic_to_euclidean(boundary1_dist_h)
   local boundary2_dist_e = radius_hyperbolic_to_euclidean(boundary2_dist_h)
   local center_dist_e = (boundary1_dist_e + boundary2_dist_e) / 2
   local radius_e = center_dist_e - boundary1_dist_e

   local center_e = transform_to_unit_disk(center)
   if center_e:len() ~= 0 then
      center_e = center_dist_e / center_e:len() * center_e
   end

   self.shape = circleshape(transform_from_unit_disk(center_e), transform_from_unit_disk(radius_e))
end

function POINCARE_CIRCLETOOL:mouseButton(button, modifiers, press)
   if not press then return end
   local v = self.model.ui:pos()
   -- refuse point identical to previous
   if v == self.v[self.cur - 1] then return end
   self.v[self.cur] = v
   self:compute()
   if self.cur == 3 or (self.cur == 2 and self.mode == "poincare_circle1") then
      self.model.ui:finishTool()
      local obj = ipe.Path(self.model.attributes, { self.shape })
      self.model:creation("create circle", obj)
   else
      self.cur = self.cur + 1
      self.model.ui:update(false)
   end
end

function POINCARE_CIRCLETOOL:mouseMove()
   self.v[self.cur] = self.model.ui:pos()
   self:compute()
   self.setShape({ self.shape })
   self.model.ui:update(false) -- update tool
end

function POINCARE_CIRCLETOOL:key(text, modifiers)
   if text == "\027" then
      self.model.ui:finishTool()
      return true
   else
      return false
   end
end

----------------------------------------------------------------------

function poincare_line_mode(model, num)
   if num == 2 then
      model.mode = "poincare_line"
      model.ui:explain("Poincaré tool: line through two points")
   elseif num == 3 then
      model.mode = "poincare_line_segment"
      model.ui:explain("Poincaré tool: line segment between two points")
   elseif num == 4 then
      model.mode = "poincare_line_right_angle"
      model.ui:explain("Poincaré tool: right angle")
   elseif num == 5 then
      model.mode = "poincare_line_tangent"
      model.ui:explain("Poincaré tool: tangent")
   elseif num == 6 then
      model.mode = "poincare_circle1"
      model.ui:explain("Poincaré tool: cirle (center = first point, radius = distance between center and second point)")
   elseif num == 7 then
      model.mode = "poincare_circle2"
      model.ui:explain("Poincaré tool: cirle (center = first point, radius = distance between second and third point)")
   elseif num == 8 then
      model.mode = "poincare_circle3"
      model.ui:explain("Poincaré tool: cirle (radius = distance between first and second point, center = thrid point)")
   end
   
end

function set_disk(model, num)
   -- poincare_disk = { radius = 64, center = ipe.Vector(64, 64) }
   local prim, obj, pos, shape = checkPrimaryIsCircle(model, false)
   _G.transformShape(obj:matrix(), shape)
   local m = shape[1][1]
   local center = m:translation()
   local v = m * ipe.Vector(1,0)
   local radius = (v - center):len()
   poincare_disk.radius = radius
   poincare_disk.center = center
   model.ui:explain("Set center and radius of the Poincaré disc to: center = "
		    .. tostring(center) .. " | radius = " .. tostring(radius), 0)
end

methods = {
   { label = "set disk", run=set_disk},
   { label = "line tool", run=poincare_line_mode},
   { label = "line segment tool", run=poincare_line_mode},
   { label = "right angle tool", run=poincare_line_mode},
   { label = "tangent tool", run=poincare_line_mode},
   { label = "circle tool", run=poincare_line_mode},
   { label = "circle tool (by center + radius)", run=poincare_line_mode},
   { label = "circle tool (by radius + center)", run=poincare_line_mode},
}

shortcuts.ipelet_1_poincare = "H,D"
shortcuts.ipelet_2_poincare = "H,Shift+P"
shortcuts.ipelet_3_poincare = "H,P"
shortcuts.ipelet_4_poincare = "H,Ctrl+P"
shortcuts.ipelet_5_poincare = "H,Alt+P"
shortcuts.ipelet_6_poincare = "H,O"
shortcuts.ipelet_7_poincare = "H,Shift+O"
shortcuts.ipelet_8_poincare = "H,Ctrl+O"