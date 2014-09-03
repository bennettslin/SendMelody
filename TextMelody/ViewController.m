//
//  ViewController.m
//  TextMelody
//
//  Created by Bennett Lin on 8/29/14.
//  Copyright (c) 2014 Bennett Lin. All rights reserved.
//

#import <MessageUI/MessageUI.h>
#import "ViewController.h"
#import "Constants.h"
#import "ContainerScrollView.h"
#import "StavesView.h"
#import "SymbolView.h"

typedef enum noteMultiplier {
  kWholeNoteMultiplier = 16,
  kHalfNoteMultiplier = 12,
  kQuarterNoteMultiplier = 8,
  kBarlineMultiplier = 1
} NoteMultiplier;

@interface ViewController () <UIScrollViewDelegate, ContainerDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate, UIActionSheetDelegate>

@property (strong, nonatomic) StavesView *stavesView;
@property (strong, nonatomic) SymbolView *clef;
@property (strong, nonatomic) NSArray *keySigAccidentals;
@property (nonatomic) NSUInteger keySigIndex;
@property (strong, nonatomic) SymbolView *endBarline;

  // pointers
@property (strong, nonatomic) UIView *containerView;
@property (strong, nonatomic) SymbolView *touchedNote;
@property (strong, nonatomic) NSMutableArray *stuffOnStaves;

@property (nonatomic) CGVector touchOffset;
@property (nonatomic) BOOL touchedNoteMoved;

@property (strong, nonatomic) UIButton *mailButton;
@property (strong, nonatomic) UIButton *textButton;

@property (strong, nonatomic) UIButton *testButton;
@property (strong, nonatomic) UIButton *soundButton;
@property (strong, nonatomic) UIButton *startOverButton;

@property (strong, nonatomic) NSMutableDictionary *barlineXPositions;
@property (strong, nonatomic) id temporaryObject;

@end

@implementation ViewController {
  CGFloat _screenWidth;
  CGFloat _screenHeight;
  CGFloat _keySigWidth;
}
            
-(void)viewDidLoad {
  [super viewDidLoad];
  
  self.barlineXPositions = [[NSMutableDictionary alloc] initWithObjects:@[@0.f, @0.f, @0.f, @0.f, @0.f]
                                                                forKeys:@[@0, @1, @2, @3, @4]];
                            
  _screenWidth = [UIScreen mainScreen].bounds.size.height;
  _screenHeight = [UIScreen mainScreen].bounds.size.width;
  
  [self loadFixedViews];
  [self instantiateStuffOnStaves];
  [self repositionStuffOnStaves];
  [self instantiateNewNoteWithSymbol:kQuarterNoteStemUp];
  [self instantiateNewNoteWithSymbol:kHalfNoteStemUp];
  [self instantiateNewNoteWithSymbol:kWholeNote];

  [self instantiateMessageButtons];
  [self instantiateOtherButtons];
}

-(void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  self.mailButton.hidden = ![MFMailComposeViewController canSendMail];
  self.mailButton.enabled = [MFMailComposeViewController canSendMail];

  self.textButton.hidden = ![MFMessageComposeViewController canSendText];
  self.textButton.enabled = [MFMessageComposeViewController canSendText];
}

-(void)viewWillDisappear:(BOOL)animated {
  self.touchedNote = nil;
  self.touchedNoteMoved = NO;
}

-(void)loadFixedViews {
  
  if (kIsIPhone) {
    ContainerScrollView *scrollView = [[ContainerScrollView alloc] initWithFrame:CGRectMake(0, 0, _screenWidth, _screenHeight)];
    
    scrollView.contentSize = CGSizeMake(kStaveWidth, _screenHeight);
    scrollView.customDelegate = self;
    [self.view addSubview:scrollView];
    self.containerView = scrollView;
  } else {
    self.containerView = self.view;
  }
  
  self.stavesView = [[StavesView alloc] initWithFrame:CGRectMake(0, 0, kStaveWidth, kContainerContentHeight)];
  self.stavesView.center = CGPointMake(kStaveWidth / 2, (kIsIPhone ? kContainerContentHeight / 2 : _screenHeight / 3));
  
  self.stavesView.layer.borderColor = [UIColor redColor].CGColor;
  self.stavesView.layer.borderWidth = 2.f;
  
  [self.containerView addSubview:self.stavesView];
  
  self.clef = [[SymbolView alloc] initWithSymbol:kTrebleClef];
  self.clef.center = CGPointMake(kStaveWidthMargin + self.clef.frame.size.width / 2, kStaveHeight * 7.5 + kStaveYAdjust);
  [self.stavesView addSubview:self.clef];
  
  NSMutableArray *tempAccidentals = [NSMutableArray arrayWithCapacity:6];
  for (int i = 0; i < 6; i++) {
    SymbolView *accidental = [[SymbolView alloc] initWithSymbol:kSharp];
    [self.stavesView addSubview:accidental];
    [tempAccidentals addObject:accidental];
  }
  self.keySigAccidentals = [NSArray arrayWithArray:tempAccidentals];
  self.keySigIndex = 0;
  [self updateKeySigLabel];
  
  self.endBarline = [[SymbolView alloc] initWithSymbol:kEndBarline];
  self.endBarline.center = CGPointMake(kStaveWidth - kStaveWidthMargin - self.endBarline.frame.size.width / 2.25, kStaveHeight * 7.5 + kStaveYAdjust / 2);
  
    // only place to establish last barlineXPosition
  [self setXPosition:self.endBarline.center.x forBarline:4];
  [self.stavesView addSubview:self.endBarline];
}

