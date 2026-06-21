<!-- keywords: mulle-video, debugger, quirks, uiavimoviewriter, jpgencoder, tiny-jpeg -->
# Quirks

## `UIAVIMovieWriter`

- `src/UIAVIMovieWriter.m` asserts positive width, height, and FPS before it tries to open the AVI. A debug build will stop there before any file I/O clue appears.
- `frameRateHz` is a `CGFloat` in the Objective-C API but is rounded to an integer for `gwavi_open`. Fractional-rate playback complaints can be real even when the caller passed a float.
- `UIAVIMovieMJPGCodec` (`0`) is the only codec path shown in the repo. Any nonzero codec is unpacked into a raw fourcc byte sequence, with endian-dependent code and no demo coverage.
- `addBitmap:freeWhenDone:` is not a separate encoder path. It just wraps `imageWithBitmap:freeWhenDone:` and then falls through to `addBitmapImage:`.
- The class is marked `MulleObjCThreadSafe`, but the only async demo still serializes writes through one queue. Treat a movie as one ordered stream while debugging.

## `UIBitmapImage (JPGEncoder)`

- The header in `src/UIBitmapImage+JPGEncoder.h` is the ownership rule: free the returned `struct mulle_data` yourself.
- Ignore the stale `// the returned data is autoreleased!` comment in `src/UIBitmapImage+JPGEncoder.m`; the implementation extracts raw buffer data and the writer frees those bytes explicitly.
- `JPGCDataWithQuality:allocator:` returns invalid data immediately when `[self bytes]` is `NULL`.
- The quality parameter is not continuous. `CGFloatProjectClamped` maps `0..100` onto `1..3`, then the code rounds again before calling TinyJPEG.
- The category always passes `4` components to TinyJPEG, so odd source bitmap layouts usually fail upstream, before any AVI-specific code runs.

## `tiny-jpeg.h`

- The vendored encoder only accepts `3` (RGB) or `4` (RGBA) source components.
- Quality values outside `1..3` are rejected in `src/tiny-jpeg.h`; the Objective-C category hides that with clamping, but direct C callers do not get that protection.
- `TJE_IMPLEMENTATION` is already defined in `src/UIBitmapImage+JPGEncoder.m`. Do not debug duplicate-symbol issues by adding another implementation site.

## Source-trust rules

- Prefer `src/reflect/_MulleVideo-export.h` over `src/MulleVideo.h` when you need the exported header list.
- Prefer `demo/src/main-write-movie.m` and `demo/src/main-write-movie2.m` over `demo/README.md` for frame count and shutdown behavior. The README still says the demo writes 20 frames; the sources currently use `RECORD_FRAMECOUNT 120`.
- There are no repo tests for this surface, so demo sources and the public headers are the trustworthy local reproducer set.
