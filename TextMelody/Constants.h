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

#define kStaveWidth 768.f // this must be 768 or less
#define kStaveWidthMargin (kStaveWidth * 0.05)
#define kStaveHeight (kIsIPhone ? 20.f : 40.f)
#define kContainerContentHeight (kStaveHeight * 12)

#define kStaveColour [UIColor blackColor]
#define kStaveLineDensity 0.75f

typedef enum musicSymbol {
  kTrebleClef,
  kAltoClef,
  kTenorClef,
  kBassClef,
  kSharp,
  kFlat,
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