-(void)instantiateMessageButtons {

  self.mailButton = [[UIButton alloc] initWithFrame:CGRectMake(_screenWidth - kButtonLength, _screenHeight - kButtonLength, kButtonLength, kButtonLength)];
  self.mailButton.backgroundColor = [UIColor greenColor];
  [self.mailButton setTitle:@"mail" forState:UIControlStateNormal];
  [self.mailButton addTarget:self
                      action:@selector(mailButtonTapped)
            forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:self.mailButton];
  
  self.textButton = [[UIButton alloc] initWithFrame:CGRectMake(_screenWidth - kButtonLength, _screenHeight - kButtonLength * 2, kButtonLength, kButtonLength)];
  self.textButton.backgroundColor = [UIColor blueColor];
  [self.textButton setTitle:@"text" forState:UIControlStateNormal];
  [self.textButton addTarget:self
                      action:@selector(textButtonTapped)
            forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:self.textButton];
}

-(void)instantiateOtherButtons {
  self.testButton = [[UIButton alloc] initWithFrame:CGRectMake(0, _screenHeight - kButtonLength * 3, kButtonLength, kButtonLength)];
  self.testButton.backgroundColor = [UIColor redColor];
  [self.testButton setTitle:@"test" forState:UIControlStateNormal];
  [self.testButton addTarget:self
                      action:@selector(testButtonTapped)
            forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:self.testButton];
  
  self.soundButton = [[UIButton alloc] initWithFrame:CGRectMake(0, _screenHeight - kButtonLength * 2, kButtonLength, kButtonLength)];
  self.soundButton.backgroundColor = [UIColor purpleColor];
  [self.soundButton setTitle:@"sound" forState:UIControlStateNormal];
  [self.soundButton addTarget:self
                      action:@selector(soundButtonTapped)
            forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:self.soundButton];
  
  self.startOverButton = [[UIButton alloc] initWithFrame:CGRectMake(0, _screenHeight - kButtonLength, kButtonLength, kButtonLength)];
  self.startOverButton.backgroundColor = [UIColor orangeColor];
  [self.startOverButton setTitle:@"new" forState:UIControlStateNormal];
  [self.startOverButton addTarget:self
                       action:@selector(startOverButtonTapped)
             forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:self.startOverButton];
}

-(void)instantiateStuffOnStaves {

  self.stuffOnStaves = [NSMutableArray new];
  
  for (int h = 0; h < 4; h++) {
    
//    SymbolView *wholeRest = [[SymbolView alloc] initWithSymbol:kWholeNoteRest];
//    [wholeRest centerThisSymbol];
//    [self.stuffOnStaves addObject:wholeRest];
    
    switch (h) {
      case 0: {
        SymbolView *wholeNote = [[SymbolView alloc] initWithSymbol:kWholeNote];
        wholeNote.staveIndex = 12;
        [self centerNote:wholeNote];
        [self.stuffOnStaves addObject:wholeNote];
        break;
      }
        
      case 1: {
        NSMutableArray *arrayOfTwoHalves = [NSMutableArray new];
        for (int i = 0; i < 2; i++) {
          SymbolView *halfNote = [[SymbolView alloc] initWithSymbol:kHalfNoteStemUp];
          halfNote.staveIndex = 10 + i;
          [self centerNote:halfNote];
          [halfNote changeStemDirectionIfNecessary];
          [arrayOfTwoHalves addObject:halfNote];
        }
        [self.stuffOnStaves addObject:arrayOfTwoHalves];
        break;
      }
        
      case 2: {
        
        NSMutableArray *arrayOfTwoHalves = [NSMutableArray new];
        for (int i = 0; i < 2; i++) {
          NSMutableArray *arrayOfTwoQuarters = [NSMutableArray new];
          for (int j = 0; j < 2; j++) {
            SymbolView *quarterNote = [[SymbolView alloc] initWithSymbol:kQuarterNoteStemUp];
            quarterNote.staveIndex = 13 + j;
            [self centerNote:quarterNote];
            [quarterNote changeStemDirectionIfNecessary];
            [arrayOfTwoQuarters addObject:quarterNote];
          }
          [arrayOfTwoHalves addObject:arrayOfTwoQuarters];
        }
        [self.stuffOnStaves addObject:arrayOfTwoHalves];
        break;
      }
        
      case 3: {

        NSMutableArray *arrayOfTwoHalves = [NSMutableArray new];
        for (int i = 0; i < 2; i++) {
          
          switch (i) {
            case 0: {
              SymbolView *halfNote = [[SymbolView alloc] initWithSymbol:kHalfNoteStemUp];
              halfNote.staveIndex = 14 + i;
              [self centerNote:halfNote];
              [halfNote changeStemDirectionIfNecessary];
              [arrayOfTwoHalves addObject:halfNote];
              break;
            }
              
            case 1: {
              NSMutableArray *arrayOfTwoQuarters = [NSMutableArray new];
              for (int j = 0; j < 2; j++) {
                SymbolView *quarterNote = [[SymbolView alloc] initWithSymbol:kQuarterNoteStemUp];
                quarterNote.staveIndex = 13 + j;
                [self centerNote:quarterNote];
                [quarterNote changeStemDirectionIfNecessary];
                [arrayOfTwoQuarters addObject:quarterNote];
              }
              
              [arrayOfTwoHalves addObject:arrayOfTwoQuarters];
              break;
            }
            default:
              break;
          }
        }
        [self.stuffOnStaves addObject:arrayOfTwoHalves];
        break;
      }
 
      default:
        break;
    }
    
    if (h < 3) {
      SymbolView *barline = [[SymbolView alloc] initWithSymbol:kBarline];
      [barline centerThisSymbol];
      [self.stuffOnStaves addObject:barline];
    }
  }
//  NSLog(@"stuff on staves is %@", self.stuffOnStaves);
}

