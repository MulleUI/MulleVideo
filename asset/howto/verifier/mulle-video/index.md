<!-- keywords: avi, mjpeg, jpgencoder, invocation-queue, runtime-trace -->
# mulle-video

Use this bundle when user code writes `.avi` files through `UIAVIMovieWriter` or calls the JPEG category directly. This repo does **not** expose MulleVideo-specific trace environment variables or debug-only helper classes; the local verifier value is the demo trace recipe, the queued writer demo, and a few non-obvious writer/encoder failure contracts.

## Understand first

```bash
mulle-sde api apropos UIAVIMovieWriter
mulle-sde api cat UIAVIMovieWriter
mulle-sde api apropos JPGCData
mulle-sde code search "MulleInvocationQueueTrace"
mulle-sde code search "MULLE_OBJC_TRACE_METHOD_CALL"
```

## Local references

- `asset/dox/TOC.md`
- `src/MulleVideo.h`
- `src/UIAVIMovieWriter.h`
- `src/UIBitmapImage+JPGEncoder.h`
- `src/tiny-jpeg.h`
- `demo/README.md`
- `demo/src/main-write-movie.m`
- `demo/src/main-write-movie2.m`

## Main diagnostic surfaces

| Symptom | Start here | Local clue |
| --- | --- | --- |
| Writer creation returns `nil` or aborts in a debug build | `UIAVIMovieWriter` | `initWithFileUTF8String:bitmapSize:frameRateHz:codec:` rejects `NULL` filenames and asserts positive width, height, and frame rate before `gwavi_open`. |
| Frames disappear even though `addBitmapImage:` looked successful | `UIBitmapImage (JPGEncoder)` first, then `UIAVIMovieWriter` | `JPGCDataWithQuality:allocator:` returns invalid data when `[self bytes]` is `NULL` or TinyJPEG encoding fails. `addBitmapImage:` only calls `gwavi_add_frame` when `data.length` is nonzero, so an empty JPEG path can leave the AVI empty without a `NO` return from the writer. |
| The queued callback path loses the tail frame or closes too early | `demo/src/main-write-movie2.m` | The demo uses one `"avi"` `MulleInvocationQueue`, adds `close` as a final invocation, and enables `MulleInvocationQueueTrace` in the queue configuration. |
| Standalone JPEG output looks wrong | `UIBitmapImage (JPGEncoder)` and `tiny-jpeg.h` | Quality `0..100` is clamped down to TinyJPEG levels `1..3`. The `fprintf( stderr, "Could not write JPEG\\n")` path in `tiny-jpeg.h` belongs to the file helper, not to `JPGCDataWithQuality:allocator:`. |

## Local workflow

- Reproduce first with `demo/src/main-write-movie.m`. It is the shortest framebuffer-to-AVI path and already logs `write %td` and `close`.
- Switch to `demo/src/main-write-movie2.m` only for timing or queue bugs. It uses the same movie API but adds `MulleInvocationQueueTrace` around the asynchronous write path.
- Reuse the demo runtime trace recipe when you need allocator or Objective-C call traces: `MULLE_OBJC_PEDANTIC_EXIT=YES`, `MULLE_TESTALLOCATOR=YES`, `MULLE_TESTALLOCATOR_TRACE=3`, `MULLE_OBJC_TRACE_INSTANCE=YES`, `MULLE_OBJC_TRACE_METHOD_CALL=YES`.
- If the movie writer appears healthy but the output is corrupt, call `JPGCDataWithQuality:allocator:` on the same `UIBitmapImage` outside the writer first. That isolates JPEG generation from AVI container writing.
- There are no repo tests for this surface in the current tree, so report against the exact demo or source path that reproduced the problem.

## Verify and report

- Say whether the failure reproduced in `demo/src/main-write-movie.m`, `demo/src/main-write-movie2.m`, or only in user code.
- Include bitmap size, frame rate, and whether the source bytes were already RGBA.
- Name the failing stage: writer init, JPEG encode, frame enqueue/write, or `close`.
- For queue bugs, note whether `MulleInvocationQueueTrace` showed `close` arriving after the last frame write.
