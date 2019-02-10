
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
function arc(center, radius)
   return ipe.Arc(ipe.Matrix(radius, 0, 0, radius, center.x, center.y))
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

function line_center(v1_in, v2_in)
   local v1 = transform_to_unit_disk(v1_in)
   local v2 = transform_to_unit_disk(v2_in)
   
   local dinominator = 2 * (v1.x * v2.y - v2.x * v1.y)
   if dinominator == 0 then
      return ipe.Vector(math.huge, math.huge)
   end

   local center_x = (v1.x^2 * v2.y + v1.y^2 * v2.y + v2.y - v2.x^2 * v1.y - v2.y^2 * v1.y - v1.y) / dinominator
   local center_y = 0
   if math.abs(v1.y) > math.abs(v2.y) then
      center_y = (v1.x^2 + v1.y^2 + 1 - 2 * v1.x * center_x)/(2 * v1.y);
   else
      center_y = (v2.x^2 + v2.y^2 + 1 - 2 * v2.x * center_x)/(2 * v2.y);
   end
   local center = ipe.Vector(center_x, center_y);

   return transform_from_unit_disk(center)
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

   local center = line_center(v1, v2)
   local radius = (v1 - center):len()

   if radius == math.huge then
      if self.mode == "poincare_line" then
	 v1 = transform_to_unit_disk(v1)
	 if v1:len() == 0 then
	    v1 = transform_to_unit_disk(v2)
	 end

	 v1 = v1:normalized(v1)
	 v2 = -1*v1

	 v1 = transform_from_unit_disk(v1)
	 v2 = transform_from_unit_disk(v2)
      end
      self.shape = { segmentshape(v1, v2) }
   else
      if self.mode == "poincare_line" then
	 local c1 = arc(center, radius)
	 local c2 = arc(poincare_disk.center, poincare_disk.radius)
      	 local intersection = c1:intersect(c2)
      	 v1 = intersection[1]
      	 v2 = intersection[2]
      end
      
      local r1 = v1 - center
      local r2 = v2 - center
      
      local alpha = r1:angle()
      local beta = r2:angle()

      if ((beta - alpha >= 0) and (beta - alpha < math.pi) or
	  (beta - alpha <= 0) and (alpha - beta > math.pi)) then
	 self.shape = { arcshape(center, radius, alpha, beta) }
      else
	 self.shape = { rarcshape(center, radius, alpha, beta) }
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
  if self.cur == 2 then
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
   center_e = center_dist_e / center_e:len() * center_e

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


function poincare_line_mode(model, num)
   if num == 1 then
      model.mode = "poincare_line"
   elseif num == 2 then
      model.mode = "poincare_line_segment"
   elseif num == 3 then
      model.mode = "poincare_circle1"
   elseif num == 4 then
      model.mode = "poincare_circle2"
   elseif num == 5 then
      model.mode = "poincare_circle3"
   end
      
end

function set_disk(model, num)
   
end

methods = {
   { label = "set disk", run=set_disk},
   { label = "line tool", run=poincare_line_mode},
   { label = "line segment tool", run=poincare_line_mode},
   { label = "circle", run=poincare_line_mode},
   { label = "circle (by center + radius)", run=poincare_line_mode},
   { label = "circle (by radius + center)", run=poincare_line_mode},
}

shortcuts.ipelet_2_poincare = "H,Shift+P"
shortcuts.ipelet_3_poincare = "H,P"
shortcuts.ipelet_4_poincare = "H,O"
shortcuts.ipelet_5_poincare = "H,Shift+O"
shortcuts.ipelet_6_poincare = "H,Ctrl+O"