-(void)repositionStuffOnStaves {
  
    // establish very left edge
  CGFloat leftEdge = [self getXPositionForBarline:0];
  
    // establish range, keeping in mind that we're only using half of endBarline width,
    // since it's actually wider than it seems
  CGFloat range = kStaveWidth - leftEdge - self.endBarline.frame.size.width / 2 - kStaveWidthMargin;
  
    // now get total value of elements: 16 for whole elements, 12 for half, and 9 for quarter
  NSUInteger sumValue = 0;
  for (int counter = 0; counter < self.stuffOnStaves.count; counter++) {
    
    id currentObject = self.stuffOnStaves[counter];
    
      // whole note or rest
    if ([currentObject isKindOfClass:SymbolView.class]) {
      SymbolView *symbol = (SymbolView *)currentObject;
      
        // whole note or rest
      if (symbol.mySymbol == kWholeNote || symbol.mySymbol == kWholeNoteRest) {
        sumValue += kWholeNoteMultiplier;
        
          // barline
      } else if (symbol.mySymbol == kBarline) {
        sumValue += kBarlineMultiplier;
        [self setXPosition:leftEdge + sumValue forBarline:0];
      }
      
        // array of two halves
    } else if ([currentObject isKindOfClass:NSArray.class]) {
      NSArray *twoHalvesArray = (NSArray *)currentObject;
      
      for (int i = 0; i < 2; i++) {
        
          // this half is a half note or rest
        if ([twoHalvesArray[i] isKindOfClass:SymbolView.class]) {
          sumValue += kHalfNoteMultiplier;
          
            // this half is an array of two quarters
        } else {
          sumValue += kQuarterNoteMultiplier + kQuarterNoteMultiplier;
        }
      }
    }
  }
  
  CGFloat widthUnit = range / sumValue;

    // widthUnit is multiplied by the noteDuration's inherent value
    // so whole notes are 16 width units, half notes are 12 width units, and quarter notes 9 width units
  
  for (int i = 0; i < self.stuffOnStaves.count; i++) {
    
      // whole note or rest
    id currentObject = self.stuffOnStaves[i];
    if ([currentObject isKindOfClass:SymbolView.class]) {
      
      SymbolView *symbol = (SymbolView *)currentObject;
      leftEdge = [self xCenterNote:symbol fromLeftEdge:leftEdge withWidthUnit:widthUnit];
      
        // array of two halves
    } else if ([currentObject isKindOfClass:NSArray.class]) {
      NSArray *twoHalvesArray = (NSArray *)currentObject;
      
      for (int j = 0; j < 2; j++) {
        
          // this half is a half note or rest
        id currentHalfObject = twoHalvesArray[j];
        if ([currentHalfObject isKindOfClass:SymbolView.class]) {
          
          SymbolView *symbol = (SymbolView *)currentHalfObject;
          leftEdge = [self xCenterNote:symbol fromLeftEdge:leftEdge withWidthUnit:widthUnit];
          
            // this half is an array of two quarters
        } else if ([currentHalfObject isKindOfClass:NSArray.class]) {
          NSArray *twoQuartersArray = (NSArray *)currentHalfObject;
          
          for (int k = 0; k < 2; k++) {
            
            id currentQuarterObject = twoQuartersArray[k];
            if ([currentQuarterObject isKindOfClass:SymbolView.class]) {

              SymbolView *symbol = (SymbolView *)currentQuarterObject;
              leftEdge = [self xCenterNote:symbol fromLeftEdge:leftEdge withWidthUnit:widthUnit];
              
            }
          }
        }
      }
    }
  }
}

