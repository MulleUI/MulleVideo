//
// Copyright (c) 2020 Nat!, Mulle kybernetiK
//
#ifdef __has_include
# if __has_include( "UIBitmapImage.h")
#  import "UIBitmapImage.h"
# endif
#endif

// we want "import.h" always anyway
#import "import.h"


@interface UIBitmapImage ( JPGEncoder)

- (struct mulle_data) JPGCData;

// the returned data must be freed
- (struct mulle_data) JPGCDataWithQuality:(CGFloat) quality
                                allocator:(struct mulle_allocator *) allocator;

@end

