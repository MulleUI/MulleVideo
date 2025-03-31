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
# define RECORD_FRAMECOUNT  20
#endif

/*
 * @name Star
 * @description The star() function created for this example is capable of
 * drawing a wide range of different forms. Try placing different numbers
 * into the star() function calls within draw() to explore.
 */

static void   starPath( NVGcontext *vg, CGFloat x, CGFloat y,
                                        CGFloat radius1, CGFloat radius2,
                                        NSUInteger npoints)
{
   CGFloat   a;
   CGFloat   angle;
   CGFloat   halfAngle;
   CGFloat   sx;
   CGFloat   sy;

   halfAngle = M_PI / npoints;
   angle     = halfAngle * 2.0f;

   nvgBeginPath( vg);
   for( a = 0; a < M_PI * 2.0f; a += angle)
   {
      sx = x + cosf( a) * radius2;
      sy = y + sinf( a) * radius2;

      if( a == 0.0)
         nvgMoveTo( vg, sx, sy);
      else
         nvgLineTo( vg, sx, sy);

      sx = x + cosf(a + halfAngle) * radius1;
      sy = y + sinf(a + halfAngle) * radius1;
      nvgLineTo( vg, sx, sy);
  }
  nvgClosePath( vg);
}

// the three pronged star, we need only a rotation
// of PI * 2 / 3, as then it will look the same

static CGFloat  rotation( NSUInteger frameCount, CGFloat divisor)
{
   CGFloat   value;
          // 1. rotation with 1 s
   value   = (M_PI * 2) * frameCount / 60.0;
          // only need 1/3 rotation though
   value  /= 3.0;
          // speed it up so third rotation is in RECORD_FRAMECOUNT
   value *= 60.0 / RECORD_FRAMECOUNT;
          // speed it up / down / reverse according to divisor
          // divisor is in frameRate and 200.0 is the speed of tri-star
   value *= (divisor / 200.0);

   return( value);
}


static void   draw( CALayer *layer, CGContext *context)
{
   CGRect       canvas;
   NSUInteger   frameCount;
   NVGcontext   *vg;

   vg         = CGContextGetNVGContext( context);
   canvas     = [layer canvas];
   frameCount = [context numberOfFrames];
   nvgSave( vg);
   {
      nvgTranslate( vg, canvas.size.width * 0.2, canvas.size.height * 0.5);
      nvgRotate( vg, rotation( frameCount, 200.0));
      starPath( vg, 0, 0, 5, 70, 3);
      nvgStrokeColor( vg, CGColorMakeWithGrayByte( 0));
      nvgStroke( vg);
      nvgFillColor( vg, CGColorMakeWithGrayByte( 160));
      nvgFill( vg);
   }
   nvgRestore( vg);

   nvgSave( vg);
   {
      nvgTranslate( vg, canvas.size.width * 0.5, canvas.size.height * 0.5);
      nvgRotate( vg, rotation( frameCount, 50.0));
      starPath( vg, 0, 0, 80, 100, 40);
      nvgStrokeColor( vg, CGColorMakeWithGrayByte( 0));
      nvgStroke( vg);
      nvgFillColor( vg, CGColorMakeWithGrayByte( 160));
      nvgFill( vg);
   }
   nvgRestore( vg);

   nvgSave( vg);
   {
      nvgTranslate( vg, canvas.size.width * 0.8, canvas.size.height * 0.5);
      nvgRotate( vg, rotation( frameCount, -200.0 * 3 / 5));
      starPath( vg, 0, 0, 30, 70, 5);
      nvgStrokeColor( vg, CGColorMakeWithGrayByte( 0));
      nvgStroke( vg);
      nvgFillColor( vg, CGColorMakeWithGrayByte( 160));
      nvgFill( vg);
   }
   nvgRestore( vg);
}


static void  didDraw( UIWindow *window,
                      id <UIGraphicsContext> context,
                      struct CGFrameInfo *info)
{
   UIAVIMovieWriter       *avi;
   struct CGBitmap        screenshotBitmap;
   NSUInteger             frameCount;
   NSInvocation           *invocation;
   MulleInvocationQueue   *queue;
   NSUInteger             configuration;

   avi        = [window userInfo];
   frameCount = [(CGContext *) context numberOfFrames];

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

   invocation = [NSInvocation mulleInvocationWithTarget:avi
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
   [window setDrawCallback:(CGGraphicsLayerDrawCallback_t *) draw];
   [window setFrameRateHz:60.0];

   avi = [UIAVIMovieWriter movieWithUTF8String:"animated.avi"
                                    bitmapSize:CGPixelSizeMake( 360, 200)
                                   frameRateHz:60.0
                                         codec:UIAVIMovieMJPGCodec];
   [window setUserInfo:avi];
   [window setDidDrawViewsCallback:didDraw];

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

