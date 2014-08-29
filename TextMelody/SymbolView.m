//
//  SymbolView.m
//  TextMelody
//
//  Created by Bennett Lin on 8/29/14.
//  Copyright (c) 2014 Bennett Lin. All rights reserved.
//

#import "SymbolView.h"
#import "Constants.h"

@implementation SymbolView

-(instancetype)initWithSymbol:(MusicSymbol)symbol {
    self = [super init];
    if (self) {
      self.font = [UIFont fontWithName:kFontSonata size:kSymbolFontSize];
      self.textColor = kSymbolColour;
//      self.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
      
      [self modifyGivenSymbol:symbol];
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

#pragma mark - helper methods

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
      charIndex = 63;
      break;
    case kQuarterNoteStemDown:
      charIndex = 85;
      break;
    case kQuarterNoteRest:
      charIndex = 206;
      break;
    case kHalfNoteStemUp:
      charIndex = 211;
      break;
    case kHalfNoteStemDown:
      charIndex = 206;
      break;
    case kHalfNoteRest:
      charIndex = 238;
      break;
    case kWholeNote:
      charIndex = 238;
      break;
    case kWholeNoteRest:
      charIndex = 238;
      break;
    case kBarline:
      charIndex = 98;
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
