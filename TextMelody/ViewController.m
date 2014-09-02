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

@interface ViewController () <UIScrollViewDelegate, ContainerDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate>

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

@property (strong, nonatomic) UIButton *mailButton;
@property (strong, nonatomic) UIButton *textButton;

@property (strong, nonatomic) NSMutableDictionary *barlineXPositions;

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
  self.stavesView.center = CGPointMake(kStaveWidth / 2, _screenHeight / 3);
  
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
  self.keySigIndex = 11;
  [self updateKeySigLabel];
  
  self.endBarline = [[SymbolView alloc] initWithSymbol:kEndBarline];
  self.endBarline.center = CGPointMake(kStaveWidth - kStaveWidthMargin - self.endBarline.frame.size.width / 2, kStaveHeight * 7.5 + kStaveYAdjust);
  
    // only place to establish last barlineXPosition
  [self setXPosition:self.endBarline.center.x forKey:4];
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

-(void)instantiateStuffOnStaves {

  self.StuffOnStaves = [NSMutableArray new];
  
  for (int i = 0; i < 4; i++) {
    SymbolView *wholeRest = [[SymbolView alloc] initWithSymbol:kWholeNoteRest];
    wholeRest.center = CGPointMake(0, kStaveHeight * 5);
    [self.StuffOnStaves addObject:wholeRest];
    
    if (i < 3) {
      SymbolView *barline = [[SymbolView alloc] initWithSymbol:kBarline];
      barline.center = CGPointMake(0, kStaveHeight * 7.5);
      [self.StuffOnStaves addObject:barline];
    }
  }
}

-(void)repositionStuffOnStaves {
  
  NSUInteger unhiddenCount = [self countOfUnhiddenStuffOnStaves];
  
  CGFloat leftBuffer = [self getXPositionForKey:0];
  CGFloat range = kStaveWidth - leftBuffer - self.endBarline.frame.size.width / 2 - kStaveWidthMargin; // only half of endBarline width is wider than it seems
  
  CGFloat rangeSlot = range / (unhiddenCount + 1);
  NSUInteger currentBarline = 1;
  
  NSUInteger unhiddenCounter = 0;
  for (int i = 0; i < self.StuffOnStaves.count; i++) {
    
    SymbolView *symbol = self.StuffOnStaves[i];
    if (!symbol.hidden) {
  
      symbol.center = CGPointMake(leftBuffer + (unhiddenCounter + 1) * rangeSlot, symbol.center.y);
      
      if (!symbol.superview) {
        [self.stavesView addSubview:symbol];
      }
      
      if (symbol.mySymbol == kBarline) {
        [self setXPosition:symbol.center.x forKey:currentBarline];
        currentBarline++;
      }
      
      unhiddenCounter++;
    }
  }
}

#pragma mark - touch methods

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  
  CGPoint touchPoint = [[touches anyObject] locationInView:self.view];
  UIView *touchedView = [self.view hitTest:touchPoint withEvent:event];
  
  if ([touchedView.superview isKindOfClass:SymbolView.class]) {
    if (!self.touchedNote) {
      self.touchedNote = (SymbolView *)touchedView.superview;
      [self.touchedNote beginTouch];
      
        // center to account for touch offset
      CGPoint realPoint = [self getStavesViewLocationForSelfLocation:touchPoint];
      self.touchOffset = CGVectorMake(self.touchedNote.center.x - realPoint.x,
                                      self.touchedNote.center.y - realPoint.y);
    }
  }
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
  if (self.touchedNote) {
    self.touchedNoteMoved = YES;
    
      // recenter
    CGPoint touchPoint = [[touches anyObject] locationInView:self.view];
    CGPoint noteCenter = [self adjustForTouchOffsetLocationPoint:touchPoint];
    CGPoint realCenter = [self getStavesViewLocationForSelfLocation:noteCenter];
    self.touchedNote.center = realCenter;
    self.tempStaveIndexForTouchedNote = [self staveIndexForNoteCenter:realCenter];
    NSLog(@"staveIndex is %i", self.tempStaveIndexForTouchedNote);
    
          // change stem direction if necessary
    [self constrictStaveIndex];
    [self changeTouchedNoteStemDirectionIfNecessary];
    
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
  }
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  if (self.touchedNote) {
    
    [self.touchedNote endTouch];
    
    if (self.touchedNoteMoved) {
      
        // check whether to add to staves
      [self constrictStaveIndex];
      [self.touchedNote modifyLedgersGivenStaveIndex:self.tempStaveIndexForTouchedNote];
      
      [self decideWhetherToAddTouchedNoteToStaves];
      self.touchedNoteMoved = NO;
    }
    
    self.touchedNote = nil;
  }
  
  NSLog(@"barlineXPositions %@", self.barlineXPositions);
}

  // FIXME: a lot of these will be changed
