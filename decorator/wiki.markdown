# Decorator Ipelet #

With the decorator ipelet, you can decorate other objects (by for example surrounding them with a box).  The ipelet is flexible in the sense that you can define your own decorator objects.  The following example (click on the figure to download the ipe-file) illustrates the usage.

[![example](Decorator_Ipelet/attachment/decorator.svg)](Decorator_Ipelet/attachment/decorator.ipe)

# Download & Installation #

Download [decorator.lua](Decorator_Ipelet/attachment/decorator.lua) and copy it to ~/.ipe/ipelets/ (or to some other directory for ipelets).

# Usage #

Run "Ipelets->Decorator->decorate" to decorate the currently selected objects.  For that to work, there must be decorator objects (symbols with prefix "deco/") defined in your stylesheet (see the example above).

# Creating Decorator Objects #

To create your own decorator object, execute the following steps.

1. Create a rectangle, lets call it R.
2. Create path objects, that decorate R (usually some kind of box around R).  You can use multiple objects for the decoration.
3. Make sure that R is the front most object (select R and press Ctrl+F).
4. Group R together with the decoration (select R and the decoration and press Ctrl+G).
5. Run "Ipelets->Decorator->create deco-object".

Note that "Ipelets->Decorator->create deco-object" only slightly extends "Ipelets->Symbols->create symbol" (it checks whether the selected object can be used as decorator object and it automatically adds the prefix "deco/").

# Changes #

**14. October 2014**
first version of the decorator ipelet online
