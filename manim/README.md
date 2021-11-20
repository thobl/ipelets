# Manim Animations with Ipe #

[Manim](https://www.manim.community/) is python library for creating
mathematical animations that was originally written by
[3blue1brown](https://www.youtube.com/c/3blue1brown).  This ipelet
basically provides a GUI for Manim via
[Ipe](https://ipe.otfried.org/).  You can draw the objects you want to
animate in Ipe and use views to define animation steps (different Ipe
objects in different views can be linked by assigning labels to them).
The ipelet then generates python code to create the corresponding
animation.

## Example ##

  * Example Ipe file: [AnimateExample.ipe](AnimateExample.ipe)
  * Generated python file: [AnimateExample.py](AnimateExample.py)
  * Video output created by Mainim:
    [AnimateExample.mp4](AnimateExample.mp4)


## Limitations ##

At this point, this is mostly a proof-of-concept implementation.  It
only works for circles and closed polygons and the only properties
that are taken into account are the colors (stroke and fill) of the
objects.

## Usage ##

  * Create your (stop-motion) animation using views as usual in Ipe.
  * Use the ipelet to assign labels to objects.  Each label should be
    unique for each view but can (and should) be shared between
    different objects on different views.  If object A in view 1 and
    object B in view 2 have the same label, then the final animation
    will transform A into B.
  * Use the ipelet to export to python (the code will be printed in
    the command line).
  * Optional: If you want so save the file and get rid of the "missing
    symbols" warning when reopening it, run the "update style sheet"
    routine of the ipelet.
