# MulleVideo Library Documentation for AI
<!-- Keywords: video, AVI, MJPEG, encoder, Objective-C, MulleUI -->

## 1. Introduction & Purpose

MulleVideo is an Objective-C library that provides video encoding capabilities for the MulleUI framework. Its primary function is to create AVI video files with MJPEG (Motion JPEG) compression from UIBitmapImage objects or raw bitmap data. The library wraps the libgwavi C library for AVI file generation and integrates the TinyJPEG encoder for JPEG frame compression, providing a high-level Objective-C interface for video creation.

Key features include:
- Simple API for creating AVI movies frame-by-frame
- MJPEG codec support with configurable quality
- Automatic bitmap format conversion and scaling
- Integration with MulleImage for seamless image handling
- Thread-safe movie writer class

MulleVideo is part of the MulleUI ecosystem and depends on MulleImage for bitmap image operations.

## 2. Key Concepts & Design Philosophy

MulleVideo follows the MulleUI design philosophy of providing simple, focused Objective-C wrappers around efficient C libraries. The core design principles are:

**Separation of Concerns:** The library is divided into clear functional areas:
- `UIAVIMovieWriter` handles AVI file creation and frame management
- `UIBitmapImage+JPGEncoder` category adds JPEG encoding to existing image objects
- `tiny-jpeg.h` provides the low-level JPEG compression

**Resource Management:** The library follows proper Objective-C memory management patterns with explicit lifecycle methods (`initWithFileUTF8String:...`, `close`, `finalize`). Bitmaps can be optionally freed after adding to the movie.

**Format Flexibility:** While the public interface works with high-level UIBitmapImage objects, the implementation allows for raw bitmap data with automatic format conversion.

**Streaming Architecture:** Frames are written incrementally to disk rather than buffered in memory, making it suitable for long video sequences.

**Category Extension Pattern:** JPEG encoding capability is added to UIBitmapImage via a category, maintaining separation between image representation and encoding functionality.

## 3. Core API & Data Structures

### 3.1. `UIAVIMovieWriter.h`

#### `@interface UIAVIMovieWriter : MulleObject <MulleObjCThreadSafe>`

**Purpose:** Main class for creating and writing AVI movie files with MJPEG compression.

**Key Fields:**
- `_gwavi`: Internal pointer to the libgwavi structure (private, do not access directly)

**Properties:**
- `@property(assign) CGPixelSize bitmapSize`: The dimensions of frames in the movie
- `@property(assign) NSUInteger codec`: The video codec to use (currently only `UIAVIMovieMJPGCodec` supported)
- `@property(assign) CGFloat frameRateHz`: Frame rate in frames per second

**Lifecycle Functions:**

```objc
+ (instancetype) movieWithFileUTF8String:(char *) filename
                              bitmapSize:(CGPixelSize) bitmapSize
                             frameRateHz:(CGFloat) hz
                                   codec:(NSUInteger) codec;
```
Convenience constructor that creates and autoreleases a movie writer.

```objc
- (instancetype) initWithFileUTF8String:(char *) filename
                             bitmapSize:(CGPixelSize) bitmapSize
                            frameRateHz:(CGFloat) hz
                                  codec:(NSUInteger) codec;
```
Designated initializer. Creates the AVI file at the specified path with the given parameters. Returns `nil` on failure.

```objc
- (BOOL) close;
```
Finalizes and closes the AVI file. Must be called before the object is deallocated. Returns `YES` on success.

**Core Operations:**

```objc
- (BOOL) addBitmapImage:(UIBitmapImage *) image;
```
Adds a frame to the movie from a UIBitmapImage. The image is automatically scaled and converted to the movie's bitmap format if necessary. JPEG compression is applied automatically. Returns `YES` on success.

```objc
- (BOOL) addBitmap:(struct CGBitmap) bitmap
      freeWhenDone:(BOOL) flag;
```
Adds a frame from raw bitmap data. If `flag` is `YES`, the bitmap data is freed after encoding. Returns `YES` on success.

**Constants:**

```objc
enum
{
   UIAVIMovieMJPGCodec = 0
};
```
Currently the only supported codec is MJPEG (value 0).

### 3.2. `MulleVideo.h` (Umbrella Header)

#### Macro
```c
#define MULLE_VIDEO_VERSION  ((0UL << 20) | (0 << 8) | 2)
```
Version identifier for compile-time API checks. Encoded as `(MAJOR << 20) | (MINOR << 8) | PATCH`.

### 3.3. `UIBitmapImage+JPGEncoder.h`

