
label = "Offset"

about = [[ Draw a line parallel to a path. ]]

local roundCorners = true

function toggleRoundCorners(model, num)
   roundCorners = not roundCorners
end

function run(model, num)
   local dist = getInt(model, "Enter distance")
   if dist == 0 then
      return
   end
   if num == 1 then 
      offset(model, dist, false)
   elseif num == 2 then
      offset(model, dist, true)
   end
end

function getInt(model, string)
   local str
   if ipeui.getString ~= nil then
      str = ipeui.getString(model.ui, string)
   else 
      str = model:getString(string)
   end
   if not str or str:match("^%s*$)") then return 0 end
   return tonumber(str)
end

-- For each selected path, create the offset path for the given
-- distance.
function offset(model, dist, area)
   p = model:page()
   -- collect segments and build the paths, but do not add them to the
   -- model yet (this would confuse the loop)
   local paths = {}
   for i, obj, sel, layer in p:objects() do
      if sel and obj:type() == "path" then
	 for _, subPath in ipairs(obj:shape()) do
	    -- selected path found -> collect the segments
	    local segments = {}
	    local closed = subPath["closed"]
	    for _, seg in ipairs(subPath) do
	       if (seg["type"] == "segment") then
		  local p1 = obj:matrix() * seg[1]
		  local p2 = obj:matrix() * seg[2]
		  table.insert(segments, {p1, p2})
	       end
	    end
	    -- create the offset curve
	    local curve = offsetCurve(segments, dist, closed)
	    -- create the path
	    local path = nil
	    -- no area -> just add the path
	    if not area then 
	       path = ipe.Path(model.attributes, { curve })
	    end
	    -- area for a closed path -> composition with the original
	    -- curve
	    if area and closed then
	       local origCurve = { type="curve", closed=true }
	       addToCurve(origCurve, segments)
	       path = ipe.Path(model.attributes, { curve, origCurve })
	    end
	    -- area of open path -> concatenate original path with
	    -- offset path
	    if area and not closed then
	       segments[#segments + 1] = {segments[#segments][2], curve[#curve][2]}
	       reverseSegments(segments)
	       addToCurve(curve, segments)
	       curve["closed"] = true
	       path = ipe.Path(model.attributes, { curve })
	    end
	    paths[ #paths + 1 ] = path
	 end
      end
   end
   
   -- actually create paths with the collected curves
   for _, path in ipairs(paths) do
      model:creation("segment created", path)
   end
end

-- Add some segments to a given curve.
function addToCurve(curve, segments)
   for _, seg in ipairs(segments) do
      curve[#curve + 1] = { type="segment", seg[1], seg[2] }
   end
end

-- Reverses the order of a list of segments (and reverses each segment
-- itself).
function reverseSegments(segments)
   local i, j = 1, #segments

   while i < j do
      segments[i], segments[j] = segments[j], segments[i]
      i = i + 1
      j = j - 1
   end

   for _, seg in ipairs(segments) do
      seg[1], seg[2] = seg[2], seg[1]
   end
end

-- Return a curve at distance dist from that path described by the
-- list of points pairs in segments.
function offsetCurve(segs, dist, closed)
   -- add closing segment if curve is closed
   if closed then
      segs[#segs + 1] = {segs[#segs][2], segs[1][1]}
   end
   
   -- shift the segments
   local newSegs = shiftedSegments(segs, dist)

   -- create the curve from the shifted segments
   local curve = { type="curve", closed=closed }
   for i, seg in ipairs(newSegs) do
      -- nicely join consecutive segments
      local next = nextSegment(newSegs, i, closed)
      local arc = joinSegments(seg, next, segs[i][2], dist)
      
      -- add the current segment to the path but skip the first
      -- segment if the curve is closed
      if not (closed and i == 1) then
	 curve[#curve + 1] = { type="segment", seg[1], seg[2] }
      end

      -- create the connecting arc
      if arc then
	 curve[#curve + 1] = arc
      end
   end
   
   -- return the curve
   return curve
end

-- Return a new list of segments obtained by shifting each segment by
-- dist along its normal.
function shiftedSegments(segments, dist)
   local result = {}
   for i, seg in ipairs(segments) do
      local vec = seg[2] - seg[1]
      local norm = vec:orthogonal():normalized()
      result[i] = {seg[1] + dist*norm, seg[2] + dist*norm}
   end
   return result
end

-- Return the next segment after i in a list of segments (modulo is
-- closed is true).
function nextSegment(segments, i, closed)
   local next = segments[i+1]
   if not next and closed then
      next = segments[1]
   end
   return next
end

-- If seg1 and seg2 intersect, they are shortened such that the
-- endpoint of seg1 coincides with the endpoint of seg2.  Otherwise,
-- an arc (with given center and radius) joining the endpoint of seg1
-- with the startpoint of seg2 is returned.  The sign of radius
-- indicates whether the arc goes clockwise or counterclockwise.
function joinSegments(seg1, seg2, center, radius)
   -- return nil if one of the segments is nil
   if not seg1 or not seg2 then return nil end

   -- lengthen both segments if the tarnsition should be sharp
   if not roundCorners then
      local p1 = seg1[2]
      local p2 = seg1[1]
      local pDelta = p1 - p2
      local pNorm = pDelta:normalized()
      local newP1 =  p1 + pNorm * 500
      seg1[2] = newP1

      local q1 = seg2[1]
      local q2 = seg2[2]
      local qDelta = q1 - q2
      local qNorm = qDelta:normalized()
      local newQ1 =  q1 + qNorm * 500
      print(q1)
      print(q2)
      print(seg2[1])
      seg2[1] = newQ1
      print(seg2[1])
   end
   
   -- shorten to intersection (and stop if there is one)
   local intersection = shortenToIntersection(seg1, seg2)
   if intersection then return nil end
   
   -- create the arc
   local m1 = nil
   if radius > 0 then
      m1 = ipe.Matrix(radius, 0, 0, -radius)
   else
      m1 = ipe.Matrix(radius, 0, 0, radius)
   end
   local m2 = ipe.Translation(center)
   local myArc = ipe.Arc(m2*m1, seg2[1], seg1[2])
   return { type="arc", arc=myArc, seg1[2], seg2[1]}
end

-- Shorten the segments to their intersection (if exists) such that
-- the endpoint of seg1 coincides with the startpoint of seg2.  The
-- intersection is returned (nil if there is no intersection).
function shortenToIntersection(seg1, seg2)
   local intersection = nil
   -- create ipe segments
   seg1Ipe = ipe.Segment(seg1[1], seg1[2])
   seg2Ipe = ipe.Segment(seg2[1], seg2[2])
   intersection = seg1Ipe:intersects(seg2Ipe)
   if intersection then 
      -- shorten segments to meet at their intersection
      seg1[2] = intersection
      seg2[1] = intersection
   end
   return intersection
end

-- some debug output to figure out how arcs exactly work
function test(model, num)
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

methods = {
   { label = "Offset path", run=run },
   { label = "Offset area", run=run },
   { label = "Toggle round corners", run=toggleRoundCorners },
   -- { label = "test", run=test }
}

----------------------------------------------------------------------
