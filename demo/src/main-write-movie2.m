#define _GNU_SOURCE

#import "import.h"

#include <math.h>

//#define LEAK_CHECK
/*
   MULLE_OBJC_PEDANTIC_EXIT=YES MULLE_OBJC_EPHEMERAL_SINGLEON=YES \
   MULLE_TESTALLOCATOR=YES MULLE_TESTALLOCATOR_TRACE=3 \
   MULLE_OBJC_TRACE_INSTANCE=YES MULLE_OBJC_TRACE_METHOD_CALL=YES \
   ./kitchen/Debug/write-movie
*/

#define RECORD_AVI
#ifdef LEAK_CHECK
# define RECORD_FRAMECOUNT  1
#else
# define RECORD_FRAMECOUNT  120
#endif

#include "stars-draw.inc"
static BOOL   draw( CGGraphicsLayer *layer, CGContext *context)
{
   CGRect       canvas;
   NSUInteger   frameCount;

   canvas     = [layer canvas];
   frameCount = [context numberOfFrames];

   drawStars( context, canvas, frameCount);
   return( YES);
}
static void  didDraw( UIWindow *window,
                      id <UIGraphicsContext> graphicsContext,
                      struct CGFrameInfo *info)
{
   UIAVIMovieWriter       *avi;
   CGContext              *context = MULLE_OBJC_CLASS_CAST( CGContext, graphicsContext);
   struct CGBitmap        screenshotBitmap;
   NSUInteger             frameCount;
   NSInvocation           *invocation;
   MulleInvocationQueue   *queue;
   NSUInteger             configuration;

   avi        = [window userInfo];
   frameCount = [context numberOfFrames];

   queue = [window invocationQueueForNameUTF8String:"avi"];
   if( ! queue)
   {
      configuration = MulleInvocationQueueTrace
                      | MulleInvocationQueueCatchesExceptions
                      | MulleInvocationQueueTerminateWaitsForCompletion;
      queue = [MulleInvocationQueue invocationQueueWithCapacity:0
                                                  configuration:configuration];
      [window setInvocationQueue:queue
               forNameUTF8String:"avi"];
      [queue start];
   }

   if( frameCount == RECORD_FRAMECOUNT)
   {
      fprintf( stderr, "close\n");

      invocation = [NSInvocation mulleInvocationWithTarget:avi
                                                  selector:@selector( close)];
      [queue addFinalInvocation:invocation];
      [window setUserInfo:nil];

      [UIApp requestTerminate];
      return;
   }

   // can happen...
   if( frameCount > RECORD_FRAMECOUNT)
      return;

   screenshotBitmap = [context framebufferBitmap];

   invocation       = [NSInvocation mulleInvocationWithTarget:avi
                                                     selector:@selector( addBitmap:freeWhenDone:),
                                                              screenshotBitmap,
                                                              YES];
   [queue addInvocation:invocation];
   fprintf( stderr, "write %td\n", frameCount);
}
int   main( int argc, char *argv[])
{
   UIWindow           *window;
   UIApplication      *app;
   UIAVIMovieWriter   *avi;

   app    = [UIApplication sharedInstance];
   window = [UIWindow windowWithFrame:CGRectMake( 0.0, 0.0, 720.0, 400.0)
                      titleUTF8String:"Demo"
                            styleMask:UIWindowStyleMaskDefault];

   [window setBackgroundColor:CGColorMakeWithGrayByte( 102)];
   [window setDrawCallback:draw];
   [window setFrameRateHz:60.0];

   avi = [UIAVIMovieWriter movieWithFileUTF8String:"animated.avi"
                                        bitmapSize:CGPixelSizeMake( 360, 200)
                                       frameRateHz:60.0
                                             codec:UIAVIMovieMJPGCodec];
   [window setUserInfo:avi];
   [window setDidRenderLayersCallback:didDraw];

   return( [app runWindow:window]);
}

