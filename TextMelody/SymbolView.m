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
@property (strong, nonatomic) SymbolView *ledgerLine;

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
      [self modifyGivenSymbol:symbol resize:YES]; // must be between these two
      [self instantiateLedgerLine];
      [self instantiateTouchSubview];
    } else {
      [self modifyGivenSymbol:symbol resize:YES];
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

-(void)modifyGivenSymbol:(MusicSymbol)symbol resize:(BOOL)resize {
  self.mySymbol = symbol;
  self.text = [self stringForMusicSymbol:symbol];
  
  if (resize) {
    
    if (self.userInteractionEnabled) {
      CGRect frame = CGRectMake(self.frame.origin.x, self.frame.origin.y,
                                kTouchSubviewRadius * 2, kTouchSubviewRadius * 6);
      self.frame = frame;
      
    } else if (self.mySymbol == kLedgerLine) {
      self.frame = CGRectMake(0, 0, self.superview.frame.size.width, self.superview.frame.size.height);
      
    } else {
      [self sizeToFit];
    }
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
  
  [self modifyGivenSymbol:self.mySymbol resize:NO];
  [self repositionTouchSubview];
}

-(void)beginTouch {
  self.font = [UIFont fontWithName:kFontSonata size:kSymbolFontSize * kTouchScaleFactor];
  self.ledgerLine.font = [UIFont fontWithName:kFontSonata size:kSymbolFontSize * kTouchScaleFactor];
  [self repositionTouchSubview];
}

-(void)endTouch {
  self.font = [UIFont fontWithName:kFontSonata size:kSymbolFontSize];
  self.ledgerLine.font = [UIFont fontWithName:kFontSonata size:kSymbolFontSize];
  [self repositionTouchSubview];
}

-(void)sendHomeToRack {
  if (self.mySymbol == kQuarterNoteStemDown) {
    [self modifyGivenSymbol:kQuarterNoteStemUp resize:NO];
  } else if (self.mySymbol == kHalfNoteStemDown) {
    [self modifyGivenSymbol:kHalfNoteStemUp resize:NO];
  } else {
    [self modifyGivenSymbol:self.mySymbol resize:NO];
  }
  
  self.center = self.homePosition;
  [self repositionTouchSubview];
}

#pragma mark - custom getters and setters

#pragma mark - helper methods

-(void)instantiateLedgerLine {
  self.ledgerLine = [[SymbolView alloc] initWithSymbol:kLedgerLine];
  self.ledgerLine.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
  self.ledgerLine.hidden = YES;
  
  [self addSubview:self.ledgerLine];
  [self.ledgerLine modifyGivenSymbol:kLedgerLine resize:YES];
}

-(void)showLedgerLine:(BOOL)show {
  self.ledgerLine.hidden = !show;
}

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

@end
