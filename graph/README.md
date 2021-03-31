# graph

This ipelet helps when drawing graphs.

## Features

The menu entry `toggle graph mode` turns a new graph editing mode on
and off (by default it is on).  The graph mode adds the feature that
vertices of a graph can be moved such that the incident edges follow
automatically.  At the moment this only works for vertices represented
by marks.

### Moving Vertices

Select a mark and press `Ctrl + E` to edit the position of the vertex.
Move the displayed cycle to a new position (changing its radius does
not have any effect) and press the space key.  The mark moves to the
new position and all endpoints of poly-lines and splines incident to
the previous position of the mark follow.

There are two different modes.  Either, only visible edges or all
edges on the current page are changed.  The menu entry `toggle move
invisible` switches between these two modes (by default only visible
edges are changed).

### Shortening Edges

Using the `shorten target/source/both` commands you can shorten edges
by a specified distance.  This is useful if you have directed edges
with arrowheads hiding under vertices (or vice versa).  Instead of
shortening each of them by hand, you can select all of them and run
the ipelet (at least if all vertices have the same size).

## Notes

Since Ipe 7.2.5, Ipe itself has a feature for moving vertices of a
graph.  So you probably also want to check that out.

## Changes

  * **26 August 2015** the ipelet should now also work with Ipe 7.1.7 and
	Ipe 7.1.8

  * **8 November 2013** new mode that only changes edges that are
    currently visible; see [Moving Vertices](#moving-vertices) (previously, all edges on
    the current page were modified)

  * **29 April 2012** shortening edges should now work with version
    7.1.2 of Ipe

  * **26 April 2012** first version of the Graph Ipelet online
