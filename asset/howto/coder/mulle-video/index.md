<!-- keywords: mulle-video, uiavimoviewriter, uibitmapimage, jpgencoder, mjpeg, avi -->
# mulle-video

Use this bundle when you touch the repo's exported video-writing surface. The useful local split is: `UIAVIMovieWriter` for AVI output, `UIBitmapImage (JPGEncoder)` for JPEG bytes, and `tiny-jpeg.h` only when you must bypass the Objective-C wrapper.

## Understand first

```bash
mulle-sde api list
mulle-sde code search UIAVIMovieWriter
mulle-sde code search JPGCDataWithQuality
mulle-sde code grep "addBitmap:freeWhenDone:"
mulle-sde code grep "TJE_IMPLEMENTATION"
```

## Local references

- `asset/dox/TOC.md`
- `src/MulleVideo.h`
- `src/reflect/_MulleVideo-export.h`
- `src/UIAVIMovieWriter.h`
- `src/UIAVIMovieWriter.m`
- `src/UIBitmapImage+JPGEncoder.h`
- `src/UIBitmapImage+JPGEncoder.m`
- `src/tiny-jpeg.h`
- `demo/README.md`
- `demo/src/main-write-movie.m`
- `demo/src/main-write-movie2.m`

## Main local surfaces

| Scenario | Start here | Local rule |
| --- | --- | --- |
| Write an `.avi` from rendered frames | `UIAVIMovieWriter` | Writer size and FPS are fixed up front; feed frames with `addBitmapImage:` or `addBitmap:freeWhenDone:` and close explicitly. |
| Record frames during a live render loop | `demo/src/main-write-movie2.m` | Queue `addBitmap:freeWhenDone:` onto one `MulleInvocationQueue`; do not write the same movie concurrently from ad-hoc callbacks. |
| Turn one `UIBitmapImage` into JPEG bytes | `UIBitmapImage+JPGEncoder` | Use `JPGCDataWithQuality:allocator:` and free the returned bytes yourself. |
| Bypass Objective-C and encode raw RGB/RGBA memory | `src/tiny-jpeg.h` | Supported qualities are only `1..3`; this repo already provides the one `TJE_IMPLEMENTATION` site. |

## Local workflow

- Treat `src/MulleVideo.h` as a thin umbrella. The actual exported headers are listed in `src/reflect/_MulleVideo-export.h`.
- Prefer the demo sources over the READMEs for real usage. `demo/src/main-write-movie.m` shows the synchronous offscreen loop; `demo/src/main-write-movie2.m` shows the queued render-callback variant.
- Keep the movie writer API and the JPEG category distinct: the writer always encodes frames as MJPEG internally, while the category is the public escape hatch for standalone JPEG data.
- There are no repo tests for this surface in the current tree, so verify and report against the cited demo and source paths instead of inventing test-only behavior.
