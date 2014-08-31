//
//  ViewController.m
//  TextMelody
//
//  Created by Bennett Lin on 8/29/14.
//  Copyright (c) 2014 Bennett Lin. All rights reserved.
//

#import "ViewController.h"
#import "Constants.h"
#import "ContainerScrollView.h"
#import "StavesView.h"
#import "SymbolView.h"

@interface ViewController () <UIScrollViewDelegate, ContainerDelegate>

@property (strong, nonatomic) StavesView *stavesView;
@property (strong, nonatomic) SymbolView *clef;
@property (strong, nonatomic) NSArray *keySigAccidentals;
@property (nonatomic) NSUInteger keySigIndex;
@property (strong, nonatomic) SymbolView *endBarline;

  // pointers
@property (strong, nonatomic) UIView *containerView;
@property (strong, nonatomic) SymbolView *touchedNote;
@property (strong, nonatomic) NSMutableArray *StuffOnStaves;

@property (nonatomic) CGVector touchOffset;
@property (nonatomic) NSInteger tempStaveIndexForTouchedNote;
@property (nonatomic) BOOL touchedNoteMoved;

@end

@implementation ViewController {
  CGFloat _screenWidth;
  CGFloat _screenHeight;
  CGFloat _keySigWidth;
}
            
-(void)viewDidLoad {
  [super viewDidLoad];
  
  _screenWidth = [UIScreen mainScreen].bounds.size.height;
  _screenHeight = [UIScreen mainScreen].bounds.size.width;
  
    // empty staves
  self.StuffOnStaves = [NSMutableArray new];
  for (int i = 0; i < 4; i++) {
    SymbolView *wholeRest = [[SymbolView alloc] initWithSymbol:kWholeNoteRest];
    [self.StuffOnStaves addObject:wholeRest];
    if (i < 3) {
      SymbolView *barline = [[SymbolView alloc] initWithSymbol:kBarline];
      [self.StuffOnStaves addObject:barline];
    }
  }
  
  [self loadFixedViews];
  [self instantiateNewNoteWithSymbol:kQuarterNoteStemUp];
  [self instantiateNewNoteWithSymbol:kHalfNoteStemUp];
  [self instantiateNewNoteWithSymbol:kWholeNote];
}

-(void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
}

-(void)viewWillDisappear:(BOOL)animated {
  self.touchedNote = nil;
  self.touchedNoteMoved = NO;
}

-(void)repositionStuffOnStaves {
  
  
  
}

-(void)loadFixedViews {
  
  if (kIsIPhone) {
    ContainerScrollView *scrollView = [[ContainerScrollView alloc] initWithFrame:CGRectMake(0, 0, _screenWidth, _screenHeight)];
    scrollView.center = self.view.center;
    scrollView.contentSize = CGSizeMake(kStaveWidth, _screenHeight);
    scrollView.customDelegate = self;
    [self.view addSubview:scrollView];
    self.containerView = scrollView;
  } else {
    self.containerView = self.view;
  }
  
  self.containerView.center = CGPointMake(_screenWidth / 2, _screenHeight / 2);

  self.stavesView = [[StavesView alloc] initWithFrame:CGRectMake(0, 0, kStaveWidth, kContainerContentHeight)];
  self.stavesView.center = CGPointMake(kStaveWidth / 2, _screenHeight / 3);
  
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
  self.keySigIndex = 11;
  [self updateKeySigLabel];
  
  self.endBarline = [[SymbolView alloc] initWithSymbol:kEndBarline];
  self.endBarline.center = CGPointMake(kStaveWidth - kStaveWidthMargin - self.endBarline.frame.size.width / 2, kStaveHeight * 7.5 + kStaveYAdjust);
  [self.stavesView addSubview:self.endBarline];
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
  
  newNote.homePosition = CGPointMake(xPosition, _screenHeight * 3/4);
  newNote.center = newNote.homePosition;
  
  [self.view addSubview:newNote];
}

-(void)discardNote:(SymbolView *)note {
  
    // FIXME: this will eventually be animated
  [note removeFromSuperview];
}

#pragma mark - note positioning methods

-(BOOL)decideWhetherToAddTouchedNoteToStaves {
  
    // note is within staves
  if (self.tempStaveIndexForTouchedNote > 3 && self.tempStaveIndexForTouchedNote < 20) {
    
      // add to containerView

    CGPoint selfPoint = CGPointMake(self.touchedNote.center.x,
                                    [self stavePositionForStaveIndex:self.tempStaveIndexForTouchedNote]);
    
    CGPoint stavesPoint;
    
    if ([self touchedNoteBelongsOnStaves]) {
      stavesPoint = selfPoint;
      
    } else {
      stavesPoint = [self getStavesViewLocationForSelfLocation:selfPoint];
      
        // add touched note to array
      [self.StuffOnStaves addObject:self.touchedNote];
      
        // generate new note for self.view
      [self instantiateNewNoteWithSymbol:self.touchedNote.mySymbol];
    }
    
    self.touchedNote.center = stavesPoint;
    self.touchedNote.homePosition = CGPointMake(CGFLOAT_MAX, CGFLOAT_MAX);
    [self.containerView addSubview:self.touchedNote];
    
    return YES;
    
      // note is not within staves
  } else {
    
      // if note already belongs on staves, discard
    if ([self touchedNoteBelongsOnStaves]) {
      [self discardNote:self.touchedNote];
      
        // else send it home to rack
    } else {
      [self.touchedNote sendHomeToRack];
    }
    return NO;
  }
}

