//
//  StavesView.m
//  Dyadminoes
//
//  Created by Bennett Lin on 7/23/14.
//  Copyright (c) 2014 Bennett Lin. All rights reserved.
//

#import "StavesView.h"
#import "Constants.h"
#import "TouchSubview.h"

#define kHeightWholeStep

@implementation StavesView

-(id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    self.backgroundColor = kBackgroundYellow;
    self.layer.cornerRadius = kStaveHeight;
    self.layer.masksToBounds = YES;
  }
  return self;
}

-(void)drawRect:(CGRect)rect {
  
  [super drawRect:rect];
  CGFloat lineDensity = kStaveLineDensity;
  
  CGContextRef context = UIGraphicsGetCurrentContext();
  for (int i = 0; i < 5; i++) {
    CGContextSetStrokeColorWithColor(context, [kStaveColour colorWithAlphaComponent:0.7f].CGColor);
    CGContextSetLineWidth(context, lineDensity);
    
    CGFloat yPosition = kStaveHeight *( i + 4);
    CGFloat startXPoint = kStaveWidthMargin;
    CGContextMoveToPoint(context, startXPoint, yPosition); //start at this point
    
    CGFloat endXPoint = self.bounds.size.width - kStaveWidthMargin;
    CGContextAddLineToPoint(context, endXPoint, yPosition); //draw to this point
    
      // and now draw the Path!
    CGContextStrokePath(context);
  }
}

@end
