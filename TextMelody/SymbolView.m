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
@property (strong, nonatomic) SymbolView *ledgerLine1;
@property (strong, nonatomic) SymbolView *ledgerLine2;

@end

@implementation SymbolView

-(instancetype)initWithSymbol:(MusicSymbol)symbol {
  self = [super init];
  if (self) {
    
    self.onStaves = NO;
    
    self.font = [UIFont fontWithName:kFontSonata size:kSymbolFontSize];
    self.textAlignment = NSTextAlignmentCenter;
    self.textColor = kSymbolColour;
    if ([self determineIfTouchableWithSymbol:symbol]) {
      self.userInteractionEnabled = YES;
      [self modifyGivenSymbol:symbol]; // must be between these two
      [self instantiateLedgerLines];
      [self instantiateTouchSubview];
    } else {
      [self modifyGivenSymbol:symbol];
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

  if (self.userInteractionEnabled) {
    self.attributedText = [self verticallyAlignString:self.text];
    CGRect frame = CGRectMake(self.frame.origin.x, self.frame.origin.y,
                              kTouchSubviewRadius * 2, kTouchSubviewRadius * 6);
    self.frame = frame;
    
  } else if (self.mySymbol == kLedgerLine) {
    self.frame = CGRectMake(0, 0, self.superview.frame.size.width, self.superview.frame.size.height);
    
  } else {
    [self sizeToFit];
  }
}

-(void)modifyLedgersGivenStaveIndex:(NSUInteger)staveIndex {
  
  if (staveIndex <= 6) {
  
    switch (staveIndex) {
      case 6: // high A
        self.ledgerLine1.hidden = NO;
        self.ledgerLine1.center = CGPointMake(self.frame.size.width / 2,
                                              (self.frame.size.height / 2) - kStaveHeight / 2);
        self.ledgerLine2.hidden = YES;
        break;
      case 5:
        self.ledgerLine1.hidden = NO;
        self.ledgerLine1.center = CGPointMake(self.frame.size.width / 2,
                                              self.frame.size.height / 2);
        self.ledgerLine2.hidden = YES;
        break;
      case 4:
      default:
        self.ledgerLine1.hidden = NO;
        self.ledgerLine1.center = CGPointMake(self.frame.size.width / 2,
                                              (self.frame.size.height / 2) - kStaveHeight / 2);
        self.ledgerLine2.hidden = NO;
        self.ledgerLine2.center = CGPointMake(self.frame.size.width / 2,
                                              (self.frame.size.height / 2) + kStaveHeight / 2);
        break;
    }
    
  } else if (staveIndex >= 18 && staveIndex <= 22) {
    
      switch (staveIndex) {
      case 18: // low C
        self.ledgerLine1.hidden = NO;
        self.ledgerLine1.center = CGPointMake(self.frame.size.width / 2,
                                              (self.frame.size.height / 2) - kStaveHeight / 2);
        self.ledgerLine2.hidden = YES;
        break;
      case 19:
        self.ledgerLine1.hidden = NO;
        self.ledgerLine1.center = CGPointMake(self.frame.size.width / 2,
                                              (self.frame.size.height / 2) - kStaveHeight);
        self.ledgerLine2.hidden = YES;
        break;
      case 20:
      default:
        self.ledgerLine1.hidden = NO;
        self.ledgerLine1.center = CGPointMake(self.frame.size.width / 2,
                                              (self.frame.size.height / 2) - kStaveHeight / 2);
        self.ledgerLine2.hidden = NO;
        self.ledgerLine2.center = CGPointMake(self.frame.size.width / 2,
                                              (self.frame.size.height / 2) - kStaveHeight * 3 / 2);
        break;
    }
  } else {
    self.ledgerLine1.hidden = YES;
    self.ledgerLine2.hidden = YES;
  }
}

-(void)changeStemDirection {
  switch (self.mySymbol) {
    case kQuarterNoteStemUp:
      self.mySymbol = kQuarterNoteStemDown;
      break;
    case kQuarterNoteStemDown:
      self.mySymbol = kQuarterNoteStemUp;
      break;
    case kHalfNoteStemUp:
      self.mySymbol = kHalfNoteStemDown;
      break;
    case kHalfNoteStemDown:
      self.mySymbol = kHalfNoteStemUp;
      break;
    default:
      break;
  }
  
  [self modifyGivenSymbol:self.mySymbol];
  [self repositionTouchSubview];
}

-(void)beginTouch {
  self.font = [UIFont fontWithName:kFontSonata size:kSymbolFontSize * kTouchScaleFactor];
  self.ledgerLine1.font = [UIFont fontWithName:kFontSonata size:kSymbolFontSize * kTouchScaleFactor];
  self.ledgerLine2.font = [UIFont fontWithName:kFontSonata size:kSymbolFontSize * kTouchScaleFactor];
  [self repositionTouchSubview];
}

-(void)endTouch {
  self.font = [UIFont fontWithName:kFontSonata size:kSymbolFontSize];
  self.ledgerLine1.font = [UIFont fontWithName:kFontSonata size:kSymbolFontSize];
  self.ledgerLine2.font = [UIFont fontWithName:kFontSonata size:kSymbolFontSize];
  [self repositionTouchSubview];
}

-(void)sendHomeToRack {
  if (self.mySymbol == kQuarterNoteStemDown) {
    [self modifyGivenSymbol:kQuarterNoteStemUp];
  } else if (self.mySymbol == kHalfNoteStemDown) {
    [self modifyGivenSymbol:kHalfNoteStemUp];
  } else {
    [self modifyGivenSymbol:self.mySymbol];
  }
  
  self.userInteractionEnabled = NO;
  [UIView animateWithDuration:kAnimationDuration animations:^{
    self.center = self.homePosition;
  } completion:^(BOOL finished) {
    self.userInteractionEnabled = YES;
  }];
  
  [self repositionTouchSubview];
}

#pragma mark - helper methods

-(void)instantiateLedgerLines {
  self.ledgerLine1 = [[SymbolView alloc] initWithSymbol:kLedgerLine];
  self.ledgerLine1.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
  self.ledgerLine1.hidden = YES;
  
  [self addSubview:self.ledgerLine1];
  [self.ledgerLine1 modifyGivenSymbol:kLedgerLine];

  self.ledgerLine2 = [[SymbolView alloc] initWithSymbol:kLedgerLine];
  self.ledgerLine2.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
  self.ledgerLine2.hidden = YES;
  
  [self addSubview:self.ledgerLine2];
  [self.ledgerLine2 modifyGivenSymbol:kLedgerLine];
}

-(void)instantiateTouchSubview {
  self.touchSubview = [[TouchSubview alloc] initWithFrame:CGRectMake(0, 0, kTouchSubviewRadius * 2, kTouchSubviewRadius * 4)];
  [self addSubview:self.touchSubview];
  [self repositionTouchSubview];
}

-(void)repositionTouchSubview {
  
    // testing purposes
  self.touchSubview.layer.borderColor = [UIColor redColor].CGColor;
  self.touchSubview.layer.borderWidth = 0.5;
  self.touchSubview.layer.cornerRadius = kTouchSubviewRadius / 2;
  self.touchSubview.clipsToBounds = YES;
  
  self.touchSubview.center = CGPointMake(self.frame.size.width / 2,
                                         (self.frame.size.height + kStaveHeight) / 2 + kTouchSubviewRadius * 3/4);
}

-(NSAttributedString *)verticallyAlignString:(NSString *)string {

  NSMutableAttributedString *attString = [[NSMutableAttributedString alloc] initWithString:string];
  [attString addAttribute:NSBaselineOffsetAttributeName
                    value:@(kStaveHeight/2 + kStaveYAdjust)
                    range:NSMakeRange(0, string.length)];
  
  return attString;
}

-(BOOL)determineIfTouchableWithSymbol:(MusicSymbol)symbol {
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
    case kLedgerLine:
      charIndex = 95;
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

  // this allows touching above stem to register as scrollView touch
-(UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
  UIView *result = [super hitTest:point withEvent:event];
  if ([result isKindOfClass:TouchSubview.class]) {
    return result;
  } else {
    return nil;
  }
}

@end
