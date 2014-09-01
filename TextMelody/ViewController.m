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
#import <MessageUI/MessageUI.h>

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
  
  [self loadFixedViews];
  [self instantiateStuffOnStaves];
  [self repositionStuffOnStaves];
  [self instantiateNewNoteWithSymbol:kQuarterNoteStemUp];
  [self instantiateNewNoteWithSymbol:kHalfNoteStemUp];
  [self instantiateNewNoteWithSymbol:kWholeNote];

  [self instantiateMailButton];
  [self instantiateTextButton];

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

-(void)instantiateMailButton {
  self.mailButton = [[UIButton alloc] initWithFrame:CGRectMake(_screenWidth - 50, _screenHeight - 50, 50, 50)];
  self.mailButton.backgroundColor = [UIColor greenColor];
  [self.mailButton setTitle:@"mail" forState:UIControlStateNormal];
  [self.mailButton addTarget:self
                      action:@selector(mailButtonTapped)
            forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:self.mailButton];
}

-(void)instantiateTextButton {
  self.textButton = [[UIButton alloc] initWithFrame:CGRectMake(_screenWidth - 100, _screenHeight - 50, 50, 50)];
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
  
  CGFloat leftBuffer = self.clef.frame.size.width + _keySigWidth;
  CGFloat range = kStaveWidth - leftBuffer - self.endBarline.frame.size.width;
  
  CGFloat rangeSlot = range / (self.StuffOnStaves.count + 1);
  
  for (int i = 0; i < self.StuffOnStaves.count; i++) {
    
    SymbolView *symbol = self.StuffOnStaves[i];
    symbol.center = CGPointMake(leftBuffer + (i + 1) * rangeSlot, symbol.center.y);
    
    if (!symbol.superview) {
      [self.stavesView addSubview:symbol];
    }
  }
  
  
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
  if (self.tempStaveIndexForTouchedNote > 4 && self.tempStaveIndexForTouchedNote < 20) {
    
    CGPoint selfPoint;
    CGPoint stavesPoint;
    
      // already added to stavesView
    if ([self touchedNoteBelongsOnStaves]) {
      
      CGFloat buffer;
      if (kIsIPhone) {
        ContainerScrollView *containerScrollView = (ContainerScrollView *)self.containerView;
        buffer = containerScrollView.contentOffset.x;
      }
      
      selfPoint = CGPointMake(self.touchedNote.center.x - buffer,
                              [self stavePositionForStaveIndex:self.tempStaveIndexForTouchedNote]);
      stavesPoint = [self getStavesViewLocationForSelfLocation:selfPoint];
      
      
        // not yet added to stavesView
    } else {
      
      CGFloat buffer;
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
    if ([self touchedNoteBelongsOnStaves]) {
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
    [self changeTouchedNoteStemDirectionIfNecessary];
  }
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  if (self.touchedNote) {
    
    [self.touchedNote endTouch];
    
    if (self.touchedNoteMoved) {
      
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
  return ((staveIndex) * kStaveHeight / 2);
}

-(NSInteger)staveIndexForNoteCenter:(CGPoint)noteCenter {

  CGFloat yOrigin = 0;
  
  if ([self touchedNoteBelongsOnStaves]) {
    yOrigin = 0;
  } else {
    yOrigin = _screenHeight / 3 - self.stavesView.frame.size.height / 2;
  }
  
  CGFloat noteCenterRelativeToYOrigin = noteCenter.y - yOrigin;
  NSInteger staveIndex = ((noteCenterRelativeToYOrigin + kStaveHeight * .25f) / (kStaveHeight / 2.f));

    // establish whether to show ledger line here
  [self.touchedNote showLedgerLine:(staveIndex < 6 || staveIndex > 16)];
  
  return staveIndex;
}

-(CGPoint)getStavesViewLocationForSelfLocation:(CGPoint)selfLocation {
  
  CGFloat xPosition;
  
  if (kIsIPhone && [self touchedNoteBelongsOnStaves]) {
    UIScrollView *scrollView = (UIScrollView *)self.containerView;
    xPosition = selfLocation.x + scrollView.contentOffset.x;
  } else {
    xPosition = selfLocation.x;
  }

  return CGPointMake(xPosition, selfLocation.y);
}

#pragma mark - mail methods

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

#pragma mark - text methods

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

#pragma mark - image methods

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
