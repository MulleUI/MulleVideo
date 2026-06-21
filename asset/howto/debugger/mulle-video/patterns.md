<!-- keywords: mulle-video, debugger, patterns, uiavimoviewriter, jpgencoder -->
# Patterns

## Localize startup failures in `UIAVIMovieWriter`

`src/UIAVIMovieWriter.m` keeps init simple: validate input, build the fourcc, then call `gwavi_open`.

```objc
assert( frameRateHz > 0.0);
assert( bitmapSize.width >= 1.0);
assert( bitmapSize.height >= 1.0);

gwavi = gwavi_open( (const char *) filename,
                    bitmapSize.width,
                    bitmapSize.height,
                    fourcc,
                    (unsigned int) round( frameRateHz),
                    NULL);
```

- If init returns `nil`, inspect `filename` and file creation first; the only post-assert failure in this method is `gwavi_open`.
- If timing looks wrong, remember that the writer rounds `frameRateHz` before it reaches libgwavi.
- If a custom codec is involved, debug the fourcc conversion before blaming JPEG encoding.

## Split frame-write failures at the JPEG boundary

`addBitmapImage:` is the main fork between image conversion problems and AVI write problems.

```objc
scaled  = [image bitmapImageForBitmapInfo:aviInfo
                                allocator:NULL];

data = [scaled JPGCData];
if( data.length)
{
   rval = gwavi_add_frame( _gwavi, data.bytes, data.length);
   mulle_free( data.bytes);
}
```

- If `data.length` is `0`, move straight to `src/UIBitmapImage+JPGEncoder.m`; the failure happened before libgwavi saw the frame.
- If `data.length` is nonzero but the AVI is still bad, stay in the writer path and inspect `gwavi_add_frame` / `close`.
- This path always normalizes frames to the writer's RGBA `bitmapInfo`, so size mismatches show up as conversion work, not as a separate raw-bitmap code path.

## Reproduce ordering bugs with the queued demo

`demo/src/main-write-movie2.m` is the local pattern for callback-driven recording.

```objc
queue = [window invocationQueueForNameUTF8String:"avi"];
if( ! queue)
{
   queue = [MulleInvocationQueue invocationQueueWithCapacity:0
                                               configuration:configuration];
   [window setInvocationQueue:queue
            forNameUTF8String:"avi"];
   [queue start];
}

[queue addInvocation:invocation];
[queue addFinalInvocation:[NSInvocation mulleInvocationWithTarget:avi
                                                         selector:@selector( close)]];
```

- Use this source when a bug only appears during `didRenderLayers`.
- Keep one queue per writer, as the demo does; this repo does not show ad-hoc concurrent writes to one `UIAVIMovieWriter`.
- Compare the callback's `frameCount == RECORD_FRAMECOUNT` shutdown branch with the failing run when you suspect a lost last frame.

## Isolate JPEG-only failures below the writer

`src/UIBitmapImage+JPGEncoder.m` is small enough that you can debug the whole path in one pass.

```objc
bytes = [self bytes];
if( ! bytes)
   return( mulle_data_make_invalid());

quality = CGFloatProjectClamped( quality, 0, 100, 1, 3);
if( ! tje_encode_with_func( my_tje_write_func,
                            &buffer,
                            (int) quality + 0.5,
                            bitmapInfo.size.width,
                            bitmapInfo.size.height,
                            4,
                            bytes))
   return( mulle_data_make_invalid());
```

- If `[self bytes]` is `NULL`, stop there; this category does not synthesize bitmap storage for you.
- Quality bugs are coarse in this repo: `0..100` is projected onto TinyJPEG levels `1..3`.
- The category always calls TinyJPEG with `4` components, so debug RGBA-compatible image bytes first.
