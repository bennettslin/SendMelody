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

//@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) StavesView *stavesView;
@property (strong, nonatomic) SymbolView *clef;
@property (strong, nonatomic) NSArray *keySigAccidentals;
@property (nonatomic) NSUInteger keySigIndex;
@property (strong, nonatomic) SymbolView *endBarline;

  // pointers
@property (strong, nonatomic) UIView *containerView;
@property (strong, nonatomic) SymbolView *touchedNote;
@property (strong, nonatomic) NSMutableArray *notesOnStaves;

@end

@implementation ViewController {
  CGFloat _screenWidth;
  CGFloat _screenHeight;
}
            
-(void)viewDidLoad {
  [super viewDidLoad];
  
  _screenWidth = [UIScreen mainScreen].bounds.size.height;
  _screenHeight = [UIScreen mainScreen].bounds.size.width;
  
  self.notesOnStaves = [NSMutableArray new];
  
  [self loadFixedViews];
  [self instantiateNewNoteWithSymbol:kQuarterNoteStemUp];
  [self instantiateNewNoteWithSymbol:kHalfNoteStemUp];
  [self instantiateNewNoteWithSymbol:kWholeNote];
}

-(void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
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
  self.stavesView.center = CGPointMake(kStaveWidth / 2, _screenHeight / 2);
  
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

-(void)instantiateNewNoteWithSymbol:(MusicSymbol)symbol {
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
  
  newNote.center = CGPointMake(xPosition, _screenHeight - 50);
  NSLog(@"%i is %.2f, %.2f", newNote.mySymbol, newNote.frame.size.width, newNote.frame.size.height);
  [self.view addSubview:newNote];
}

#pragma mark - touch methods

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  CGPoint locationPoint = [[touches anyObject] locationInView:self.view];
  UIView *touchedView = [self.view hitTest:locationPoint withEvent:event];

  if ([touchedView.superview isKindOfClass:SymbolView.class]) {
    self.touchedNote = (SymbolView *)touchedView.superview;
    [self.touchedNote beginTouch];
    self.touchedNote.center = self.touchedNote.superview == self.view ?
      locationPoint : [self getStavesViewLocationForSelfViewLocation:locationPoint];
  }
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
  if (self.touchedNote) {
    CGPoint locationPoint = [[touches anyObject] locationInView:self.view];
    self.touchedNote.center = self.touchedNote.superview == self.view ?
    locationPoint : [self getStavesViewLocationForSelfViewLocation:locationPoint];
  }
  
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
  [self touchesEnded:touches withEvent:event];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  if (self.touchedNote) {
    [self.touchedNote endTouch];
    CGPoint locationPoint = [[touches anyObject] locationInView:self.view];
    self.touchedNote.center = [self getStavesViewLocationForSelfViewLocation:locationPoint];
    [self.stavesView addSubview:self.touchedNote];
    
      // add touched note to array
    [self.notesOnStaves addObject:self.touchedNote];
    
      // generate new note for self.view
    [self instantiateNewNoteWithSymbol:self.touchedNote.mySymbol];
    
    self.touchedNote = nil;
  }
}

#pragma mark - keySig methods

-(void)updateKeySigLabel {

    // sharps are 0-5, flats are 6-11
  MusicSymbol symbol = (self.keySigIndex < 6) ? kSharp : kFlat;
  
  for (int i = 0; i < 6; i++) {
    SymbolView *accidental = self.keySigAccidentals[i];
    if ((symbol == kSharp && i < self.keySigIndex) ||
        (symbol == kFlat && i <= (self.keySigIndex - 6))) {
      accidental.hidden = NO;
      [accidental modifyGivenSymbol:symbol];
      CGFloat factor = [self stavePositionForAccidentalIndex:i];
      accidental.center = CGPointMake(kStaveWidthMargin + self.clef.frame.size.width + ((i + 0.5) * accidental.frame.size.width), kStaveHeight * (factor / 2 + 3.5 + kStaveYAdjust));
    } else {
      
      accidental.hidden = YES;
    }
  }
}

-(CGFloat)stavePositionForAccidentalIndex:(NSUInteger)index {
  
  CGFloat finalValue = 0;
  
    // sharps
  if (self.keySigIndex <= 6) {
      //------------------------------------------------------------------------
      // even or odd index (default is tenor clef)
    finalValue = (index % 2 == 0) ?
    6 - index * 0.5 :
    2.5 - index * 0.5;
      //------------------------------------------------------------------------
    
      // all other keys but tenor clef have first and third accidentals raised
    if (self.clef.mySymbol != kTenorClef) {
      finalValue = (index == 0 || index == 2) ? (finalValue - 7) : finalValue;
    }
    
      // flats
  } else {
      //------------------------------------------------------------------------
      // even or odd index (default is tenor clef)
    finalValue = (index % 2 == 0) ?
    3 + index * 0.5 :
    -0.5 + index * 0.5;
      //------------------------------------------------------------------------
  }
  
  switch (self.clef.mySymbol) {
    case kTrebleClef:
      finalValue = finalValue + 1;
      break;
    case kAltoClef:
      finalValue = finalValue + 2;
      break;
    case kBassClef:
      finalValue = finalValue + 3;
      break;
    default:
      break;
  }
  
  return finalValue;
}

#pragma mark - helper methods

-(CGPoint)getStavesViewLocationForSelfViewLocation:(CGPoint)selfLocation {
  CGFloat xPosition, yPosition;
  if (kIsIPhone) {
    UIScrollView *scrollView = (UIScrollView *)self.containerView;
    xPosition = selfLocation.x + scrollView.contentOffset.x;
  } else {
    xPosition = selfLocation.x;
  }
  yPosition = selfLocation.y - self.stavesView.frame.origin.y;
  return CGPointMake(xPosition, yPosition);
}

#pragma mark - system methods

-(void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
}

@end
