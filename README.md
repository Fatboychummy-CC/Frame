# Frame
A simple double-buffer for your screens

## Usage:

Download the file, then load it via `require`

Once loaded, the following function is available:

`Frame.new(<terminal object>)`

Frame does not overwrite the terminal object, but rather returns a new object that wraps it.  The terminal object can be a monitor, the CC terminal, even a terminal in your overlay glasses (if you're cool enough to have one).

Once you create a Frame Buffer, you can use it just any other terminal object.  Some functions which edit particular parts of a terminal object don't exist, however (like, for example, `setPaletteColor`).  There are a few functions which this adds, however.

### `FrameBuffer.Initialize()`
The most important function.  This function will initialize (or reinitialize) the buffers.  All calls to anything in a Frame Buffer will likely error without calling this function first.

This function also handles terminal size.  If you resize the terminal, you need to call this.  Take note that it will clear anything currently on the buffers.

### `FrameBuffer.PushBuffer()`
This function will compare the first buffer to the second buffer, and if any updates need to occur, will update the screen.

### `FrameBuffer.PostRedisplay()`
This function will set a flag that will, upon your next call to `FrameBuffer.PushBuffer()` force the whole screen to update no matter what, even if nothing changed.
