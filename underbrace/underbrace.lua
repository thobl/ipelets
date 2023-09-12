
label = "Underbrace"

about = [[ Create an underbrace of the desired length. ]]

function wrong_selection(model)
   model.ui:explain("You need to select a line segment.")
end

function run(model)
   local p = model:page()
   local prim = p:primarySelection()
   if not prim then wrong_selection(model) return end
   local obj = p[prim]
   if obj:type() ~= "path" then wrong_selection(model) return end
   local shape = obj:shape();
   if shape[1]["type"] ~= "curve" or shape[1][1]["type"] ~= "segment" then wrong_selection(model) return end

   local p1 = obj:matrix() * shape[1][1][1]
   local p2 = obj:matrix() * shape[1][1][2]
   local v = p2 - p1
   local sheets = model.doc:sheets()
   local stretch = sheets:find("textstretch", "normal")
   
   local underbrace = ipe.Text(
      {horizontalalignment="hcenter", verticalalignment="vcenter"},
      "$\\underbrace{\\hspace{" .. v:len() / stretch .. "pt}}$",
      ipe.Vector(0, 0))
   underbrace:set("transformations", "affine")

   underbrace:setMatrix(ipe.Translation(p1 + 0.5 * v) * ipe.Rotation(v:angle()))

   local t = { label="underbrace",
   	      pno = model.pno,
	      vno = model.vno,
	      original = p:clone(),
	      selection = model:selection(),
	      layer = p:active(model.vno),
	      underbrace = underbrace,
	      undo = _G.revertOriginal,
   }
   t.redo = function(t, doc)
      local p = doc[t.pno]
      p:insert(nil, t.underbrace, nil, t.layer)
   end
   model:register(t)

end