//
//                           ,╓≤æKª╨╙╙▓█D"╙╙╙*╨¥W▄╓,
//                      ╓▄ª╙└╧▓        █           ⁿ▓▓ª╦w
//                  ╓#╜^*█⌐   `╕       █           ╓▌    `╙%w
//               ╓ΦΓ      █    ╙⌐     ,█,,,Φ      ╓▌         ╙¥▄
//            ,▄▀ █▄       █µ,╓╝,╓≤╗≡≡ª╨╨╨¥≡∞╗w╓,ª█,  ,       ]▄▀V,
//          ,Φ└   ║"▀▄     ,▄▀╨"                 "╙¥▓▓       ▄▀  º▄¥,
//        ,#▌Φ▓▄╓  Φ `█Q▄M╙                           ╙¥▄ ,▄▀ ╙▄⌐`  `Φ
//       ▄▀   `V,"▀▀¼╓╩└                                 ╙¥▓╗ ,       ╙▄
//      Φ       `¥═▄▀                            ╒          ▀▄          ▓
//    .▓         ╓▓]V▄H       ▓                 ,Å            ▀,         ▀
//    █      ,-ª▓╛  `██▀½      "▄  ,╓╓╓╓;╓▄▄▄▄╗▄█,             ╙▄         ▀
//   █  `██▄   ▓. - Φ█═.~     ,≤█▄▀-      `   █└"▀▀▀▀▄╓╓╓╓       ▌    ██▄, █
//  ║⌐  " ▀   ▓╨⌐   }▀`      ,█  `           █      .█▀▄▄███▄     ▌  ` ▀    ▌
//  ▌        ▐M A   '┴      ▌                ▀        ╙█▌████▌    ╙▄        ║⌐
// ║⌐        █⌐'║▄ Γr2«    ║▀                 ▄▄▄      ╙▌▄███      █         ▌
// █]     ,▄▐H  ██████═ª  ╓` ▄█▀▀▀▀█▄        ████     ╓███` `╙╙║█  ▐H        █
// █ "% ,▄▀ ║░╠K█═╣███^   ╛╓█▀      ▐█         ,╓╓═ª╙└   █      ╙█▄▐▌▓######▌╫
// █║▄▄▄█▄▄▄║H:  "╙▀███▄╓▄,█▌╓▄,,▄∩  ██p$ΦΦ▀▀▀▀▀ΦΦΦR≡≥▄╓ ║▄   ╙j▌` ▄▀╙╗ `╫
// █"      ╙▐H-═M ▄███████¥█H "^╙    '█, ,«^``     `     ║▌        ▐M▄▀    "Φ█
// ║        !█▄▄████≤═^`╓█ █▌╓▀╦▄▀█   ╙█⌐               ╓█▌        ▓ `       █
//  ▌      ,▄██╫██ ▄█═╜" █▌▐█╣Hj⌐ █    █▌╙¥w,           ██▄       ╓▌        ▐M
//  ╢"▄▄#▀▀╙╟█Ü███▀`▀█  ║██J█▄▌jH █    ██    ╙▀W▄;    ,██  `╙w,   █▄     ,╓ █
//   █╙     ▐███▌▀█w ▀█ ╠██████j▌║█▌   ▀██▄       `╙▓██▀w,     ╙╗█'`"▀█▀╙"`║`
//   ╙▌     Φ████████▄██ ███████████    ═██▀W▄,   ╓█▀└         ╓▀ "    ╙▄ ╓▀
//    ╙▄     ╙▀███╙█▄▐██▄,╙▀█████▄▀▄▀▄   ,█M╗ ▀▄██▀╙""*ⁿ═─≈-,,▄▌,        ▄▀
//     `▌╙µ,▄Φ▀x███▄██████████▀V███▀╙└ ,▄#▌████▀`"*«,      .█▀▄▀▄,      ▄╛
//       ▀Ö█  ;▓████████▄▄█▀▄╙W "V▄██▀▀│▄███▀└ ▀╦     "*═╥▄▀ ║,  ║▀▄  ,▓
//        ╙W▀ '█████╨▀▀█████████   "▀▀████└      ╙▄   ,▄▀'   `▀▀╣H ▐▀▄▀
//          ╙▄  ▀▀Γ╓▌  ▄▀ⁿ`╙▀███      ██▌         ╓█R▀▄A█        ▀▀▄▀
//            ╙W,Φ╙  ║█        ▄╙╙ª%≡╦██≤≤╗╗≡≡╜▀▀   ╣▌   █╕     ,▄▀
//              `▀▄M█┘        ║▀▌   ╫"    *Φ▄  █       Φ` ▀▌, ▄M╙
//                 "▀╦,       M ╙▌  ▀       `█W▐▌       wæQ▄▀╙
//                     ╙▀W╥,╓╣   ╙█║        ╫M  █    ,╓▄╝╙`
//                          ╙╙▀%▄▄▄▌,≤▄_▄≡,▐▓▓▄▄#ª▀"`

