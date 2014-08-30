//
//  SymbolView.m
//  TextMelody
//
//  Created by Bennett Lin on 8/29/14.
//  Copyright (c) 2014 Bennett Lin. All rights reserved.
//

#import "SymbolView.h"
#import "Constants.h"
#import "TouchSubview.h"

@interface SymbolView ()

@property (strong, nonatomic) TouchSubview *touchSubview;

@end

@implementation SymbolView

-(instancetype)initWithSymbol:(MusicSymbol)symbol {
  self = [super init];
  if (self) {
    self.font = [UIFont fontWithName:kFontSonata size:kSymbolFontSize];
    self.textColor = kSymbolColour;
    [self modifyGivenSymbol:symbol];
    if ([self determineIfUserInterationEnabledWithSymbol:symbol]) {
      self.userInteractionEnabled = YES;
      [self instantiateTouchSubview];
    }
    
      // testing purposes
    UIView *centerDot = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1.5, 1.5)];
    centerDot.backgroundColor = [UIColor redColor];
    centerDot.center = self.center;
    [self addSubview:centerDot];
    
    self.layer.borderColor = [UIColor redColor].CGColor;
    self.layer.borderWidth = 0.5f;
  }
  return self;
}

-(void)modifyGivenSymbol:(MusicSymbol)symbol {
  self.mySymbol = symbol;
  self.text = [self stringForMusicSymbol:symbol];
  [self sizeToFit];
  CGRect frame = CGRectMake(0, 0, self.frame.size.width, kStaveHeight * 12);
  self.frame = frame;
}

-(void)beginTouch {
  self.font = [UIFont fontWithName:kFontSonata size:kSymbolFontSize * kTouchScaleFactor];
  [self sizeToFit];
}

-(void)endTouch {
  self.font = [UIFont fontWithName:kFontSonata size:kSymbolFontSize];
  [self sizeToFit];
  
  [self repositionTouchSubview];
}

#pragma mark - custom getters and setters

#pragma mark - helper methods

-(void)instantiateTouchSubview {
  self.touchSubview = [[TouchSubview alloc] initWithFrame:CGRectMake(0, 0, kTouchSubviewRadius * 2, kTouchSubviewRadius * 2)];
  [self addSubview:self.touchSubview];
  
  [self repositionTouchSubview];
}

-(void)repositionTouchSubview {
  
    // testing purposes
  self.touchSubview.layer.borderColor = [UIColor redColor].CGColor;
  self.touchSubview.layer.borderWidth = 0.5;
  self.touchSubview.layer.cornerRadius = kTouchSubviewRadius;
  self.touchSubview.clipsToBounds = YES;
  
  self.touchSubview.center = CGPointMake(self.frame.size.width / 2, (self.frame.size.height + kStaveHeight) / 2);
}

-(BOOL)determineIfUserInterationEnabledWithSymbol:(MusicSymbol)symbol {
  if (symbol == kQuarterNoteStemUp ||
      symbol == kQuarterNoteStemDown ||
      symbol == kHalfNoteStemUp ||
      symbol == kHalfNoteStemDown ||
      symbol == kWholeNote) {
    return YES;
  } else {
    return NO;
  }
}

-(NSString *)stringForMusicSymbol:(MusicSymbol)symbol {
  NSUInteger charIndex = 0;
  
    // FIXME: none of these are right. Fix!!
  switch (symbol) {
    case kTrebleClef:
      charIndex = 38;
      break;
    case kSharp:
      charIndex = 35;
      break;
    case kFlat:
      charIndex = 98;
      break;
    case kQuarterNoteStemUp:
      charIndex = 113;
      break;
    case kQuarterNoteStemDown:
      charIndex = 81;
      break;
    case kQuarterNoteRest:
      charIndex = 206;
      break;
    case kHalfNoteStemUp:
      charIndex = 104;
      break;
    case kHalfNoteStemDown:
      charIndex = 72;
      break;
    case kHalfNoteRest:
      charIndex = 238;
      break;
    case kWholeNote:
      charIndex = 119;
      break;
    case kWholeNoteRest:
      charIndex = 238;
      break;
    case kBarline:
      charIndex = 108;
      break;
    case kEndBarline:
      charIndex = 211;
      break;
      default:
      break;
  }
  unichar myChar[1] = {(unichar)charIndex};
  return [NSString stringWithCharacters:myChar length:1];
}

//-(UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
//{
//  if (!self.clipsToBounds && !self.hidden && self.alpha > 0) {
//    for (UIView *subview in self.subviews.reverseObjectEnumerator) {
//      CGPoint subPoint = [subview convertPoint:point fromView:self];
//      UIView *result = [subview hitTest:subPoint withEvent:event];
//      if (result != nil) {
//        return result;
//      }
//    }
//  }
//  
//  return nil;
//}

@end
