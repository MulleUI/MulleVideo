//
//  UIAVIMovieWriter.m
//  MulleUIVideo
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
#import "UIAVIMovieWriter.h"

#import "import-private.h"

#import "UIBitmapImage+JPGEncoder.h"


@implementation UIAVIMovieWriter

+ (instancetype) movieWithUTF8String:(char *) filename
                          bitmapSize:(struct MulleIntegerSize) bitmapSize
                         frameRateHz:(CGFloat) frameRateHz
                               codec:(NSUInteger) codec;
{
   return( [[[self alloc] initWithUTF8String:filename
                                  bitmapSize:bitmapSize
                                 frameRateHz:frameRateHz
                                       codec:codec] autorelease]);
}


- (instancetype) initWithUTF8String:(char *) filename
                         bitmapSize:(struct MulleIntegerSize) bitmapSize
                        frameRateHz:(CGFloat) frameRateHz
                              codec:(NSUInteger) codec
{
   struct gwavi_t  *gwavi;
   auto char       fourcc[ 5] = { 'M', 'J', 'P', 'G', 0 };

   if( ! filename)
   {
      [self release];
      return( nil);
   }

   assert( frameRateHz > 0.0);
   assert( bitmapSize.width >= 1.0);
   assert( bitmapSize.height >= 1.0);

   if( codec)
   {
#ifdef __LITTLE_ENDIAN__
      fourcc[ 0] = (codec >> 24) & 0xFF;
      fourcc[ 1] = (codec >> 16) & 0xFF;
      fourcc[ 2] = (codec >> 8) & 0xFF;
      fourcc[ 3] = codec & 0xFF;
#else
      fourcc[ 3] = (codec >> 24) & 0xFF;
      fourcc[ 2] = (codec >> 16) & 0xFF;
      fourcc[ 1] = (codec >> 8) & 0xFF;
      fourcc[ 0] = codec & 0xFF;
#endif
      fourcc[ 4] = 0;
   }

   // TODO: conceivably should convert to FileSystemRepresentation
   gwavi = gwavi_open( (const char *) filename,
                       bitmapSize.width,
                       bitmapSize.height,
                       fourcc,
                       (unsigned int) round( frameRateHz),
                       NULL);
   if( ! gwavi)
   {
      [self release];
      return( nil);
   }

   _gwavi       = gwavi;
   _bitmapSize  = bitmapSize;
   _frameRateHz = frameRateHz;
   _codec       = codec;

   return( self);
}


- (struct CGBitmapInfo) bitmapInfo
{
   return( CGBitmapInfoMake( _bitmapSize,
                             _bitmapSize.width * 4,
                             CGBitmapEncodingRGBABytes));
}


- (BOOL) close
{
   if( gwavi_close( _gwavi))
      return( NO);

   _gwavi = NULL;
   return( YES);
}


- (void) finalize
{
   [self close];
   [super finalize];
}


- (BOOL) addBitmapImage:(UIBitmapImage *) image
{
   struct CGBitmapInfo       aviInfo;
   BOOL                      rval = 0;
   UIBitmapImage             *scaled;
   struct mulle_data         data;

   aviInfo = [self bitmapInfo];
   // produce a scaled image in RGBA format if needed
   scaled  = [image bitmapImageForBitmapInfo:aviInfo
                                   allocator:NULL];

   data = [scaled JPGCData];
   if( data.length)
   {
      rval = gwavi_add_frame( _gwavi, data.bytes, data.length);
      mulle_free( data.bytes);
   }
   return( rval ? NO : YES);
}


- (BOOL) addBitmap:(struct CGBitmap) bitmap
      freeWhenDone:(BOOL) flag
{
   UIBitmapImage   *image;

   image = [UIBitmapImage imageWithBitmap:bitmap
                             freeWhenDone:flag];
   return( [self addBitmapImage:image]);
}

@end

