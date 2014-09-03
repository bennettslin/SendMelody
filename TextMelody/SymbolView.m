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

@property (nonatomic) MusicSymbol mySymbol;
@property (nonatomic) NSUInteger noteDuration;

@end

@implementation SymbolView {
  BOOL _touched;
  UIView *_centerDot;
}

-(instancetype)initWithSymbol:(MusicSymbol)symbol {
  self = [super init];
  if (self) {
    
    self.onStaves = NO;
    
    self.font = [UIFont fontWithName:kFontSonata size:kSymbolFontSize];
    self.textAlignment = NSTextAlignmentCenter;
    self.textColor = kSymbolColour;
    if ([self determineIfTouchableWithSymbol:symbol]) {
      
      self.homePosition = CGPointMake(CGFLOAT_MAX, CGFLOAT_MAX);
      
      self.userInteractionEnabled = YES;
      [self modifyGivenSymbol:symbol]; // must be between these two
      [self instantiateLedgerLines];
      [self instantiateTouchSubview];
    } else {
      [self modifyGivenSymbol:symbol];
    }
    
      // testing purposes
    _centerDot = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1.5, 1.5)];
    _centerDot.backgroundColor = [UIColor redColor];
    _centerDot.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
    [self addSubview:_centerDot];
    
    self.layer.borderColor = [UIColor redColor].CGColor;
    self.layer.borderWidth = 0.5f;
  }
  return self;
}

-(void)modifyGivenSymbol:(MusicSymbol)symbol {
  self.mySymbol = symbol;
  self.text = [self stringForMusicSymbol:symbol];
  [self setNoteDurationGivenSymbol:symbol];

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

-(void)centerThisSymbol {
  switch (self.mySymbol) {
    case kWholeNoteRest:
      self.center = CGPointMake(self.center.x, kStaveHeight * 5);
      break;
    case kBarline:
      self.center = CGPointMake(self.center.x, kStaveHeight * 7.5 + kStaveYAdjust / 2);
      break;
    default:
      break;
  }
}

-(void)modifyLedgersGivenStaveIndex {
  
  CGFloat factor = _touched ? kTouchScaleFactor : 1.f;
  
  if (self.staveIndex <= 6) {
  
    switch (self.staveIndex) {
      case 6: // high A
        self.ledgerLine1.hidden = NO;
        self.ledgerLine1.center = CGPointMake(self.frame.size.width / 2,
                                              (self.frame.size.height / 2) - kStaveHeight * factor / 2);
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
                                              (self.frame.size.height / 2) - kStaveHeight * factor / 2);
        self.ledgerLine2.hidden = NO;
        self.ledgerLine2.center = CGPointMake(self.frame.size.width / 2,
                                              (self.frame.size.height / 2) + kStaveHeight * factor / 2);
        break;
    }
    
  } else if (self.staveIndex >= 18 && self.staveIndex <= 22) {
    
      switch (self.staveIndex) {
      case 18: // low C
        self.ledgerLine1.hidden = NO;
        self.ledgerLine1.center = CGPointMake(self.frame.size.width / 2,
                                              (self.frame.size.height / 2) - kStaveHeight * factor / 2);
        self.ledgerLine2.hidden = YES;
        break;
      case 19:
        self.ledgerLine1.hidden = NO;
        self.ledgerLine1.center = CGPointMake(self.frame.size.width / 2,
                                              (self.frame.size.height / 2) - kStaveHeight * factor );
        self.ledgerLine2.hidden = YES;
        break;
      case 20:
      default:
        self.ledgerLine1.hidden = NO;
        self.ledgerLine1.center = CGPointMake(self.frame.size.width / 2,
                                              (self.frame.size.height / 2) - kStaveHeight * factor / 2);
        self.ledgerLine2.hidden = NO;
        self.ledgerLine2.center = CGPointMake(self.frame.size.width / 2,
                                              (self.frame.size.height / 2) - kStaveHeight * factor * 3 / 2);
        break;
    }
  } else {
    self.ledgerLine1.hidden = YES;
    self.ledgerLine2.hidden = YES;
  }
}

-(void)changeStemDirectionIfNecessary {
  
    // staveIndex 12 is B4
  if ((self.staveIndex <= 12 &&
       (self.mySymbol == kQuarterNoteStemUp || self.mySymbol == kHalfNoteStemUp)) ||
      
      // staveIndex 13 is A4
      (self.staveIndex >= 13 &&
       (self.mySymbol == kQuarterNoteStemDown || self.mySymbol == kHalfNoteStemDown))) {

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
}

-(void)beginTouch {
  _touched = YES;
  
  self.font = [UIFont fontWithName:kFontSonata size:kSymbolFontSize * kTouchScaleFactor];
  self.ledgerLine1.font = [UIFont fontWithName:kFontSonata size:kSymbolFontSize * kTouchScaleFactor];
  self.ledgerLine2.font = [UIFont fontWithName:kFontSonata size:kSymbolFontSize * kTouchScaleFactor];
  _centerDot.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
  
  [self modifyGivenSymbol:self.mySymbol];
  [self repositionTouchSubview];
}

-(void)endTouch {
  _touched = NO;
  
  self.font = [UIFont fontWithName:kFontSonata size:kSymbolFontSize];
  self.ledgerLine1.font = [UIFont fontWithName:kFontSonata size:kSymbolFontSize];
  self.ledgerLine2.font = [UIFont fontWithName:kFontSonata size:kSymbolFontSize];
  _centerDot.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
  
  [self modifyGivenSymbol:self.mySymbol];
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

-(void)setNoteDurationGivenSymbol:(MusicSymbol)symbol {
  switch (symbol) {
    case kWholeNote:
    case kWholeNoteRest:
      self.noteDuration = 4;
      break;
    case kHalfNoteStemUp:
    case kHalfNoteStemDown:
    case kHalfNoteRest:
      self.noteDuration = 2;
      break;
    case kQuarterNoteStemUp:
    case kQuarterNoteStemDown:
    case kQuarterNoteRest:
      self.noteDuration = 1;
      break;
    default:
      self.noteDuration = 0;
      break;
  }
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
  
  CGFloat factor = _touched ? kTouchScaleFactor : 1.f;
  CGFloat buffer = _touched ? kStaveYAdjust : kStaveYAdjust;
  
  NSMutableAttributedString *attString = [[NSMutableAttributedString alloc] initWithString:string];
  [attString addAttribute:NSBaselineOffsetAttributeName
                    value:@((kStaveHeight * factor / 2) + buffer * factor)
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
