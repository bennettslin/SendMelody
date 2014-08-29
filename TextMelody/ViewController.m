//
//  ViewController.m
//  TextMelody
//
//  Created by Bennett Lin on 8/29/14.
//  Copyright (c) 2014 Bennett Lin. All rights reserved.
//

#import "ViewController.h"
#import "Constants.h"
#import "StavesView.h"
#import "SymbolView.h"

@interface ViewController ()

@property (strong, nonatomic) UIScrollView *myScrollView;
@property (strong, nonatomic) StavesView *myStaves;
@property (strong, nonatomic) SymbolView *clef;
@property (strong, nonatomic) NSArray *keySigAccidentals;
@property (nonatomic) NSUInteger keySigIndex;

@end

@implementation ViewController
            
-(void)viewDidLoad {
  [super viewDidLoad];
  
  if (kIsIPhone) {
    self.myScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
    self.myScrollView.center = self.view.center;
    self.myScrollView.contentSize = CGSizeMake(kStaveWidth, self.view.bounds.size.height);
    [self.view addSubview:self.myScrollView];
  }
  
  UIView *containerView = kIsIPhone ? self.myScrollView : self.view;
  self.myStaves = [[StavesView alloc] initWithFrame:CGRectMake(0, 0, kStaveWidth, kContainerContentHeight)];
  self.myStaves.center = CGPointMake(kStaveWidth / 2, containerView.bounds.size.height / 2);
  self.myStaves.layer.borderColor = [UIColor redColor].CGColor;
  self.myStaves.layer.borderWidth = 2.f;

  [containerView addSubview:self.myStaves];
  
  self.clef = [[SymbolView alloc] initWithSymbol:kTrebleClef];
  CGRect clefFrame = CGRectMake(kStaveWidthMargin, kStaveHeight * 3.375, self.clef.frame.size.width, self.clef.frame.size.height);
  self.clef.frame = clefFrame;
  [containerView addSubview:self.clef];
  
  NSMutableArray *tempAccidentals = [NSMutableArray arrayWithCapacity:6];
  for (int i = 0; i < 6; i++) {
    SymbolView *accidental = [[SymbolView alloc] initWithSymbol:kSharp];
    [containerView addSubview:accidental];
    [tempAccidentals addObject:accidental];
  }
  self.keySigAccidentals = [NSArray arrayWithArray:tempAccidentals];
  self.keySigIndex = 5;
  [self updateKeySigLabel];
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
      accidental.frame = CGRectMake(kStaveWidthMargin + self.clef.frame.size.width + (i * accidental.frame.size.width), kStaveHeight * (factor / 2 - 0.625), accidental.frame.size.width, accidental.frame.size.height);
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

#pragma mark - system methods

-(void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

@end
