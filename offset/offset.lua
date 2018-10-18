
label = "Offset"

about = [[ Draw a line parallel to a path. ]]

function run(model)
   local str = getString(model, "Enter distance")
   if not str or str:match("^%s*$)") then return end
   local dist = tonumber(str)
   offset(model, dist)
end

function getString(model, string)
   if ipeui.getString ~= nil then
      return ipeui.getString(model.ui, string)
   else 
      return model:getString(string)
   end
end

function offset(model, dist)
   -- call offsetPath for each selected path
   p = model:page()

   -- collect segments and build the curves, but do not add them to
   -- the model yet (this would confuse the loop)
   local curves = {}
   print(#curves)
   for i, obj, sel, layer in p:objects() do
      local segments = {}
      if sel and obj:type() == "path" then
	 for _, subPath in ipairs(obj:shape()) do
	    for _, seg in ipairs(subPath) do
	       if (seg["type"] == "segment") then
		  -- print("segment")
		  local p1 = obj:matrix() * seg[1]
		  local p2 = obj:matrix() * seg[2]
		  table.insert(segments, {p1, p2})
	       end
	    end
	 end
	 -- get the new curve
	 curves[ #curves + 1 ] = offsetCurve(segments, dist)
      end
   end
   
   -- actually create paths with the collected curves
   print(#curves)
   for _, curve in ipairs(curves) do
      local path = ipe.Path(model.attributes, { curve })
      model:creation("segment created", path)
   end
end

function offsetCurve(segments, dist)
   -- Return a curve at distance dist from that path described by the
   -- list of points pairs in segments.

   -- move the segments by dist into the direction of thair normal
   local originalPoint = {} -- i-th entry: endpoint of i-th segment
   for _, seg in ipairs(segments) do
      originalPoint[#originalPoint + 1] = seg[2]
      local vec = seg[2] - seg[1]
      local norm = vec:orthogonal():normalized()
      seg[1] = seg[1] + dist*norm
      seg[2] = seg[2] + dist*norm
   end

   -- create a curve from the individual segments
   local curve = { type="curve", closed=false }
   for i, seg in ipairs(segments) do
      local next = segments[i+1]
      local intersection = nil
      if next then -- not the last segment
	 -- check for intersection of two consecutive segments
	 sCurr = ipe.Segment(seg[1], seg[2])
	 sNext = ipe.Segment(next[1], next[2])
	 intersection = sCurr:intersects(sNext)
	 if intersection then 
	    -- shorten segments to meet at their intersection
	    seg[2] = intersection
	    next[1] = intersection
	 end
      end
      -- add the current segment to the path
      curve[#curve + 1] = { type="segment", seg[1], seg[2] }
      -- if the segments do not intersect, create an arc
      if next and not intersection then
	 local m1 = nil
	 if dist > 0 then
	    m1 = ipe.Matrix(dist, 0, 0, -dist)
	 else
	    m1 = ipe.Matrix(dist, 0, 0, dist)
	 end
	 local m2 = ipe.Translation(originalPoint[i]) 
	 local myArc = ipe.Arc(m2*m1, next[1], seg[2])
	 -- add the arc to the path
	 curve[#curve + 1] = { type="arc", arc=myArc, seg[2], next[1]}
      end
   end
   
   -- return the curve
   return curve
end

function test(model, num)
   -- some debug output to figure out how arcs exactly work
   p = model:page()
   local write = _G.io.write
   local segments = {}
   for i, obj, sel, layer in p:objects() do
      if sel and obj:type() == "path" then
	 write("path:\n")
	 for _, subPath in ipairs(obj:shape()) do
	    write("subpath: ")
	    write(subPath["type"])
	    write("\n")
	    for _, seg in ipairs(subPath) do
	       write("segment: ")
	       write(seg["type"])
	       write("\n")
	       for key, val in pairs(seg) do
		  write(key)
		  write(" -> ")
		  print(val)
	       end
	       if seg["type"] == "arc" then
		  local arc = seg["arc"]
		  write("arc endpoints: ")
		  print(arc:endpoints())
		  write("arc matrix: ")
		  print(arc:matrix())
		  write("arc angles: ")
		  print(arc:angles())
	       end
	       write("\n")
	    end
	 end
      end
   end
end

-- methods = {
--    { label = "offset", run=run },
--    { label = "test", run=test }
-- }

----------------------------------------------------------------------
