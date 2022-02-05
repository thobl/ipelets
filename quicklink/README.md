# quicklink #

Mini ipelet for making the creation of links more convenient. 

## Usage ##

Run `Ipelets → QuickLink → create link` to create a link for the
currently selected objects.  It will prompt you for the URL and then
create a group for the selected objects with the inserted URL.  The
group will additionally contain an invisible line that slightly
extends the bounding box, so that there is an offset between the link
objects and the black box added to the PDF indicating that there is a
link.

The default value for the offset is 4 but you can change it via
`Ipelets → QuickLink → set offset`.

## Shortcut ##

If you use this regularly, you might want to add something like this
to your customization file:

```
shortcuts.ipelet_1_quicklink = "Ctrl+Alt+L"
```
