# hide #

Helper for creating animations where objects are hidden over the
course of the animation.


## Usage ##

Run `Ipelets → Hide → in current view` to hide all selected objects in
the current view.

The additional layers necessary for this are created automatically.
Specifically, if only some objects on layer `alpha` are selected, a
new layer `alpha_hide<i>` is created and the selected objects are
moved to `alpha_hide<i>`.  Moreover, `alpha_hide<i>` has the same
visibility as `alpha` except that it is invisible on the current
layer.

The command `Ipelets → Hide → in new view` has the same effect except
it creates an additional view in which the selected objects are
hidden.
