
label = "Hide"

about = [[ Add a view where the selected objects are hidden. ]]

revertOriginal = _G.revertOriginal

function hideName(layer, i)
   return(layer .. "_hide" .. tostring(i))
end

-- get a mapping from layers that contain selected to new layer names
-- to which the objects should be moved to be hidden
function targetLayers(model)
   local p = model:page()
   local layers = p:layers()
   local layerSet = {}
   local targetLayer = {}
   for _, layer in ipairs(layers) do
      layerSet[layer] = true
   end

   for _, objno in ipairs(model:selection()) do
      local layer = p:layerOf(objno)
      local i = 0
      while(layerSet[hideName(layer, i)]) do
         i = i + 1;
      end
      targetLayer[layer] = hideName(layer, i)
   end

   return(targetLayer)
end

-- return a map from layers to number of objects on the layer
function objectCountsByLayer(p)
   local res = {}
   for _, layer in pairs(p:layers()) do
      res[layer] = 0
   end
   for _, _, _, layer in p:objects() do
      res[layer] = res[layer] + 1
   end
   return res
end

function hide(model, num)
   local targetLayer = targetLayers(model)

   local t = { label = "hiding selected objects",
	       pno = model.pno,
	       vno = model.vno,
	       selection = model:selection(),
	       original = model:page():clone(),
	       targetLayer = targetLayer,
	       undo = revertOriginal,
   }
   t.redo = function (t, doc)
      local p = doc[t.pno]
      local oldLayers = p:layers()
      local currView = t.vno
      -- create new layers with same visibility as old layers
      for old, new in pairs(t.targetLayer)do
         p:addLayer(new)
         for v = 1, p:countViews() do
            if (p:visible(v, old)) then
               p:setVisible(v, new, true)
            end
         end
         -- hide in current view
         if num == 1 then
            p:setVisible(currView, new, false)
         end
      end

      -- move selected objects to newly created layers
      for _, objno in ipairs(t.selection) do
         local layer = p:layerOf(objno)
         p:setLayerOf(objno, t.targetLayer[layer])
      end

      if num == 2 then
         -- hide in new view
         p:insertView(currView + 1, p:active(currView))
         for _, layer in ipairs(oldLayers) do
            if (p:visible(currView, layer)) then
               p:setVisible(currView + 1, layer, true)
            end
         end
      end

      -- reposition layers in layer list
      local offset = 1
      for i, layer in ipairs(oldLayers) do
         if t.targetLayer[layer] then
            p:moveLayer(t.targetLayer[layer], i + offset)
            offset = offset + 1
         end
      end

      -- clean up empty layers
      local objCount = objectCountsByLayer(p)
      for old, new in pairs(t.targetLayer) do
         if objCount[old] == 0 then
            p:removeLayer(old)
            p:renameLayer(new, old)
         end
      end
   end
   model:register(t)

end

methods = {
   { label = "in current view", run=hide },
   { label = "in new view", run=hide },
}