#pragma mark - note to staves helper methods -----------------------------------

-(NSUInteger)countOfUnhiddenStuffOnStaves {
  NSUInteger count = 0;
  for (SymbolView *symbol in self.StuffOnStaves) {
    if (symbol.hidden == NO) {
      count++;
    }
  }
  return count;
}

-(NSUInteger)barForTouchedNote {
    // touched note is within staves yPosition
  if (self.tempStaveIndexForTouchedNote > 3 && self.tempStaveIndexForTouchedNote < 21) {
    CGFloat xPosition = self.touchedNote.center.x;
    for (NSUInteger index = 0; index < 4; index++) {
      if (xPosition > [self getXPositionForKey:index] && xPosition <= [self getXPositionForKey:index + 1]) {
        return index;
      }
    }
  }
  return NSUIntegerMax;
}

-(NSUInteger)sectionForTouchedNoteInBar:(NSUInteger)barNumber withElementCount:(NSUInteger)count {
  
  CGFloat leftBarlineXPosition = [self getXPositionForKey:barNumber];
  CGFloat rightBarlineXPosition = [self getXPositionForKey:barNumber + 1];
  CGFloat barLength = rightBarlineXPosition - leftBarlineXPosition;
  CGFloat barSectionLength = barLength / count;
  
  CGFloat touchedNoteXPositionWithinBar = self.touchedNote.center.x - leftBarlineXPosition;
  
  NSUInteger section = (NSUInteger)(touchedNoteXPositionWithinBar / barSectionLength);
  NSLog(@"note is in section %i", section);
  return section;
}

-(void)setXPosition:(CGFloat)xPosition forKey:(NSUInteger)key {
  if (key <= 4) {
    [self.barlineXPositions removeObjectForKey:@(key)];
    [self.barlineXPositions setObject:@(xPosition) forKey:@(key)];
  }
}

-(CGFloat)getXPositionForKey:(NSUInteger)key {
  if (key <= 4) {
    return [[self.barlineXPositions objectForKey:@(key)] floatValue];
  } else {
    return CGFLOAT_MAX;
  }
}

-(NSArray *)getElementsInBar:(NSUInteger)barNumber {
  
  NSMutableArray *tempElementsInBar = [NSMutableArray new];
  
  NSUInteger currentBarline = 0;
  for (int i = 0; i < self.StuffOnStaves.count; i++) {
    SymbolView *symbol = self.StuffOnStaves[i];
    
    if (symbol.mySymbol == kBarline) {
      currentBarline++;
    }
    
    if (currentBarline == barNumber) {
      if (symbol.mySymbol != kBarline) {
        [tempElementsInBar addObject:symbol];
      }
    }
  }
  
  NSLog(@"element count %i in bar %i", tempElementsInBar.count, barNumber);
  return [NSArray arrayWithArray:tempElementsInBar];
}