-(CGFloat)xCenterNote:(SymbolView *)note fromLeftEdge:(CGFloat)leftEdge withWidthUnit:(CGFloat)widthUnit {
  
  NSUInteger multiplier;
  switch (note.noteDuration) {
    case 4: // whole note or rest
      multiplier = kWholeNoteMultiplier;
      break;
    case 2: // half note or rest
      multiplier = kHalfNoteMultiplier;
      break;
    case 1: // quarter note or rest
      multiplier = kQuarterNoteMultiplier;
      break;
    default: // barline
      multiplier = kBarlineMultiplier;
      break;
  }
  
  CGFloat noteXRange = widthUnit * multiplier;
  note.center = CGPointMake(leftEdge + noteXRange / 2, note.center.y);

  if (!note.superview) {
    [self.stavesView addSubview:note];
  }

  return leftEdge + noteXRange;
}

#pragma mark - URL code and decode methods

-(NSString *)createURLStringFromStuffOnStavesAndSave {
  
    // each path component is four characters long
  
    // letter code is 'a' + staveIndex
    // 0 means it's a rest
    // 1 means it's a continuation of the previous note
  
  NSMutableArray *tempPathComponents = [NSMutableArray new];
  [tempPathComponents addObject:@"/"];
  
    // hard code key signature as 0 for now
  NSString *initialKey = @"0";
  [tempPathComponents addObject:initialKey];
  
    // get elements of each bar
  for (int i = 0; i < 4; i++) {
    id wholeElement = [self getElementInBar:i];
    
      // it's a whole note or rest
    if ([wholeElement isKindOfClass:SymbolView.class]) {
      SymbolView *wholeSymbol = (SymbolView *)wholeElement;
      
        // it's a whole rest
      if (wholeSymbol.mySymbol == kWholeNoteRest) {
        NSString *wholeRestString = @"0111";
        [tempPathComponents addObject:wholeRestString];
        
          // it's a whole note
      } else {
        unichar staveIndexChar = wholeSymbol.staveIndex + 'a';
        unichar pathComponentChars[4] = {staveIndexChar, '1', '1', '1'};
        NSString *wholeNoteString = [NSString stringWithCharacters:pathComponentChars length:4];
        [tempPathComponents addObject:wholeNoteString];
      }
      
        // it's an array of two halves
    } else if ([wholeElement isKindOfClass:NSArray.class]) {
      NSArray *wholeArray = (NSArray *)wholeElement;
      
      NSMutableArray *tempWholeStringComponents = [NSMutableArray new];
      
      for (int j = 0; j < 2; j++) {
        id halfElement = wholeArray[j];
        
          // it's a half note or rest
        if ([halfElement isKindOfClass:SymbolView.class]) {
          SymbolView *halfSymbol = (SymbolView *)halfElement;
          
          
            // it's a half rest
          if (halfSymbol.mySymbol == kHalfNoteRest) {
            [tempWholeStringComponents addObject:@"01"];
            
              // it's a half note
          } else {
            unichar staveIndexChar = halfSymbol.staveIndex + 'a';
            unichar halfPathComponentChars[2] = {staveIndexChar, '1'};
            NSString *halfNoteString = [NSString stringWithCharacters:halfPathComponentChars length:2];
            [tempWholeStringComponents addObject:halfNoteString];
          }

            // it's an array of two quarters
        } else if ([halfElement isKindOfClass:NSArray.class]) {
          NSArray *quarterArray = (NSArray *)halfElement;
          
          for (int k = 0; k < 2; k++) {
            id quarterElement = quarterArray[k];
            
              // it's a quarter note or rest (and can't be anything else, technically)
            if ([quarterElement isKindOfClass:SymbolView.class]) {
              SymbolView *quarterSymbol = (SymbolView *)quarterElement;
              
                // it's a quarter rest
              if (quarterSymbol.mySymbol == kQuarterNoteRest) {
                [tempWholeStringComponents addObject:@"0"];
                
                  // it's a quarter note
              } else {
                unichar staveIndexChar = quarterSymbol.staveIndex + 'a';
                unichar quarterPathComponentChars[1] = {staveIndexChar};
                NSString *quarterNoteString = [NSString stringWithCharacters:quarterPathComponentChars length:1];
                [tempWholeStringComponents addObject:quarterNoteString];
              }
            }
          }
        }
      }

      NSString *stringFromComponents = [tempWholeStringComponents componentsJoinedByString:@""];
      [tempPathComponents addObject:stringFromComponents];
    }
  }

  NSString *finalURLString = [NSString stringWithFormat:@"melodySent://%@/%@/%@/%@/%@",
                              initialKey, tempPathComponents[2], tempPathComponents[3], tempPathComponents[4], tempPathComponents[5]];
  
    // save to user defaults
  NSArray *pathComponentsArray = [NSArray arrayWithArray:tempPathComponents];
  [[NSUserDefaults standardUserDefaults] setObject:pathComponentsArray forKey:kPathComponentsKey];
  
  NSLog(@"final string is %@", finalURLString);
  return finalURLString;
}

