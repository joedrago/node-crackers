# This file is autogenerated. See Cakefile.

React = require 'react'
{span} = require './tags'

markdowns =
  help: "<h2>The Basics: Getting Around</h2>\n<ul>\n<li>Use the <strong>Menu</strong> button in the top left.</li>\n<li>Don't be afraid to use your browser's back button!\n<ul>\n<li><em>Seriously</em>. The whole app is built with it in mind.</li>\n<li>In Fullscreen mode, a fake back button will be drawn!</li>\n</ul></li>\n</ul>\n<h2>The Basics: Browse</h2>\n<ul>\n<li>Sort the current list using the dropdown in the top right.</li>\n<li>Click/tap on covers to view issues or more lists.</li>\n<li>Use the back button to go back to where you were.</li>\n<li><em>If your reader has progress tracking enabled:</em>\n<ul>\n<li>Use the filter button in the top right to toggle Reading, Unread, Completed, and Ignored.</li>\n<li>Clicking on the title of a browse entry will pop up a menu which will let you mark it as read/unread/ignore.</li>\n</ul></li>\n</ul>\n<h2>The Basics: Reading a Comic</h2>\n<ul>\n<li><p>On <strong>touch devices</strong> (tablets and phones):</p>\n<ul>\n<li>Double tap or pinch to zoom.</li>\n<li>Swipe left and right to switch pages.\n<ul>\n<li><em>You must be zoomed out completely!</em></li>\n</ul></li>\n<li>When zoomed, drag to scroll around.</li>\n</ul></li>\n<li><p>On <strong>desktop</strong>:</p>\n<ul>\n<li>Zoom with mousewheel, drag when zoomed to scroll around.</li>\n<li>Right click on left/right halves of the window to switch pages.</li>\n<li>Keyboard shortcuts:\n<ul>\n<li><strong>Left, Z</strong> - Previous page</li>\n<li><strong>Right, X</strong> - Next page</li>\n<li><strong>Q</strong> - Zoom to top left</li>\n<li><strong>W</strong> - Zoom to top right</li>\n<li><strong>A</strong> - Zoom to bottom left</li>\n<li><strong>S</strong> - Zoom to bottom right</li>\n<li><strong>D</strong> - Autoread back</li>\n<li><strong>F</strong> - Autoread next</li>\n<li><strong>P</strong> - Previous issue</li>\n<li><strong>N</strong> - Next issue</li>\n<li><strong>1</strong> - Set zoom to 1.5x</li>\n<li><strong>2</strong> - Set zoom to 2x</li>\n<li><strong>3</strong> - Set zoom to 3x</li>\n<li><strong>0</strong> - Zoom out</li>\n</ul></li>\n</ul></li>\n</ul>\n<hr>\n<h2>Hints and Tips</h2>\n<ul>\n<li>Settings are per-device.</li>\n<li>Settings are automatically saved when changed.</li>\n<li>On desktop, try out Autoread (D/F). It cycles between:\n<ul>\n<li>Zoom to top left</li>\n<li>Zoom to bottom right</li>\n<li>Go to next page</li>\n</ul></li>\n<li>Disabling animations in the settings can help slow devices.</li>\n<li>On small touch devices, try enabling the zoomgrid!\n<ul>\n<li>It makes the bottom center of the screen have a 3x3 grid which allows for quick zooming in and out.</li>\n<li>Press and hold in the bottom center to make the grid appear and use it.</li>\n<li>Dragging to any edge of the zoom grid will snap your view to that position.</li>\n<li>Dragging in the center square will free pan.</li>\n<li>Tapping quickly anywhere in the zoomgrid will zoom out (required for going to the next page).</li>\n</ul></li>\n</ul>\n"

class MarkdownSpan extends React.Component
  constructor: (props) ->
    super props

  render: ->
    html = markdowns[@props.name] ? ""
    return span {
      dangerouslySetInnerHTML:
        __html: html
    }

module.exports = MarkdownSpan