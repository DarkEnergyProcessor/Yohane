Yohane Flash Abstraction
========================
Yohane is a Playground Flash Abstraction layer, written in Lua 5.1 (compilant and pure)
without any additional dependencies (like bit library and such). It decomposes the flash
animation to lists of draw calls in-order which is simpler for users (especially for LOVE2D users)

What is NOT Yohane
==================
Yohane doesn't come with rendering function and image loading function. Yohane task
is just calculating animation data. You're responsible to write your image loading
routines. In short, Yohane doesn't draw the images.

With this model, Yohane can be ported to other game framework which uses Lua 5.1

When will it complete?
======================
I don't know, but soon. Please don't ask this.