-(id)getElementInBar:(NSUInteger)barNumber {
  
  NSUInteger currentBarline = 0;
  for (int i = 0; i < self.stuffOnStaves.count; i++) {
    id element = self.stuffOnStaves[i];
    
      // get barline
    if ([element isKindOfClass:SymbolView.class]) {
      SymbolView *symbol = (SymbolView *)element;
      if (symbol.mySymbol == kBarline) {
        currentBarline++;
      }
    }
    
      // get next object after barline
    if (currentBarline == barNumber) {
      
        // ensures that this method does not return a barline
      
        // it's a note
      if ([element isKindOfClass:SymbolView.class]) {
        SymbolView *symbol = (SymbolView *)element;
        if (symbol.mySymbol != kBarline) {
          return element;
        }
        
          // it's an array of notes
      } else if ([element isKindOfClass:NSArray.class]) {
        return element;
      }
    }
  }
  
  return nil;
}


-(void)populateStuffOnStavesArrayFromPathComponents {
  
}

#pragma mark - touch methods

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  
  CGPoint touchPoint = [[touches anyObject] locationInView:self.view];
  UIView *touchedView = [self.view hitTest:touchPoint withEvent:event];
  
  if ([touchedView.superview isKindOfClass:SymbolView.class]) {
    if (!self.touchedNote) {
      
      self.touchedNote = (SymbolView *)touchedView.superview;
      
//      if ([self noteWasAlreadyPlacedOnStaves:self.touchedNote]) {
//        [self removeFromStavesView];
//      }
      
      [self.touchedNote beginTouch];
      
        // center to account for touch offset
      CGPoint realPoint = [self getStavesViewLocationForNote:self.touchedNote withSelfLocation:touchPoint];
      
      self.touchOffset = CGVectorMake(self.touchedNote.center.x - realPoint.x,
                                      self.touchedNote.center.y - realPoint.y);
    }
  }
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
  
//  NSLog(@"touches Moved");
  if (self.touchedNote) {
    self.touchedNoteMoved = YES;
    
      // recenter
    CGPoint touchPoint = [[touches anyObject] locationInView:self.view];
    CGPoint noteCenter = [self adjustForTouchOffsetLocationPoint:touchPoint];
    CGPoint realCenter = [self getStavesViewLocationForNote:self.touchedNote withSelfLocation:noteCenter];
    self.touchedNote.center = realCenter;
    self.touchedNote.staveIndex = [self staveIndexForNoteCenter:realCenter];
//    NSLog(@"staveIndex is %li", (long)self.touchedNote.staveIndex);
    
          // change stem direction if necessary
    [self constrictStaveIndex];
    [self.touchedNote modifyLedgersGivenStaveIndex];
    [self.touchedNote changeStemDirectionIfNecessary];
    
    /*
    
      // if within staves, handle how to rearrange stuffOnStaves array
    NSUInteger barForTouchedNote = [self barForTouchedNote];
    if (barForTouchedNote != NSUIntegerMax) {
      
      NSArray *elementsInBar = [self getElementsInBar:barForTouchedNote];
      NSUInteger barSection = [self sectionForTouchedNoteInBar:barForTouchedNote
                                              withElementCount:elementsInBar.count];
      
        // A. handle whole note
      if (self.touchedNote.mySymbol == kWholeNote) {
        [self hideOrShowElements:elementsInBar hide:YES];
        
          // 1. one whole
        
          // 2. two halves
        
          // 3. one half, two quarters
        
          // 4. four quarters
        
          // B. handle half note
      } else if (self.touchedNote.mySymbol == kHalfNoteStemUp ||
                 self.touchedNote.mySymbol == kHalfNoteStemDown) {

          // 1. one whole
        
          // 2. two halves
        
          // 3. one half, two quarters
        
          // 4. four quarters
        
          // C. quarter note
      } else if (self.touchedNote.mySymbol == kQuarterNoteStemUp ||
                 self.touchedNote.mySymbol == kQuarterNoteStemDown) {
        
          // 1. one whole
        
          // 2. two halves
        
          // 3. one half, two quarters
        
          // 4. four quarters
        
      }
    }
     */
  } else {
//    NSLog(@"no touched note");
  }
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  
//  NSLog(@"touchesEnded");
  if (self.touchedNote) {
    
    [self.touchedNote endTouch];
    
    if (self.touchedNoteMoved) {
      
        // check whether to add to staves
      [self constrictStaveIndex];
      [self.touchedNote modifyLedgersGivenStaveIndex];
      
      [self decideWhetherToAddTouchedNoteToStaves];
      self.touchedNoteMoved = NO;
    }
    
    self.touchedNote = nil;
  }
}

#pragma mark - note to staves helper methods -----------------------------------

-(void)setXPosition:(CGFloat)xPosition forBarline:(NSUInteger)key {
  if (key <= 4) {
    [self.barlineXPositions removeObjectForKey:@(key)];
    [self.barlineXPositions setObject:@(xPosition) forKey:@(key)];
  }
}

-(CGFloat)getXPositionForBarline:(NSUInteger)key {
  if (key <= 4) {
    return [[self.barlineXPositions objectForKey:@(key)] floatValue];
  } else {
    return CGFLOAT_MAX;
  }
}

