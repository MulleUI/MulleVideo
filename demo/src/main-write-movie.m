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


static void  writeFrames( id <UIGraphicsContext> graphicsContext, struct CGFrameInfo *info, UIAVIMovieWriter *avi)
{
   CGContext         *context = MULLE_OBJC_CLASS_CAST( CGContext, graphicsContext);
   struct CGBitmap   screenshotBitmap;
   NSUInteger        frameCount;
   NVGcontext        *vg;

   vg = CGContextGetNVGContext( context);

   for( frameCount = 0; frameCount < RECORD_FRAMECOUNT; frameCount++)
   {
      [context beginRender:info];
      {
         [context clearFramebuffer];
         drawStars( vg, CGFrameInfoGetContentRect( info), frameCount);

         [context flushRender];
         screenshotBitmap = [context framebufferBitmap];
      }
      [context endRender];
   
      MulleUICLog( "write %td", frameCount);
      [avi addBitmap:screenshotBitmap
        freeWhenDone:YES];
   }
   MulleUICLog( "close");
   [avi close];
}


int   main( int argc, char *argv[])
{
   UIWindow                *window;
   UIApplication           *app;
   UIAVIMovieWriter        *avi;
   NSUInteger              styleMask;
   id <UIGraphicsContext>  context;
   struct CGFrameInfo      info;

   app       = [UIApplication sharedInstance];
   styleMask = UIWindowStyleMaskDefault;
   styleMask = UIWindowStyleMaskBySetting( styleMask, UIWindowStyleRetained, NO);
   styleMask = UIWindowStyleMaskBySetting( styleMask, UIWindowStyleHidden, YES);
   window    = [UIWindow windowWithFrame:CGRectMake( 0.0, 0.0, 720.0, 400.0)
                         titleUTF8String:"Demo"
                               styleMask:styleMask];

   [window setBackgroundColor:CGColorMakeWithGrayByte( 102)];


   avi = [UIAVIMovieWriter movieWithFileUTF8String:"stars.avi"
                                        bitmapSize:CGPixelSizeMake( 360, 200)
                                       frameRateHz:60.0
                                             codec:UIAVIMovieMJPGCodec];

   [window activateRenderGraphicsContext];
   context = [window renderGraphicsContext];
   {
      [window getFrameInfo:&info];
      writeFrames( context, &info, avi);
   }
   [window deactivateRenderGraphicsContext];

   [app requestTerminate];
   return( 0);
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

