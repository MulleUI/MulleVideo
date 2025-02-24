//
// Copyright (c) 2022 Nat!, Mulle kybernetiK
//
#import "UIBitmapImage+JPGEncoder.h"

#import "import-private.h"

#define TJE_IMPLEMENTATION
#include "tiny-jpeg.h"


@implementation UIBitmapImage ( JPGEncoder)

static void  my_tje_write_func( void* context, void* data, int size)
{
   struct mulle_buffer   *buffer = context;

   mulle_buffer_add_bytes( buffer, data, size);
}


- (struct mulle_data) JPGCDataWithQuality:(CGFloat) quality
                                allocator:(struct mulle_allocator *) allocator
{
   NSUInteger            lineLength;
   struct mulle_buffer   buffer;
   struct CGBitmapInfo   bitmapInfo;
   void                  *bytes;
   struct mulle_data     data;

   bitmapInfo = [self bitmapInfo];
   bytes      = [self bytes];
   if( ! bytes)
      return( mulle_data_make_invalid());

   lineLength = CGBitmapInfoGetLineLength( bitmapInfo);
   quality    = CGFloatProjectClamped( quality, 0, 100, 1, 3);

   mulle_buffer_init( &buffer,
                      1024 + bitmapInfo.size.width * lineLength,
                      allocator);

   if( ! tje_encode_with_func( my_tje_write_func,
                               &buffer,
                              (int) quality + 0.5,
                              bitmapInfo.size.width,
                              bitmapInfo.size.height,
                              4,
                              bytes))
   {
      mulle_buffer_done( &buffer);
      return( mulle_data_make_invalid());
   }

   mulle_buffer_size_to_fit( &buffer);
   data = mulle_buffer_extract_data( &buffer);
   mulle_buffer_done( &buffer);

   return( data);
}


// the returned data is autoreleased!
- (struct mulle_data) JPGCData
{
   return( [self JPGCDataWithQuality:75.0
                           allocator:NULL]);
}

@end