-(NSUInteger)barForTouchedNote {
    // touched note is within staves yPosition
  if (self.touchedNote.staveIndex > 3 && self.touchedNote.staveIndex < 21) {
    
    CGFloat xPosition;
    if (kIsIPhone && ![self noteWasAlreadyPlacedOnStaves:self.touchedNote]) {
      UIScrollView *scrollView = (UIScrollView *)self.containerView;
      xPosition = self.touchedNote.center.x + scrollView.contentOffset.x;
    } else {
      xPosition = self.touchedNote.center.x;
    }
    
    for (NSUInteger index = 0; index < 4; index++) {
      if (xPosition > [self getXPositionForBarline:index] && xPosition <= [self getXPositionForBarline:index + 1]) {
        return index;
      }
    }
  }
  
  return NSUIntegerMax;
}

//-(NSUInteger)countOfUnhiddenStuffOnStaves {
//  NSUInteger count = 0;
//  for (SymbolView *symbol in self.StuffOnStaves) {
//    if (symbol.hidden == NO) {
//      count++;
//    }
//  }
//  return count;
//}

/*


-(NSUInteger)sectionForTouchedNoteInBar:(NSUInteger)barNumber withElementCount:(NSUInteger)count {
  
  CGFloat leftBarlineXPosition = [self getXPositionForBarline:barNumber];
  CGFloat rightBarlineXPosition = [self getXPositionForBarline:barNumber + 1];
  CGFloat barLength = rightBarlineXPosition - leftBarlineXPosition;
  CGFloat barSectionLength = barLength / count;
  
  CGFloat touchedNoteXPositionWithinBar = self.touchedNote.center.x - leftBarlineXPosition;
  
  NSUInteger section = (NSUInteger)(touchedNoteXPositionWithinBar / barSectionLength);
  return section;
}



-(void)toggleObject:(id)object hidden:(BOOL)hide {
  if ([object isKindOfClass:SymbolView.class]) {
    SymbolView *symbol = (SymbolView *)object;
    symbol.hidden = hide;
  } else if ([object isKindOfClass:NSArray.class]) {
    NSArray *array = (NSArray *)object;
    for (id object in array) {
      [self toggleObject:object hidden:hide];
    }
  }
}

*/

#pragma mark - keySig methods

-(void)updateKeySigLabel {

    // sharps are 0-5, flats are 6-11
  MusicSymbol symbol = (self.keySigIndex < 6) ? kSharp : kFlat;
  CGFloat accidentalWidth = 0;
  
  for (int i = 0; i < 6; i++) {
    SymbolView *accidental = self.keySigAccidentals[i];
    if ((symbol == kSharp && i < self.keySigIndex) ||
        (symbol == kFlat && i <= (self.keySigIndex - 6))) {
       
      accidental.hidden = NO;
      [accidental modifyGivenSymbol:symbol];
      CGFloat factor = [self stavePositionForAccidentalIndex:i];
      accidental.center = CGPointMake(kStaveWidthMargin + self.clef.frame.size.width + ((i + 0.5) * accidental.frame.size.width), kStaveHeight * (factor / 2 + 3.5 + kStaveYAdjust));
      
      if (accidentalWidth == 0) {
        accidentalWidth = accidental.frame.size.width;
      }
      
    } else {
      accidental.hidden = YES;
    }
  }
  
  _keySigWidth = (self.keySigIndex < 6 ? self.keySigIndex : (self.keySigIndex % 6) + 1) * accidentalWidth;
  
    // only place to establish first barlineXPosition
  [self setXPosition:(kStaveWidthMargin + self.clef.frame.size.width + _keySigWidth) forBarline:0];
}

-(CGFloat)stavePositionForAccidentalIndex:(NSUInteger)accidentalIndex {
  
  CGFloat finalValue = 0;
  
  if (accidentalIndex != NSUIntegerMax) { // check accidental index
  
      // sharps
    if (self.keySigIndex <= 6) {
        //------------------------------------------------------------------------
        // even or odd index (default is tenor clef)
      finalValue = (accidentalIndex % 2 == 0) ?
      6 - accidentalIndex * 0.5 :
      2.5 - accidentalIndex * 0.5;
        //------------------------------------------------------------------------
      
        // all other keys but tenor clef have first and third accidentals raised
      if (self.clef.mySymbol != kTenorClef) {
        finalValue = (accidentalIndex == 0 || accidentalIndex == 2) ? (finalValue - 7) : finalValue;
      }
      
        // flats
    } else {
        //------------------------------------------------------------------------
        // even or odd index (default is tenor clef)
      finalValue = (accidentalIndex % 2 == 0) ?
      3 + accidentalIndex * 0.5 :
      -0.5 + accidentalIndex * 0.5;
        //------------------------------------------------------------------------
    }
  }
  
  switch (self.clef.mySymbol) {
    case kTrebleClef:
      finalValue = finalValue + 4;
      break;
    case kAltoClef:
      finalValue = finalValue + 5;
      break;
    case kBassClef:
      finalValue = finalValue + 6;
      break;
    default:
      break;
  }
  
  return finalValue;
}

