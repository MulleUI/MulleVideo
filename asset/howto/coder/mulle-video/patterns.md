<!-- keywords: mulle-video, patterns, uiavimoviewriter, uibitmapimage, tiny-jpeg -->
# Patterns

## Write an AVI from an offscreen render loop

`demo/src/main-write-movie.m` is the clearest batch pattern: render, grab the framebuffer bitmap, hand ownership to the writer, then close.

```objc
avi = [UIAVIMovieWriter movieWithFileUTF8String:"stars.avi"
                                     bitmapSize:CGPixelSizeMake( 360, 200)
                                    frameRateHz:60.0
                                          codec:UIAVIMovieMJPGCodec];

[window activateRenderGraphicsContext];
context = [window renderGraphicsContext];
[window getFrameInfo:&info];

[context beginRender:&info];
{
   [context clearFramebuffer];
   [context flushRender];
   screenshotBitmap = [context framebufferBitmap];
}
[context endRender];

[avi addBitmap:screenshotBitmap
  freeWhenDone:YES];
[avi close];
```

- The demo renders into a `720x400` hidden window but writes `360x200` AVI frames. Resizing is handled by `addBitmapImage:` through `bitmapImageForBitmapInfo:allocator:`.
- `freeWhenDone:YES` is the happy path for framebuffers you no longer need after handing them to the writer.

## Record from `didRenderLayers` via one queue

`demo/src/main-write-movie2.m` shows the live-recording shape: capture the framebuffer inside the render callback, but queue the encode/write work onto one named `MulleInvocationQueue`.

```objc
queue = [window invocationQueueForNameUTF8String:"avi"];
if( ! queue)
{
   queue = [MulleInvocationQueue invocationQueueWithCapacity:0
                                               configuration:MulleInvocationQueueTrace
                                                            | MulleInvocationQueueCatchesExceptions
                                                            | MulleInvocationQueueTerminateWaitsForCompletion];
   [window setInvocationQueue:queue
            forNameUTF8String:"avi"];
   [queue start];
}

screenshotBitmap = [context framebufferBitmap];
invocation = [NSInvocation mulleInvocationWithTarget:avi
                                            selector:@selector( addBitmap:freeWhenDone:),
                                                     screenshotBitmap,
                                                     YES];
[queue addInvocation:invocation];
```

- Use one queue per writer.
- Queue a final `close` invocation before terminating, as the demo does when it reaches the last frame.

## Export JPEG bytes from `UIBitmapImage`

`src/UIBitmapImage+JPGEncoder.m` is the public image-side pattern when you want JPEG data without AVI writing.

```objc
data = [image JPGCDataWithQuality:90.0
                        allocator:NULL];
if( data.length)
{
   fwrite( data.bytes, 1, data.length, fp);
   mulle_free( data.bytes);
}
```

- Treat both `JPGCData` and `JPGCDataWithQuality:allocator:` as returning caller-owned bytes.
- Use this when you already have a `UIBitmapImage`; do not reimplement the TinyJPEG callback path unless you need pure C integration.

## Drop to `tiny-jpeg.h` only for raw C buffers

The vendored encoder is the fallback when your input is already RGB/RGBA memory and you do not want `UIBitmapImage`.

```c
if( ! tje_encode_to_file_at_quality( "frame.jpg",
                                     3,
                                     width,
                                     height,
                                     4,
                                     pixels))
   fprintf( stderr, "JPEG encode failed\n");
```

- Keep `num_components` at `3` or `4`; the encoder rejects anything else.
- In this repo, `TJE_IMPLEMENTATION` already lives in `src/UIBitmapImage+JPGEncoder.m`, so consumers should call the API, not redeclare the implementation block.
