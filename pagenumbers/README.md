# pagenumbers

This ipelet provides some page numbering features.

## Usage

To enable page numbering, add a layer with the name
*pagenumbers_format* to the first page.  The text objects in that
layer are copied to every page where every occurrence of the
placeholder `[page]` is replaced by the current page number.  This is
done every time latex runs.

### Special Layers

Besides the above mentioned layer *pagenumbers_format* there are other
layers with a special meaning.
  * ***pagenumbers_format:*** On this layer the format for the page
	numbers is specified (see description above).  It is not necessary
	(and usually not desired) that this layer is visible.

  * ***pagenumbers_page:*** This layer contains the page number and is
    automatically created on every page.  To hide the page number on a
    specific page, just make this layer invisible.

  * ***pagenumbers_dont_count:*** If a page contains this layer, the
	page count is not increased for this page.

## Example

See [example.ipe](example.ipe).

## Notes

Since Ipe 7.2.5, Ipe itself allows some styling of the page numbers,
which is sufficient for most cases.  Only use this ipelet if you need
more control.