#pragma mark - note state change methods

-(void)instantiateNewNoteWithSymbol:(MusicSymbol)symbol {
  
  if (symbol == kQuarterNoteStemDown) {
    symbol = kQuarterNoteStemUp;
  } else if (symbol == kHalfNoteStemDown) {
    symbol = kHalfNoteStemUp;
  }
  
  SymbolView *newNote = [[SymbolView alloc] initWithSymbol:symbol];
  CGFloat xPosition;
  
    // FIXME: change hard coded values
  switch (symbol) {
    case kQuarterNoteStemUp:
      xPosition = _screenWidth  * 0.25;
      break;
    case kHalfNoteStemUp:
      xPosition = _screenWidth  * 0.50;
      break;
    case kWholeNote:
      xPosition = _screenWidth  * 0.75;
      break;
    default:
      break;
  }
  
  newNote.homePosition = CGPointMake(xPosition, _screenHeight * 4/5);
  newNote.center = newNote.homePosition;
  
  [self.view addSubview:newNote];
}

-(void)discardNote:(SymbolView *)note {
  
    // FIXME: this will eventually be animated
  [note removeFromSuperview];
}

#pragma mark - note positioning methods

-(void)constrictStaveIndex {
    // if 0 to 3, it's 4; if 21 to 24, it's 20
  if (self.touchedNote.staveIndex >= 0 && self.touchedNote.staveIndex < 4) {
    self.touchedNote.staveIndex = 4;
  } else if (self.touchedNote.staveIndex <= 24 && self.touchedNote.staveIndex > 20) {
    self.touchedNote.staveIndex = 20;
  }
}

-(BOOL)decideWhetherToAddTouchedNoteToStaves {
  
    // note is within staves
  if ([self barForTouchedNote] != NSUIntegerMax) {
    
    [self centerNote:self.touchedNote];
    
    if (![self noteWasAlreadyPlacedOnStaves:self.touchedNote]) {
      self.touchedNote.homePosition = CGPointMake(CGFLOAT_MAX, CGFLOAT_MAX);
      
        // add touched note to array
      [self.stuffOnStaves addObject:self.touchedNote];
      
        // generate new note for self.view
      [self instantiateNewNoteWithSymbol:self.touchedNote.mySymbol];
    }
    
    [self.stavesView addSubview:self.touchedNote];
    
    return YES;
    
      // note is not within staves
  } else {
    
      // if note already belongs on staves, discard
    if ([self noteWasAlreadyPlacedOnStaves:self.touchedNote]) {
      [self discardNote:self.touchedNote];
      
        // else send it home to rack
    } else {
      [self.touchedNote sendHomeToRack];
    }
    
    return NO;
  }
}

-(CGPoint)adjustForTouchOffsetLocationPoint:(CGPoint)locationPoint {
  
  CGPoint touchLocation = locationPoint;
  return CGPointMake(self.touchOffset.dx + touchLocation.x,
                     self.touchOffset.dy + touchLocation.y);
}

#pragma mark - touched note helper methods -------------------------------------

-(BOOL)noteWasAlreadyPlacedOnStaves:(SymbolView *)note {
  return (CGPointEqualToPoint(note.homePosition, CGPointMake(CGFLOAT_MAX, CGFLOAT_MAX)));
}

-(CGFloat)stavePositionForStaveIndex:(NSUInteger)staveIndex {
  return ((staveIndex) * kStaveHeight / 2);
}

-(NSInteger)staveIndexForNoteCenter:(CGPoint)noteCenter {

  CGFloat yOrigin = 0;
  
  if ([self noteWasAlreadyPlacedOnStaves:self.touchedNote]) {
    yOrigin = 0;
  } else {
    yOrigin = _screenHeight / 3 - self.stavesView.frame.size.height / 2;
  }
  
  CGFloat noteCenterRelativeToYOrigin = noteCenter.y - yOrigin;
  NSInteger staveIndex = ((noteCenterRelativeToYOrigin + kStaveHeight * .25f) / (kStaveHeight / 2.f));

  return staveIndex;
}

-(void)removeFromStavesView {

    // this works in iPhone for now because stavesHeight origin.y is zero
  
    // FIXME: this does not work in iPad!
  
//  self.touchedNote.homePosition = CGPointZero;
//  [self.containerView addSubview:self.touchedNote];
}

-(CGPoint)getStavesViewLocationForNote:(SymbolView *)note withSelfLocation:(CGPoint)selfLocation {
  
  CGFloat xPosition, yPosition;
  
  if (kIsIPhone && [self noteWasAlreadyPlacedOnStaves:note]) {
    UIScrollView *scrollView = (UIScrollView *)self.containerView;
    xPosition = selfLocation.x + scrollView.contentOffset.x;
  } else {
    xPosition = selfLocation.x;
  }
  
//  if ([self noteWasAlreadyPlacedOnStaves:note]) {
//    yPosition = selfLocation.y;
//  } else {
//    yPosition = selfLocation.y + self.stavesView.frame.origin.y;;
//  }

  yPosition = selfLocation.y;
  return CGPointMake(xPosition, yPosition);
}

