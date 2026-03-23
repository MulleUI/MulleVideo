/*
 * @name Star
 * @description The star() function created for this example is capable of
 * drawing a wide range of different forms. Try placing different numbers
 * into the star() function calls within draw() to explore.
 */

static void   starPath( CGContext *context, CGFloat x, CGFloat y,
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

   CGContextBeginPath( context);
   for( a = 0; a < M_PI * 2.0f; a += angle)
   {
      sx = x + cosf( a) * radius2;
      sy = y + sinf( a) * radius2;

      if( a == 0.0)
         CGContextMoveTo( context, CGPointMake( sx, sy));
      else
         CGContextLineTo( context, CGPointMake( sx, sy));

      sx = x + cosf(a + halfAngle) * radius1;
      sy = y + sinf(a + halfAngle) * radius1;
      CGContextLineTo( context, CGPointMake( sx, sy));
  }
  CGContextClosePath( context);
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


static void   drawStars( CGContext *context, CGRect canvas, NSUInteger frameCount)
{
   CGContextSave( context);
   {
      CGContextTranslate( context, CGPointMake( canvas.size.width * 0.2, canvas.size.height * 0.5));
      CGContextRotate( context, rotation( frameCount, 200.0));
      starPath( context, 0, 0, 5, 70, 3);
      CGContextStrokeColor( context, CGColorMakeWithGrayByte( 0));
      CGContextStroke( context);
      CGContextFillColor( context, CGColorMakeWithGrayByte( 160));
      CGContextFill( context);
   }
   CGContextRestore( context);

   CGContextSave( context);
   {
      CGContextTranslate( context, CGPointMake( canvas.size.width * 0.5, canvas.size.height * 0.5));
      CGContextRotate( context, rotation( frameCount, 50.0));
      starPath( context, 0, 0, 80, 100, 40);
      CGContextStrokeColor( context, CGColorMakeWithGrayByte( 0));
      CGContextStroke( context);
      CGContextFillColor( context, CGColorMakeWithGrayByte( 160));
      CGContextFill( context);
   }
   CGContextRestore( context);

   CGContextSave( context);
   {
      CGContextTranslate( context, CGPointMake( canvas.size.width * 0.8, canvas.size.height * 0.5));
      CGContextRotate( context, rotation( frameCount, -200.0 * 3 / 5));
      starPath( context, 0, 0, 30, 70, 5);
      CGContextStrokeColor( context, CGColorMakeWithGrayByte( 0));
      CGContextStroke( context);
      CGContextFillColor( context, CGColorMakeWithGrayByte( 160));
      CGContextFill( context);
   }
   CGContextRestore( context);
}

