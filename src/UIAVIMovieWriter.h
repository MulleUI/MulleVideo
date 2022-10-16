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
// prefer a local UIBitmapImage over one in import.h
#ifdef __has_include
# if __has_include( "UIBitmapImage.h")
#  import "UIBitmapImage.h"
# endif
#endif

// we want "import.h" always anyway
#import "import.h"

#include <stdio.h>
#include <stdint.h>


@interface UIAVIMovieWriter : NSObject
{
   struct gwavi_t   *_gwavi;
}

enum
{
   UIAVIMovieMJPGCodec = 0
};

@property( assign) struct MulleIntegerSize    bitmapSize;
@property( assign) NSUInteger                 codec;
@property( assign) CGFloat                    frameRateHz;

+ (instancetype) movieWithUTF8String:(char *) filename
                          bitmapSize:(struct MulleIntegerSize) bitmapSize
                         frameRateHz:(CGFloat) hz
                               codec:(NSUInteger) codec;

- (instancetype) initWithUTF8String:(char *) filename
                         bitmapSize:(struct MulleIntegerSize) bitmapSize
                         frameRateHz:(CGFloat) hz
                              codec:(NSUInteger) codec;
- (BOOL) close;

- (BOOL) addBitmap:(struct CGBitmap) bitmap
      freeWhenDone:(BOOL) flag;

- (BOOL) addBitmapImage:(UIBitmapImage *) image;

@end

