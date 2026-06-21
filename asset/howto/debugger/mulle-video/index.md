<!-- keywords: mulle-video, debugger, uiavimoviewriter, jpgencoder, avi, mjpeg -->
# mulle-video

Use this bundle when the repo's video path fails at movie creation, frame writing, JPEG encoding, or queued shutdown. The local split is: `UIAVIMovieWriter` for AVI output, `UIBitmapImage (JPGEncoder)` for JPEG bytes, and `tiny-jpeg.h` only when the failure is below the Objective-C wrapper.

## Understand first

```bash
mulle-sde api apropos UIAVIMovieWriter
mulle-sde api cat UIAVIMovieWriter
mulle-sde api apropos JPGCData
mulle-sde code search "gwavi_add_frame"
mulle-sde code search "MulleInvocationQueue"
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

## Main failure surfaces

| Symptom | Start here | Local clue |
| --- | --- | --- |
| Writer creation returns `nil` | `src/UIAVIMovieWriter.m` | `filename` must be non-`NULL`; width, height, and FPS are asserted positive before `gwavi_open`. |
| Frames are skipped or the AVI is empty/corrupt | `src/UIAVIMovieWriter.m` | `addBitmapImage:` scales to RGBA, calls `JPGCData`, then hands the bytes to `gwavi_add_frame`; `close` is explicit in both demos. |
| JPEG export returns invalid data | `src/UIBitmapImage+JPGEncoder.m` | `[self bytes] == NULL` or a TinyJPEG failure yields `mulle_data_make_invalid()`. |
| Live capture loses the tail frame or closes too early | `demo/src/main-write-movie2.m` | The callback path uses one `"avi"` queue and schedules `close` as a final invocation before termination. |

## Local workflow

- Treat `src/reflect/_MulleVideo-export.h` as the exported-family inventory. The umbrella header in `src/MulleVideo.h` is mostly scaffolding.
- Debug the synchronous demo first. `demo/src/main-write-movie.m` is the shortest end-to-end path from framebuffer to `.avi`.
- Only switch to `demo/src/main-write-movie2.m` when the bug depends on callback timing, queue ordering, or shutdown.
- Keep the writer and encoder paths separate while debugging: the writer is an AVI wrapper around JPEG frames; the category is the standalone JPEG escape hatch.
- There are no repo tests for this surface in the current tree, so report against the exact source or demo path that reproduced the failure.

## Verify and report

- Say which stage failed: writer init, `addBitmapImage:`, `JPGCDataWithQuality:allocator:`, or `close`.
- Note whether the failure reproduced in `demo/src/main-write-movie.m`, `demo/src/main-write-movie2.m`, or both.
- If the symptom is data-dependent, include the observed bitmap size, frame rate, and whether the source bytes were already valid RGBA.
