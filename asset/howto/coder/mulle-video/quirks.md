<!-- keywords: mulle-video, quirks, uiavimoviewriter, jpgencoder, tiny-jpeg -->
# Quirks

## `UIAVIMovieWriter`

- `initWithFileUTF8String:bitmapSize:frameRateHz:codec:` asserts positive width, height, and FPS in `src/UIAVIMovieWriter.m`. Do not feed `0` sizes or a zero frame rate.
- `frameRateHz` is stored as a `CGFloat` on the Objective-C side but passed to `gwavi_open` as `round( frameRateHz)`. Fractional rates are effectively rounded to whole FPS.
- `UIAVIMovieMJPGCodec` (`0`) means "use the built-in `MJPG` fourcc". Non-zero codec values are treated as raw fourcc bytes; that path is not demonstrated anywhere in this repo.
- `addBitmapImage:` always converts the image to the writer's RGBA `bitmapInfo` before JPEG encoding. Mismatched source size or format is allowed, but it costs a conversion/scale step.
- The class is marked `MulleObjCThreadSafe`, but the demos still serialize writes through one queue. Treat one movie writer as a single ordered stream.
- Call `close` yourself. `finalize` also calls it, but the demos do not rely on that fallback.

## `UIBitmapImage (JPGEncoder)`

- The header is the trustworthy ownership rule: the returned `struct mulle_data` must be freed by the caller.
- `JPGCDataWithQuality:allocator:` projects `0..100` onto TinyJPEG quality levels `1..3` with `CGFloatProjectClamped`. Quality is coarse, not a continuous slider.
- The encoder path uses the image's current bitmap bytes. If `[self bytes]` is `NULL`, the method returns invalid data instead of silently inventing a conversion.
- The implementation always encodes with `4` components when it calls TinyJPEG, so the category assumes bitmap data that is already compatible with the repo's RGBA-oriented path.

## `tiny-jpeg.h`

- Supported component counts are only `3` (RGB) and `4` (RGBA).
- Supported quality values are only `1`, `2`, or `3`; passing anything else is an error in the encoder.
- `src/UIBitmapImage+JPGEncoder.m` already defines `TJE_IMPLEMENTATION`. Do not add a second implementation site when extending this library.

## Source-trust rules

- For exported-header inventory, prefer `src/reflect/_MulleVideo-export.h` over `src/MulleVideo.h`; the umbrella header is mostly import/export scaffolding here.
- Prefer `demo/src/main-write-movie.m` and `demo/src/main-write-movie2.m` over `demo/README.md` for frame counts, callback wiring, and shutdown order. The README is only a sketch.
