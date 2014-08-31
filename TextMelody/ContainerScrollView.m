//
//  ContainerScrollView.m
//  SendMelody
//
//  Created by Bennett Lin on 8/29/14.
//  Copyright (c) 2014 Bennett Lin. All rights reserved.
//

#import "ContainerScrollView.h"
#import "SymbolView.h"

@interface ContainerScrollView ()

@end

@implementation ContainerScrollView

-(instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {

  }
  return self;
}

  // this is the magic method that allows notes on staves to register touch immediately
-(UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
  UIView *result = [super hitTest:point withEvent:event];
  self.scrollEnabled = ![result.superview isKindOfClass:[SymbolView class]];
  return result;
}

-(BOOL)touchesShouldBegin:(NSSet *)touches withEvent:(UIEvent *)event inContentView:(UIView *)view {
  CGPoint locationPoint = [[touches anyObject] locationInView:view];
  UIView *touchedView = [view hitTest:locationPoint withEvent:event];

  if ([touchedView.superview isKindOfClass:SymbolView.class]) {
    SymbolView *note = (SymbolView *)touchedView.superview;
    [note beginTouch];
  }
  return YES;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  [self.customDelegate touchesBegan:touches withEvent:event];
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
  [self.customDelegate touchesMoved:touches withEvent:event];
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
  [self.customDelegate touchesCancelled:touches withEvent:event];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  [self.customDelegate touchesEnded:touches withEvent:event];
}

@end