-(void)centerNote:(SymbolView *)note {
  CGPoint selfPoint;
  
    // already added to stavesView
  if ([self noteWasAlreadyPlacedOnStaves:note]) {
    
    CGFloat buffer = 0;
    if (kIsIPhone) {
      ContainerScrollView *containerScrollView = (ContainerScrollView *)self.containerView;
      buffer = containerScrollView.contentOffset.x;
    }
    
    selfPoint = CGPointMake(note.center.x - buffer,
                            [self stavePositionForStaveIndex:note.staveIndex]);
    
      // not yet added to stavesView
  } else {
    
    CGFloat buffer = 0;
    if (kIsIPhone) {
      ContainerScrollView *containerScrollView = (ContainerScrollView *)self.containerView;
      buffer = containerScrollView.contentOffset.x;
    }
    
    selfPoint = CGPointMake(note.center.x + buffer,
                            [self stavePositionForStaveIndex:note.staveIndex]);
  }

  note.center = [self getStavesViewLocationForNote:note withSelfLocation:selfPoint];
}

#pragma mark - mail and text methods -------------------------------------------

-(void)mailButtonTapped {
  
  if ([MFMailComposeViewController canSendMail]) {
    MFMailComposeViewController *mailVC = [[MFMailComposeViewController alloc] init];
    mailVC.mailComposeDelegate = self;
    
    [mailVC setSubject:@"Sending you a melody"];
    
    NSString *bodyText = [self createURLStringFromStuffOnStavesAndSave];
    [mailVC setMessageBody:bodyText isHTML:NO];
    
      // Add attachment
    NSData *imageData = [self generatePNGDataFromStavesView];
    [mailVC addAttachmentData:imageData mimeType:@"image/png" fileName:@"melody"];
    
    [self presentViewController:mailVC animated:YES completion:NULL];
    
  } else {
    [self showCantSendAlertWithTitle:@"Error" message:@"This device is unable to send mail."];
  }
}

-(void) mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
  
  switch (result) {
    case MFMailComposeResultCancelled:
    break;
    case MFMailComposeResultSaved:
    break;
    case MFMailComposeResultSent:
    break;
    case MFMailComposeResultFailed: {
    [self showCantSendAlertWithTitle:@"Error" message:@"Failed to send mail."];
    break;
    }
    default:
    break;
  }
  
  [self dismissViewControllerAnimated:YES completion:NULL];
}

-(void)textButtonTapped {
  if([MFMessageComposeViewController canSendText]) {
    
    MFMessageComposeViewController *textVC = [[MFMessageComposeViewController alloc] init];
    textVC.messageComposeDelegate = self;
    
      // attach image if possible
    if ([MFMessageComposeViewController canSendAttachments] &&
        [MFMessageComposeViewController isSupportedAttachmentUTI:@"public.data"]) {
      
      NSData *imageData = [self generatePNGDataFromStavesView];
      [textVC addAttachmentData:imageData typeIdentifier:@"public.data" filename:@"melody.png"];
    }
    
    NSString *bodyText = [self createURLStringFromStuffOnStavesAndSave];
    [textVC setBody:bodyText];
    
      // Present message view controller on screen
    [self presentViewController:textVC animated:YES completion:nil];
    
  } else {
    [self showCantSendAlertWithTitle:@"Error" message:@"This device is unable to send messages."];
  }
}

-(void)messageComposeViewController:(MFMessageComposeViewController *)controller
                didFinishWithResult:(MessageComposeResult)result {
  switch (result) {
    case MessageComposeResultCancelled:
      break;
    case MessageComposeResultFailed: {
    [self showCantSendAlertWithTitle:@"Error" message:@"Failed to send message."];
    break;
    }
    case MessageComposeResultSent:
      break;
    default:
      break;
  }
  
  [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)showCantSendAlertWithTitle:(NSString *)title message:(NSString *)message {
  UIAlertView *warningAlert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
  [warningAlert show];
}

#pragma mark - other button methods

-(void)testButtonTapped {
  NSLog(@"stuffOnStaves is %@, count %lu", self.stuffOnStaves, (unsigned long)self.stuffOnStaves.count);
  
}

-(void)soundButtonTapped {
  
  
}

-(void)startOverButtonTapped {
  UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Are you sure? You will lose all changes." delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Okay" otherButtonTitles:nil, nil];
  [actionSheet showInView:self.view];
}

#pragma mark - image methods ---------------------------------------------------

-(NSData *)generatePNGDataFromStavesView {
  UIImage *image;
  UIGraphicsBeginImageContext(self.stavesView.frame.size);
  [self.stavesView.layer renderInContext:UIGraphicsGetCurrentContext()];
  image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  
  return UIImagePNGRepresentation(image);
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error
  contextInfo:(void *)contextInfo {
  if (error) {
//    NSLog(@"error %@", error);
  } else {
//    NSLog(@"no error");
  }
}

#pragma mark - system methods

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
  [self touchesEnded:touches withEvent:event];
}

-(void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
}

@end