#### `@interface UIBitmapImage (JPGEncoder)`

**Purpose:** Category that adds JPEG encoding capabilities to UIBitmapImage objects.

**Core Operations:**

```objc
- (struct mulle_data) JPGCData;
```
Encodes the bitmap image to JPEG format with default quality (75%). Returns a `mulle_data` structure containing the JPEG bytes. The returned data must be freed by the caller using `mulle_free()`.

```objc
- (struct mulle_data) JPGCDataWithQuality:(CGFloat) quality
                                allocator:(struct mulle_allocator *) allocator;
```
Encodes the bitmap image to JPEG with specified quality and allocator. Quality ranges from 0-100 and is mapped to TinyJPEG quality levels (1-3). If `allocator` is `NULL`, uses the default allocator. Returns a `mulle_data` structure. The caller must free the returned data.

### 3.4. `tiny-jpeg.h` (Third-party Library)

#### Public C API

**Purpose:** Single-header JPEG encoder implementing baseline DCT JPEG compression. Used internally by MulleVideo but can be used directly if needed.

**Core Functions:**

```c
int tje_encode_to_file(const char* dest_path,
                       const int width,
                       const int height,
                       const int num_components,
                       const unsigned char* src_data);
```
Encodes bitmap data to a JPEG file. `num_components` must be 3 (RGB) or 4 (RGBA). Returns 1 on success, 0 on error.

```c
int tje_encode_to_file_at_quality(const char* dest_path,
                                  const int quality,
                                  const int width,
                                  const int height,
                                  const int num_components,
                                  const unsigned char* src_data);
```
Encodes with specified quality level (1-3, where 3 is highest quality).

```c
typedef void tje_write_func(void* context, void* data, int size);

int tje_encode_with_func(tje_write_func* func,
                         void* context,
                         const int quality,
                         const int width,
                         const int height,
                         const int num_components,
                         const unsigned char* src_data);
```
Encodes JPEG using a custom callback function for writing data. This allows encoding to memory or custom streams.

**Important Notes:**
- No dynamic allocations in the encoder
- Must define `TJE_IMPLEMENTATION` before including in exactly one C file
- Thread-safe with proper defaults

## 4. Performance Characteristics

**UIAVIMovieWriter:**
- **File I/O:** O(n) where n is the number of frames. Each frame is encoded and written sequentially.
- **Memory Usage:** Minimal - frames are not buffered in memory. Each frame is compressed and written immediately.
- **Thread Safety:** Marked as `MulleObjCThreadSafe`, but concurrent writes to the same movie instance should be serialized by the caller.
- **Scaling Performance:** If images need to be scaled to match `bitmapSize`, there is additional overhead proportional to the image size.

**JPEG Encoding:**
- **Compression:** O(w×h) where w and h are image dimensions. Uses fast DCT algorithm.
- **Quality Tradeoff:** Quality level 3 (highest) provides ~1/3 to 1/20 compression. Quality 2 is ~1/2 the size of quality 3. Quality 1 is ~1/6 the size of quality 3.
- **No Allocations:** The TinyJPEG encoder performs no dynamic allocations, making it predictable and fast.

**Thread Safety:**
- `UIAVIMovieWriter` is thread-safe at the object level but individual instances should not be written to concurrently.
- JPEG encoding is stateless and can be performed on multiple threads with different images.
- Demo code shows asynchronous frame writing using `MulleInvocationQueue` for parallel encoding.

## 5. AI Usage Recommendations & Patterns

### Best Practices

1. **Always close the movie:** Call `[movie close]` before releasing the UIAVIMovieWriter object. The `finalize` method will attempt to close, but explicit closing is cleaner.

2. **Match bitmap sizes:** For best performance, ensure source images match the `bitmapSize` specified when creating the movie. This avoids scaling overhead.

3. **Use appropriate quality:** Default quality (75/quality level 2-3) provides a good balance. Lower quality for larger videos or bandwidth-constrained scenarios.

4. **Handle failures gracefully:** Check return values from `initWithFileUTF8String:...`, `addBitmapImage:`, and `close`. These can fail due to I/O errors or resource constraints.

5. **Consider asynchronous encoding:** For real-time applications, encode frames on a background thread/queue as shown in the demo code to avoid blocking the render loop.

6. **Free bitmaps appropriately:** When using `addBitmap:freeWhenDone:`, pass `YES` only if the bitmap data is heap-allocated and no longer needed.

### Common Pitfalls

