//
//  UIBitmapImage+JPGEncoder.m
//  MulleVideo
//
//  Copyright (c) 2022 Nat! - Mulle kybernetiK.
//  All rights reserved.
//
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//
//  Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation
//  and/or other materials provided with the distribution.
//
//  Neither the name of Mulle kybernetiK nor the names of its contributors
//  may be used to endorse or promote products derived from this software
//  without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
//  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
//
#import "UIBitmapImage+JPGEncoder.h"

#import "import-private.h"

#ifndef MULLE_BOOL_DEFINED
# error "you need to include <mulle-c11/mulle-c11-bool.h> before including <tiny-jpeg.h>"
#endif

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
