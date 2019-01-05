
label = "Move along path"

about = [[ Animation moving something along a path. ]]

revertOriginal = _G.revertOriginal

function run(model, num)
   -- selection should be one a mark, a group, and a path
   p = model:page()
   local group
   local sourcePosition
   local targetPositions = {}
   for _, i in ipairs(model:selection()) do
      local obj = p[i]
      if obj:type() == "group" then
	 group = obj
      end
      if obj:type() == "reference" then 
	 sourcePosition = obj:matrix() * obj:position()
      end
      if obj:type() == "path" then
	 for _, subPath in ipairs(obj:shape()) do
	    -- selected path found -> collect the segments
	    for j, seg in ipairs(subPath) do
	       if (seg["type"] == "segment") then
		  if (j == 1) then
		     table.insert(targetPositions, obj:matrix() * seg[1])
		  end
		  table.insert(targetPositions, obj:matrix() * seg[2])
	       end
	    end
	 end
      end
   end
   
   local clones = {}
   for i,_ in  ipairs(targetPositions) do
      clones[i] = group:clone()
   end

   local t = { label = "moving group along path",
	       pno = model.pno,
	       vno = model.vno,
	       selection = model:selection(),
	       original = model:page():clone(),
	       group = group,
	       sourcePosition = sourcePosition,
	       targetPositions = targetPositions,
	       clones = clones,
	       undo = revertOriginal,
   }
   t.redo = function (t, doc)
      local p = doc[t.pno]
      local initialView = t.vno
      for i, point in ipairs(t.targetPositions) do
	 -- print(point)
	 local layerName = p:addLayer(p:active(initialView) .. tostring(i))
	 p:insertView(initialView + i, layerName)
	 p:setVisible(initialView + i, layerName, true)
	 for _, layer in ipairs(p:layers()) do
	    if (p:visible(initialView, layer)) then
	       p:setVisible(initialView + i, layer, true)
	    end
	 end
	 local m = ipe.Translation(point - t.sourcePosition)
	 p:insert(nil, t.clones[i], 0, layerName)
	 p:transform(#p, m)
      end
      model:setPage()
   end
   model:register(t)
end