1. **Forgetting to close:** Not calling `close` before deallocation may result in corrupted AVI files.

2. **Incorrect frame rate:** The `frameRateHz` must match your actual frame generation rate for proper playback timing.

3. **Mismatched bitmap formats:** The encoder expects RGBA format. Other formats require conversion via MulleImage.

4. **File path issues:** Use UTF-8 C strings for file paths. Ensure the directory exists and is writable.

5. **Memory management:** The data returned by `JPGCData` and `JPGCDataWithQuality:allocator:` must be freed with `mulle_free()`.

### Idiomatic Usage

**MulleUI Pattern:** Use factory methods (`+movieWithFileUTF8String:...`) rather than manual alloc/init/autorelease sequences in application code.

**Resource Cleanup:** Utilize the `-finalize` override for cleanup, but don't rely on it exclusively - explicit cleanup is preferred.

**Error Handling:** Check for `nil` returns from initializers and `NO`/`0` returns from operations.

**Thread-Safe Encoding:** When encoding in real-time, use invocation queues to serialize writes while allowing the render thread to continue.

## 6. Integration Examples

### Example 1: Creating a Simple AVI Movie

```c
// Create a movie writer for a 640x480 video at 30 FPS
UIAVIMovieWriter   *movie;
CGPixelSize        size;
UIBitmapImage      *frame;
NSUInteger         i;

size  = CGPixelSizeMake( 640, 480);
movie = [UIAVIMovieWriter movieWithFileUTF8String:"output.avi"
                                       bitmapSize:size
                                      frameRateHz:30.0
                                            codec:UIAVIMovieMJPGCodec];
if( ! movie)
{
   fprintf( stderr, "Failed to create movie\n");
   return;
}

// Add 90 frames (3 seconds at 30 FPS)
for( i = 0; i < 90; i++)
{
   // Create or obtain your bitmap image
   frame = ... // generate frame content
   
   if( ! [movie addBitmapImage:frame])
   {
      fprintf( stderr, "Failed to add frame %lu\n", (unsigned long) i);
      break;
   }
}

// Important: close the movie
if( ! [movie close])
   fprintf( stderr, "Failed to close movie\n");
```

### Example 2: Using Raw Bitmap Data

```c
// Create movie from raw bitmap frames
UIAVIMovieWriter      *movie;
struct CGBitmap       bitmap;
struct CGBitmapInfo   info;
void                  *pixels;
NSUInteger            frameCount;

movie = [UIAVIMovieWriter movieWithFileUTF8String:"raw.avi"
                                       bitmapSize:CGPixelSizeMake( 320, 240)
                                      frameRateHz:24.0
                                            codec:UIAVIMovieMJPGCodec];

for( frameCount = 0; frameCount < 120; frameCount++)
{
   // Allocate and fill bitmap data (RGBA format)
   info   = CGBitmapInfoMake( CGPixelSizeMake( 320, 240),
                              320 * 4,
                              CGBitmapEncodingRGBABytes);
   pixels = malloc( 320 * 240 * 4);
   
   // ... fill pixels with frame data ...
   
   bitmap = CGBitmapMake( pixels, info);
   
   // Add frame and let the movie writer free the pixels
   [movie addBitmap:bitmap
       freeWhenDone:YES];
}

[movie close];
```

### Example 3: Custom JPEG Encoding Quality

```c
// Encode a bitmap image to JPEG with custom quality
UIBitmapImage      *image;
struct mulle_data   jpegData;
FILE               *file;

image = ... // your image

// Encode with high quality (90 out of 100)
jpegData = [image JPGCDataWithQuality:90.0
                            allocator:NULL];

if( mulle_data_is_valid( jpegData))
{
   // Write to file
   file = fopen( "output.jpg", "wb");
   if( file)
   {
      fwrite( jpegData.bytes, 1, jpegData.length, file);
      fclose( file);
   }
   
   // Must free the returned data
   mulle_free( jpegData.bytes);
}
```

### Example 4: Asynchronous Frame Writing (Production Pattern)

