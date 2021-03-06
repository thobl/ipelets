label = "Plot Function"

about = [[ Very simple plotter for functions. ]]

local funcStr = "sin(pi*x) * x^2"
local xMin = -1
local xMax = 1
local step = 0.02
local yMin = -1
local yMax = 1

local function loadCode(code, environment)
   if _G.setfenv and _G.loadstring then
      local f = assert(loadstring(code))
      setfenv(f,environment)
      return f
   else
      return assert(_G.load(code, nil,"t",environment))
   end
end

local functionEvalContext = {}

functionEvalContext.abs = math.abs
functionEvalContext.acos = math.acos
functionEvalContext.asin = math.asin
functionEvalContext.atan = math.atan
functionEvalContext.ceil = math.ceil
functionEvalContext.cos = math.cos
functionEvalContext.deg = math.deg
functionEvalContext.exp = math.exp
functionEvalContext.floor = math.floor
functionEvalContext.modf = math.modf
functionEvalContext.huge = math.huge
functionEvalContext.log = math.log
functionEvalContext.max = math.max
functionEvalContext.maxinteger = math.maxinteger
functionEvalContext.min = math.min
functionEvalContext.mininteger = math.mininteger
functionEvalContext.modf = math.modf
functionEvalContext.pi = math.pi
functionEvalContext.rad = math.rad
functionEvalContext.random = math.random
functionEvalContext.randomseed = math.randomseed
functionEvalContext.sin = math.sin
functionEvalContext.sqrt = math.sqrt
functionEvalContext.tan = math.tan
functionEvalContext.tointeger = math.tointeger
functionEvalContext.type = math.type
functionEvalContext.ult = math.ult

function saveInput(d)
   funcStr = d:get("func")
   xMin = toNumber(d:get("xMin"))   
   xMax = toNumber(d:get("xMax"))
   step = toNumber(d:get("step"))
   yMin = toNumber(d:get("yMin"))
   yMax = toNumber(d:get("yMax"))
end

function loadInput(d)
   d:set("func", funcStr)
   d:set("xMin", xMin)
   d:set("xMax", xMax)
   d:set("step", step)
   d:set("yMin", yMin)
   d:set("yMax", yMax)
end

function run(model)
   local p = model:page()
   local prim = p:primarySelection()
   if not prim then
      local details = "The bounding box of your selection will be used as bounding box of your plot: the values for x-min, x-max, y-min, and y-max will match the edges of your selection."
      ipeui.messageBox(model.ui:win(), 
		       "information", "Please select something", details, nil)
      return 
   end

   local d = ipeui.Dialog(model.ui:win(), "Plot a function")
   
   d:add("label7", "label", {label="Use Lua syntax for your function!"}, 1, 1, 1, 6)
   d:add("label1", "label", {label="f(x)"}, 2, 1, 1, 1)
   d:add("func", "input", {}, 2, 2, 1, 5)
   d:add("label2", "label", {label="x-min"}, 3, 1, 1, 1)
   d:add("xMin", "input", {}, 3, 2, 1, 1)
   d:add("label3", "label", {label="x-max"}, 3, 3, 1, 1)
   d:add("xMax", "input", {}, 3, 4, 1, 1)
   d:add("label4", "label", {label="step size"}, 3, 5, 1, 1)
   d:add("step", "input", {}, 3, 6, 1, 1)
   d:add("label5", "label", {label="y-min"}, 4, 1, 1, 1)
   d:add("yMin", "input", {}, 4, 2, 1, 1)
   d:add("label6", "label", {label="y-max"}, 4, 3, 1, 1)
   d:add("yMax", "input", {}, 4, 4, 1, 1)
   
   d:addButton("ok", "&Ok", "accept")
   d:addButton("save", "&Save", saveInput)
   d:addButton("cancel", "&Cancel", "reject")
   
   loadInput(d)

   if not d:execute() then return end
   saveInput(d)
   plot(model)
end

function plot(model)
   local p = model:page()
   local prim = p:primarySelection()
   -- if not prim then model.ui:explain("select a rectangle") return end
   local bbox = p:bbox(prim)
   
   -- local func = _G.loadstring("return " .. funcStr)
   local func = loadCode("return " .. funcStr, functionEvalContext)
  
   -- plot the function
   local path = { type="curve", closed=false }
   local x = xMin
   sestX(x)
   local y = func(x)
   local lastPoint = point(x, y, xMin, xMax, yMin, yMax, bbox)
   for x = xMin + step, xMax + 0.0001, step do
      sestX(x)
      y = func(x)
      local point = point(x, y, xMin, xMax, yMin, yMax, bbox)
      path[#path + 1] = { type="segment", lastPoint, point }
      lastPoint = point
   end

   local plot = ipe.Path(model.attributes, { path })
   model:creation("create function plot", plot)
end

function point (x, y, xMin, xMax, yMin, yMax, bbox)
   local sX = bbox:width()/(xMax - xMin)
   local sY = bbox:height()/(yMax - yMin)
   local dX = bbox:left() - xMin*sX
   local dY = bbox:bottom() - yMin*sY
   local newX = x * sX + dX
   local newY = y * sY + dY
   return ipe.Vector(newX, newY)
end

function sestX (x)
   --assert(_G.loadstring("x = " .. x))()
   assert(loadCode("x = " .. x, functionEvalContext))()
end

function toNumber (str)
   if not str or str:match("^%s*$)") then return end
   local k = tonumber(str)
   if not k then
      model:warning("Enter a number!")
      return
   end
   return k
end
