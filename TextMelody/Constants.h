//
//  Constants.h
//  TextMelody
//
//  Created by Bennett Lin on 8/29/14.
//  Copyright (c) 2014 Bennett Lin. All rights reserved.
//

#ifndef TextMelody_Constants_h
#define TextMelody_Constants_h

#define kIsIPhone (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)

#define kFontSonata @"Sonata"
#define kSymbolFontSize (kStaveHeight * 4)
#define kSymbolColour [UIColor blackColor]

#define kStaveWidth 1024.f // this must be 768 or less
#define kStaveWidthMargin (kStaveWidth * 0.025)
#define kStaveHeight (kIsIPhone ? 16.f : 16.f) // test
#define kContainerContentHeight (kStaveHeight * 12)

#define kStaveColour [UIColor blackColor]
#define kStaveLineDensity 0.75f
#define kStaveYAdjust (kStaveHeight * -0.1f)

#define kTouchScaleFactor 1.25
#define kTouchSubviewRadius 30.f

#define kAnimationDuration 0.15f

typedef enum musicSymbol {
  kTrebleClef,
  kAltoClef,
  kTenorClef,
  kBassClef,
  kSharp,
  kFlat,
  kLedgerLine,
  kQuarterNoteStemUp,
  kQuarterNoteStemDown,
  kQuarterNoteRest,
  kHalfNoteStemUp,
  kHalfNoteStemDown,
  kHalfNoteRest,
  kWholeNote,
  kWholeNoteRest,
  kBarline,
  kEndBarline
} MusicSymbol;

#endif