-(void)hideOrShowElements:(NSArray *)elements hide:(BOOL)hide {
  for (SymbolView *symbol in elements) {
    symbol.hidden = hide;
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
  
    // only place to establish first barlineXPosition
  [self setXPosition:(kStaveWidthMargin + self.clef.frame.size.width + _keySigWidth) forKey:0];
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
  
  newNote.homePosition = CGPointMake(xPosition, _screenHeight * 3/4);
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
  if (self.tempStaveIndexForTouchedNote >= 0 && self.tempStaveIndexForTouchedNote < 4) {
    self.tempStaveIndexForTouchedNote = 4;
  } else if (self.tempStaveIndexForTouchedNote <= 24 && self.tempStaveIndexForTouchedNote > 20) {
    self.tempStaveIndexForTouchedNote = 20;
  }
}

-(BOOL)decideWhetherToAddTouchedNoteToStaves {
  
    // note is within staves
  if ([self barForTouchedNote] != NSUIntegerMax) {
    
    CGPoint selfPoint;
    CGPoint stavesPoint;
    
      // already added to stavesView
    if ([self touchedNoteWasAlreadyPlacedOnStaves]) {
      
      CGFloat buffer = 0;
      if (kIsIPhone) {
        ContainerScrollView *containerScrollView = (ContainerScrollView *)self.containerView;
        buffer = containerScrollView.contentOffset.x;
      }
      
      selfPoint = CGPointMake(self.touchedNote.center.x - buffer,
                              [self stavePositionForStaveIndex:self.tempStaveIndexForTouchedNote]);
      stavesPoint = [self getStavesViewLocationForSelfLocation:selfPoint];
      
        // not yet added to stavesView
    } else {
      
      CGFloat buffer = 0;
      if (kIsIPhone) {
        ContainerScrollView *containerScrollView = (ContainerScrollView *)self.containerView;
        buffer = containerScrollView.contentOffset.x;
      }
      
      selfPoint = CGPointMake(self.touchedNote.center.x + buffer,
                              [self stavePositionForStaveIndex:self.tempStaveIndexForTouchedNote]);
      stavesPoint = [self getStavesViewLocationForSelfLocation:selfPoint];
      
      self.touchedNote.homePosition = CGPointMake(CGFLOAT_MAX, CGFLOAT_MAX);
      
        // add touched note to array
      [self.StuffOnStaves addObject:self.touchedNote];
      
        // generate new note for self.view
      [self instantiateNewNoteWithSymbol:self.touchedNote.mySymbol];
    }
    
    self.touchedNote.center = stavesPoint;
    [self.stavesView addSubview:self.touchedNote];
    
    return YES;
    
      // note is not within staves
  } else {
    
      // if note already belongs on staves, discard
    if ([self touchedNoteWasAlreadyPlacedOnStaves]) {
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

-(void)changeTouchedNoteStemDirectionIfNecessary {
  
  if ((self.tempStaveIndexForTouchedNote < 13 &&
       (self.touchedNote.mySymbol == kQuarterNoteStemUp || self.touchedNote.mySymbol == kHalfNoteStemUp)) ||
      (self.tempStaveIndexForTouchedNote >= 13 &&
       (self.touchedNote.mySymbol == kQuarterNoteStemDown || self.touchedNote.mySymbol == kHalfNoteStemDown))) {
        
        [self.touchedNote changeStemDirection];
      }
}

#pragma mark - touched note helper methods -------------------------------------

-(BOOL)touchedNoteWasAlreadyPlacedOnStaves {
  return (CGPointEqualToPoint(self.touchedNote.homePosition, CGPointMake(CGFLOAT_MAX, CGFLOAT_MAX)));
}

-(CGFloat)stavePositionForStaveIndex:(NSUInteger)staveIndex {
  return ((staveIndex) * kStaveHeight / 2);
}

-(NSInteger)staveIndexForNoteCenter:(CGPoint)noteCenter {

  CGFloat yOrigin = 0;
  
  if ([self touchedNoteWasAlreadyPlacedOnStaves]) {
    yOrigin = 0;
  } else {
    yOrigin = _screenHeight / 3 - self.stavesView.frame.size.height / 2;
  }
  
  CGFloat noteCenterRelativeToYOrigin = noteCenter.y - yOrigin;
  NSInteger staveIndex = ((noteCenterRelativeToYOrigin + kStaveHeight * .25f) / (kStaveHeight / 2.f));

    // establish whether to show ledger line here
  [self.touchedNote modifyLedgersGivenStaveIndex:staveIndex];
  return staveIndex;
}

-(CGPoint)getStavesViewLocationForSelfLocation:(CGPoint)selfLocation {
  
  CGFloat xPosition;
  
  if (kIsIPhone && [self touchedNoteWasAlreadyPlacedOnStaves]) {
    UIScrollView *scrollView = (UIScrollView *)self.containerView;
    xPosition = selfLocation.x + scrollView.contentOffset.x;
  } else {
    xPosition = selfLocation.x;
  }

  return CGPointMake(xPosition, selfLocation.y);
}

#pragma mark - mail and text methods -------------------------------------------

-(void)mailButtonTapped {
  
  if ([MFMailComposeViewController canSendMail]) {
    MFMailComposeViewController *mailVC = [[MFMailComposeViewController alloc] init];
    mailVC.mailComposeDelegate = self;
    
    [mailVC setSubject:@"Sending you a melody"];
    [mailVC setMessageBody:@"Hi!" isHTML:NO];
    
      // Add attachment
    NSData *imageData = [self generatePNGDataFromStavesView];
    [mailVC addAttachmentData:imageData mimeType:@"image/png" fileName:@"melody"];
    
    [self presentViewController:mailVC animated:YES completion:NULL];
    
  } else {
    [self showCantSendMailAlert];
  }
}

-(void) mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
  
  switch (result) {
    case MFMailComposeResultCancelled:
    NSLog(@"Mail cancelled");
    break;
    case MFMailComposeResultSaved:
    NSLog(@"Mail saved");
    break;
    case MFMailComposeResultSent:
    NSLog(@"Mail sent");
    break;
    case MFMailComposeResultFailed:
    NSLog(@"Mail sent failure: %@", [error localizedDescription]);
    break;
    default:
    break;
  }
  
    // Close the Mail Interface
  [self dismissViewControllerAnimated:YES completion:NULL];
}

-(void)showCantSendMailAlert {
  
}

-(void)textButtonTapped {
  if([MFMessageComposeViewController canSendText]) {
    
    MFMessageComposeViewController *textVC = [[MFMessageComposeViewController alloc] init];
    textVC.messageComposeDelegate = self;
    
      // include subject if possible
//    [MFMessageComposeViewController canSendSubject] ?
//        [textVC setSubject:@"Sending you a melody"] : nil;
    
      // attach image if possible
    if ([MFMessageComposeViewController canSendAttachments] &&
        [MFMessageComposeViewController isSupportedAttachmentUTI:@"public.data"]) {
      
      NSData *imageData = [self generatePNGDataFromStavesView];
      [textVC addAttachmentData:imageData typeIdentifier:@"public.data" filename:@"melody.png"];
    }
    
    [textVC setBody:@"melodySent://badaboop/bing/bang/boom"];
    
      // Present message view controller on screen
    [self presentViewController:textVC animated:YES completion:nil];
    
  } else {
    [self showCantSendTextAlert];
  }
}

-(void)messageComposeViewController:(MFMessageComposeViewController *)controller
                didFinishWithResult:(MessageComposeResult)result {
  switch (result) {
    case MessageComposeResultCancelled:
      NSLog(@"Text message cancelled");
      break;
      
    case MessageComposeResultFailed:
    {
    UIAlertView *warningAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Failed to send SMS!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [warningAlert show];
    break;
    }
      
    case MessageComposeResultSent:
      NSLog(@"Text message sent");
      break;
      
    default:
      break;
  }
  
  [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)showCantSendTextAlert {
  UIAlertView *warningAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Your device doesn't support SMS!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
  [warningAlert show];
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
    NSLog(@"error %@", error);
  } else {
    NSLog(@"no error");
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
