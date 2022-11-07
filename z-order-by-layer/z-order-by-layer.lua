label = "Z-Order by Layer"

about = [[ Sort the z-order of all objects on the page by layer. ]]

revertOriginal = _G.revertOriginal

function sort_by_layer(model)
   local t = { label = "sort z-order by layer",
	       pno = model.pno,
	       original = model:page():clone(),
	       undo = revertOriginal,
   }
   t.redo = function(t, doc)
      local p = doc[t.pno]
      local layers = p:layers()
      local layer_objects = {}
      for _, layer in ipairs(layers) do
         layer_objects[layer] = {}
      end

      for _, obj, _, layer in p:objects() do
         table.insert(layer_objects[layer], obj:clone())
      end

      local i = 1
      for _, layer in ipairs(layers) do
         for _, obj in ipairs(layer_objects[layer]) do
            p:replace(i, obj)
            p:setLayerOf(i, layer)
            i = i + 1
         end
      end
   end
   model:register(t)
end

methods = {
   { label = "sort", run=sort_by_layer },
}