-(CGPoint)recenterTouchedNoteWithLocationPoint:(CGPoint)locationPoint ended:(BOOL)ended {
  
//  CGFloat buffer = self.touchedNote.touched ? ((kStaveHeight * kTouchScaleFactor) - kStaveHeight) : 0;
  
  CGPoint touchLocation = (self.touchedNote.superview == self.view && !ended) ?
  locationPoint : [self getStavesViewLocationForSelfLocation:locationPoint];
  self.touchedNote.center = CGPointMake(self.touchOffset.dx + touchLocation.x,
                                        self.touchOffset.dy + touchLocation.y);
  return self.touchedNote.center;
}

-(void)changeTouchedNoteStemDirectionIfNecessary {
  
  if ((self.tempStaveIndexForTouchedNote < 12 &&
       (self.touchedNote.mySymbol == kQuarterNoteStemUp || self.touchedNote.mySymbol == kHalfNoteStemUp)) ||
      (self.tempStaveIndexForTouchedNote >= 12 &&
       (self.touchedNote.mySymbol == kQuarterNoteStemDown || self.touchedNote.mySymbol == kHalfNoteStemDown))) {\
        
    [self.touchedNote changeStemDirection];
  }
}



#pragma mark - touch methods

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  CGPoint locationPoint = [[touches anyObject] locationInView:self.view];
  UIView *touchedView = [self.view hitTest:locationPoint withEvent:event];

//  NSLog(@"touched view is %@", touchedView);
  
  if ([touchedView.superview isKindOfClass:SymbolView.class]) {
    if (!self.touchedNote) {
      self.touchedNote = (SymbolView *)touchedView.superview;
      [self.touchedNote beginTouch];
      
        // center to account for touch offset
      CGPoint touchLocation = self.touchedNote.superview == self.view ?
      locationPoint : [self getStavesViewLocationForSelfLocation:locationPoint];
      self.touchOffset = CGVectorMake(self.touchedNote.center.x - touchLocation.x,
                                      self.touchedNote.center.y - touchLocation.y);
      [self recenterTouchedNoteWithLocationPoint:touchLocation ended:NO];
      
      self.tempStaveIndexForTouchedNote = [self staveIndexForNoteCenter:locationPoint];
    }
  }
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
  if (self.touchedNote) {
    self.touchedNoteMoved = YES;
    
      // recenter
    CGPoint locationPoint = [[touches anyObject] locationInView:self.view];
    CGPoint noteCenter = [self recenterTouchedNoteWithLocationPoint:locationPoint ended:NO];
    self.tempStaveIndexForTouchedNote = [self staveIndexForNoteCenter:noteCenter];
    
          // change stem direction if necessary
    [self changeTouchedNoteStemDirectionIfNecessary];
  }
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  if (self.touchedNote) {
    
    [self.touchedNote endTouch];
    
    if (self.touchedNoteMoved) {
        // recenter
      CGPoint locationPoint = [[touches anyObject] locationInView:self.view];
      CGPoint noteCenter = [self recenterTouchedNoteWithLocationPoint:locationPoint ended:YES];
      self.tempStaveIndexForTouchedNote = [self staveIndexForNoteCenter:noteCenter];
      
        // check whether to add to staves
      [self decideWhetherToAddTouchedNoteToStaves];
      
      self.touchedNoteMoved = NO;
    }
    
    self.touchedNote = nil;
  }
}

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

#pragma mark - helper methods

-(BOOL)touchedNoteBelongsOnStaves {
  return (CGPointEqualToPoint(self.touchedNote.homePosition, CGPointMake(CGFLOAT_MAX, CGFLOAT_MAX)));
}

-(CGFloat)stavePositionForStaveIndex:(NSUInteger)staveIndex {
  return (staveIndex * kStaveHeight / 2) +
  _screenHeight / 3 - self.stavesView.frame.size.height / 2;
}

-(NSInteger)staveIndexForNoteCenter:(CGPoint)noteCenter {

  CGFloat yOrigin = _screenHeight / 3 - self.stavesView.frame.size.height / 2;
  CGFloat noteCenterRelativeToYOrigin = noteCenter.y - yOrigin;
  NSInteger staveIndex = ((noteCenterRelativeToYOrigin + kStaveHeight / 2) / (kStaveHeight / 2));
//  NSLog(@"staveIndex %li", (long)staveIndex);

    // establish whether to show ledger line here
  [self.touchedNote showLedgerLine:(staveIndex < 6 || staveIndex > 16)];
  
  return staveIndex;
}

-(CGPoint)getStavesViewLocationForSelfLocation:(CGPoint)selfLocation {
  CGFloat xPosition;
  if (kIsIPhone) {
    UIScrollView *scrollView = (UIScrollView *)self.containerView;
    xPosition = selfLocation.x + scrollView.contentOffset.x;
  } else {
    xPosition = selfLocation.x;
  }
  return CGPointMake(xPosition, selfLocation.y);
}

#pragma mark - system methods

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
  [self touchesEnded:touches withEvent:event];
}

//-(UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
//  UIView *result = [self.view hitTest:point withEvent:event];
//  NSLog(@"touch result is %@", result);
//  return result;
//}

-(void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
}

@end
