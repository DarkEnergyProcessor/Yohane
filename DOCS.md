Yohane Documentation
====================
Yohane, able to run in every game environment which uses Lua 5.1 to allow images to be loaded and a timer function
which is called for every game frame update.

Base Functions
--------------

#### `void Yohane.Init([function loader[, string sysroot]])`

Initialize Yohane Flash Abstraction

Parameters:

* `loader` - Function to use when loading `YohaneFlash.lua` and `YohaneMovie.lua` which similar to Lua
function `loadfile`. Defaults to `loadfile`

* `sysroot` - Path where `YohaneFlash.lua` and `YohaneMovie.lua` located. Defaults to current directory.

> Calling this if it's already initialized is no-op

*****************************

#### `YohaneFlash Yohane.newFlashFromStream(file stream[, string movie_name])`

#### `YohaneFlash Yohane.newFlashFromString(string str[, string movie_name])`

#### `YohaneFlash Yohane.newFlashFromFilename(string filename[, string movie_name])`

Loads Playground flash file from specificed stream/string/filename

Parameters:

* `stream` - File stream. This object must contain `read(number bytes)` method which reads from specificed stream

* `str` - String containing the whole Playground flash contents

* `filename` - Playground flash file path

* `movie_name` - Once loaded, set animation to render

Returns: `YohaneFlash` object

YohaneFlash Object Methods
--------------------------

Note: `PlatformImage` object in here is platform-dependant image object.

*****************************

#### `YohaneFlash YohaneFlash:clone()`

Clone current `YohaneFlash` object to new instance

Returns: New `YohaneFlash` object with same animation data

*****************************

#### `void YohaneFlash:update(number deltaT)`

Updates `YohaneFlash` object state (like running animation instruction)

Parameter:

* `deltaT` - Time difference between 2 time points, in milliseconds

*****************************

#### `void YohaneFlash:draw([number x, number y])`

Draws animation, optionally in specificed coordinates

Parameters:

* `x` - X coordinate

* `y` - Y coordinate

*****************************

#### `void YohaneFlash:setMovie(string movie_name)`

Set animation to render

Parameters:

* `movie_name` - Animation name

> This function automatically unfreeze the flash animation

*****************************

#### `void YohaneFlash:jumpToLabel(string label_name)`

Jumps animation to specificed label name

Parameters:

* `label_name` - Jump to this label

> This function automatically unfreeze the flash animation

*****************************

#### `void YohaneFlash:setImage(string pseudo_image_name[, PlatformImage image])`

Sets pseudo-image to specificed image. Pseudo-image name starts with `%` prefix.

Parameters:

* `pseudo_image_name` - Pseudo image name, without `I%` prefix

* `image` - New image to set (or `nil` to clear it)

*****************************

#### `void YohaneFlash:setOpacity([number opacity = 255])`

Set animation opacity

Parameters:

* `opacity` - Flash image opacity (defaults to `255`)

*****************************

#### `PlatformImage YohaneFlash:getImage(string image_name)`

Get `PlatformImage` object for specificed image name without `I` prefix and `.png.imag` suffix. Pseudo-image name
must start with `%` prefix

Parameters:

* `image_name` - Flash image name to retrieve it's `PlatformImage` object

Returns: `PlatformImage` object, a platform-dependant image handle (can be anything depending on platform).

*****************************

#### `bool YohaneFlash:isFrozen()`

Check if current flash is frozen. That's it, it encounter `STOP_INSTRUCTION`. Frozen flash animation doesn't get
updated when `YohaneFlash:update(deltaT)` is called.

Returns: `true` if it's frozen, `false` otherwise.

*****************************

#### `void YohaneFlash:unFreeze()`

Unfreeze flash animation. Allowing it to updating when `YohaneFlash:update(deltaT)` is called.

Platform-Specific Functions
---------------------------

To add new compatible platform, one must implement these functions.

Note: `PlatformAudio` is platform-dependant audio handle (can be anything)

*****************************

#### `PlatformImage Yohane.Platform.ResolveImage(string path)`

Called when Yohane tries to load flash animation images

Parameters:

* `path` - The image path, without `I` prefix and without `.imag` suffix (PNG image)

Returns: `PlatformImage` object

Example:
```lua
function Yohane.Platform.ResolveImage(path)
	return love.graphics.newImage(path)
end
-- OR
Yohane.Platform.ResolveImage = love.graphics.newImage
```

*****************************

#### `PlatformImage Yohane.Platform.CloneImage(PlatformImage image)`

Called when Yohane tries to clone image used by flash animation (calling `YohaneFlash:clone()` for example)

Parameters:

* `image` - `PlatformImage` object which needs to be cloned.

Returns: New `PlatformImage` object.

> Depending on platform, same image handle can be used (LOVE2D for example)

*****************************

#### `PlatformAudio Yohane.Platform.ResolveAudio(string path)`

Called when Yohane tries to load audio used by flash animation

Parameter:

* `path` - The audio path, **without extension**. It's up to platform responsibility to add extension to it

Returns: New `PlatformAudio` object or `nil` on failure

*****************************

#### `PlatformAudio Yohane.Platform.CloneAudio(PlatformAudio audio)`

Same as `PlatformImage Yohane.Platform.CloneImage(PlatformImage image)` except this is for audio.

Parameters:

* `audio` - The audio handle. It also can be `nil` where in this case simply return `nil`.

Returns: New `PlatformAudio` object or `nil` if `audio` is `nil`

*****************************

#### `void Yohane.Platform.PlayAudio(PlatformAudio audio)`

Called when Yohane tries to play audio

Parameter:

* `audio` - The audio handle (can be `nil`)

*****************************

#### `void Yohane.Platform.Draw(table drawdatalist)`

Called when Yohane requests to draw images. `drawdatalist` contains lists of images to be drawn on screen,
ordered by it's appearance (first is lowest, last is highest). For every element in there, it contains:

* `x` - Image X position (relative to topmost part of image)

* `y` - Image Y position (relative to leftmost part of image)

* `scaleX` - Image scale X

* `scaleY` - Image scale Y

* `rotation` - Image rotation (in radians)

* `r`, `g`, `b`, `a` - Image colors (RGBA). Values range from 0-255

Parameters:

* `drawdatalist` - Lists of images to be drawn in their respective order

Example:
```lua
function Yohane.Platform.Draw(drawdatalist)
	local r, g, b, a = love.graphics.getColor()
	
	for _, drawdata in ipairs(drawdatalist) do
		if drawdata.image then
			love.graphics.setColor(drawdata.r, drawdata.g, drawdata.b, drawdata.a)
			love.graphics.draw(drawdata.image, drawdata.x, drawdata.y, drawdata.rotation, drawdata.scaleX, drawdata.scaleY)
		end
	end
	
	love.graphics.setColor(r, g, b, a)
end
```

*****************************

#### `file Yohane.Platform.OpenReadFile(string path)`

Called when Yohane tries to load flash image specificed in `path` (calling `Yohane.newFlashFromFilename` for example).
This function is optional and defaults to `io.open` if none is found

Parameters:

* `path` - Path to the file

Returns: File stream
