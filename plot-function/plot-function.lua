label = "Plot Function"

function plot(model)
   local p = model:page()
   local prim = p:primarySelection()
   if not prim then model.ui:explain("select a rectangle") return end
   -- local obj = p[prim]
   local bbox = p:bbox(prim)

   local func_str = model:getString("Enter a function")
   local x_min = get_number(model, "Enter minimum value for x")
   local x_max = get_number(model, "Enter maximum value for x")
   local step = get_number(model, "Enter step value for x")
   local y_min = get_number(model, "Enter minimum value for y")
   local y_max = get_number(model, "Enter maximum value for y")

   local func = _G.loadstring("return " .. func_str)
  
   -- plot the function
   local path = { type="curve", closed=false }
   local x = x_min
   set_x(x)
   local y = func(x)
   local last_point = point(x, y, x_min, x_max, y_min, y_max, bbox)
   for x = x_min + step, x_max, step do
      set_x(x)
      y = func(x)
      local point = point(x, y, x_min, x_max, y_min, y_max, bbox)
      path[#path + 1] = { type="segment", last_point, point }
      last_point = point
   end

   local plot = ipe.Path(model.attributes, { path })
   model:creation("create function plot", plot)
end

function plot2(model)
   local p = model:page()
   local prim = p:primarySelection()
   if not prim then model.ui:explain("select a rectangle") return end
   -- local obj = p[prim]
   local bbox = p:bbox(prim)

   -- local func_str = model:getString("Enter a function")
   local x_min = 0 -- get_number(model, "Enter minimum value for x")
   local x_max = get_number(model, "Enter maximum value for x")
   local step = 1 -- get_number(model, "Enter step value for x")
   local y_min = 0 -- get_number(model, "Enter minimum value for y")
   local y_max = 0.5 -- get_number(model, "Enter maximum value for y")

   -- local func = _G.loadstring("return " .. func_str)
  
   -- plot the function
   local path = { type="curve", closed=false }
   local x = x_min
   set_x(x)
   -- print(x)
   local y = martins_f(x)
   -- print(y)
   local last_point = point(x, y, x_min, x_max, y_min, y_max, bbox)
   for x = x_min + step, x_max, step do
      set_x(x)
      y = martins_f(x)

      local point = point(x, y, x_min, x_max, y_min, y_max, bbox)
      path[#path + 1] = { type="segment", last_point, point }
      last_point = point
      
      local mark = ipe.Reference(model.attributes, "mark/disk(sx)", point)
      model:creation("new point", mark)
   end

   local plot = ipe.Path(model.attributes, { path })
   model:creation("create function plot", plot)
end


function martins_f(t)
   local p_0 = 0.49999
   local res = p_0
   for i = 1, t do
      -- print(i)
      res = dec(res)
   end
   return res
end

function dec(p)
   return 3*p*p*(1-p) + p*p*p
end

function point (x, y, x_min, x_max, y_min, y_max, bbox)
   local s_x = bbox:width()/(x_max - x_min)
   local s_y = bbox:height()/(y_max - y_min)
   local d_x = bbox:left() - x_min*s_x
   local d_y = bbox:bottom() - y_min*s_y
   local new_x = x * s_x + d_x
   local new_y = y * s_y + d_y
   return ipe.Vector(new_x, new_y)
end

function set_x (x)
   assert(_G.loadstring("x = " .. x))()
end

function test ()
   -- local f = assert(loadstring("function f(i) print(i); return i; end"))
   --- f = function () i = i + 1 end
   -- assert(loadstring("i = 0"))()

   f = _G.loadstring("return x + 1") -- compile the expression to an anonymous function
   set_x(1)
   print(f())

   -- local f = assert(loadstring("i = i + 1; return i"))
   -- f()
   -- print(f())   --> 1
   -- f()
   -- print(i)   --> 2
end

function get_number(model, text)
   local str = model:getString(text)
   if not str or str:match("^%s*$)") then return end
   local k = tonumber(str)
   if not k then
      model:warning("Enter a number between 3 and 1000!")
      return
   end
   return k
end

methods = {
   { label = "plot function", run = plot},
   { label = "plot function2", run = plot2},
   { label = "test", run = test},
}