```c
// Real-time video recording with async encoding
static void   didRenderFrame( UIWindow *window,
                               id <UIGraphicsContext> context,
                               struct CGFrameInfo *info)
{
   UIAVIMovieWriter        *movie;
   struct CGBitmap         screenshot;
   MulleInvocationQueue    *queue;
   NSInvocation            *invocation;
   NSUInteger              configuration;
   
   movie = [window userInfo];
   
   // Get or create background queue for encoding
   queue = [window invocationQueueForNameUTF8String:"video-encoder"];
   if( ! queue)
   {
      configuration = MulleInvocationQueueCatchesExceptions
                      | MulleInvocationQueueTerminateWaitsForCompletion;
      queue         = [MulleInvocationQueue invocationQueueWithCapacity:0
                                                          configuration:configuration];
      [window setInvocationQueue:queue
               forNameUTF8String:"video-encoder"];
      [queue start];
   }
   
   // Capture the rendered frame
   screenshot = [(CGContext *) context framebufferBitmap];
   
   // Queue frame encoding on background thread
   invocation = [NSInvocation mulleInvocationWithTarget:movie
                                               selector:@selector( addBitmap:freeWhenDone:),
                                                        screenshot,
                                                        YES];
   [queue addInvocation:invocation];
}

int   main( int argc, char *argv[])
{
   UIWindow           *window;
   UIAVIMovieWriter   *movie;
   
   window = [UIWindow windowWithFrame:CGRectMake( 0.0, 0.0, 1280.0, 720.0)
                      titleUTF8String:"Recording"
                            styleMask:UIWindowStyleMaskDefault];
   
   movie = [UIAVIMovieWriter movieWithFileUTF8String:"recording.avi"
                                          bitmapSize:CGPixelSizeMake( 1280, 720)
                                         frameRateHz:60.0
                                               codec:UIAVIMovieMJPGCodec];
   
   [window setUserInfo:movie];
   [window setDidRenderLayersCallback:didRenderFrame];
   [window setFrameRateHz:60.0];
   
   return( [UIApp runWindow:window]);
}
```

### Example 5: Encoding Without a Window (Batch Processing)

```c
// Generate video from existing images or procedural content
static void   renderFrame( CGContext *context,
                            struct CGFrameInfo *info,
                            NSUInteger frameNumber)
{
   CGRect       canvas;

   canvas = CGFrameInfoGetContentRect( info);

   // Use CGContext drawing APIs to render frame content
   // ... custom drawing code based on frameNumber ...
}

int   main( int argc, char *argv[])
{
   UIWindow                  *window;
   UIAVIMovieWriter          *movie;
   id <UIGraphicsContext>    graphicsContext;
   struct CGFrameInfo        frameInfo;
   struct CGBitmap           screenshot;
   NSUInteger                frame;
   NSUInteger                styleMask;
   
   // Create hidden window for offscreen rendering
   styleMask = UIWindowStyleMaskDefault;
   styleMask = UIWindowStyleMaskBySetting( styleMask,
                                            UIWindowStyleHidden,
                                            YES);
   
   window = [UIWindow windowWithFrame:CGRectMake( 0.0, 0.0, 1920.0, 1080.0)
                      titleUTF8String:"Renderer"
                            styleMask:styleMask];
   
   movie = [UIAVIMovieWriter movieWithFileUTF8String:"output.avi"
                                          bitmapSize:CGPixelSizeMake( 1920, 1080)
                                         frameRateHz:24.0
                                               codec:UIAVIMovieMJPGCodec];
   
   [window activateRenderGraphicsContext];
   graphicsContext = [window renderGraphicsContext];
   [window getFrameInfo:&frameInfo];
   
   // Render and capture frames
   for( frame = 0; frame < 240; frame++)  // 10 seconds at 24 FPS
   {
      [(CGContext *) graphicsContext beginRender:&frameInfo];
      {
         [(CGContext *) graphicsContext clearFramebuffer];
         
         renderFrame( (CGContext *) graphicsContext, &frameInfo, frame);
         
         [(CGContext *) graphicsContext flushRender];
         screenshot = [(CGContext *) graphicsContext framebufferBitmap];
      }
      [(CGContext *) graphicsContext endRender];
      
      [movie addBitmap:screenshot
          freeWhenDone:YES];
   }
   
   [window deactivateRenderGraphicsContext];
   [movie close];
   
   return( 0);
}
```

## 7. Dependencies

MulleVideo has the following direct mulle-sde dependencies:

- **libgwavi** - C library for AVI file generation (external dependency)
- **MulleImage** - Bitmap image manipulation and format conversion
- **mulle-objc-list** - Core Objective-C runtime support (build-only dependency)

Additionally, it includes:

- **tiny-jpeg.h** - Single-header JPEG encoder (vendored as `src/tiny-jpeg.h`)

The library is part of the MulleUI ecosystem and integrates with:
- MulleImage for bitmap operations
- MulleUI/UIKit for graphics context and windowing (used in demos)
- mulle-core infrastructure (allocators, data structures)
