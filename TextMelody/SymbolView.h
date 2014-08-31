//
//  SymbolView.h
//  TextMelody
//
//  Created by Bennett Lin on 8/29/14.
//  Copyright (c) 2014 Bennett Lin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Constants.h"

@interface SymbolView : UILabel

@property (nonatomic) MusicSymbol mySymbol;
@property (nonatomic) CGPoint homePosition;
@property (nonatomic) BOOL onStaves;
//@property (nonatomic) BOOL touched;

-(instancetype)initWithSymbol:(MusicSymbol)symbol;
-(void)modifyGivenSymbol:(MusicSymbol)symbol;

-(void)beginTouch;
-(void)endTouch;

-(void)changeStemDirection;
-(void)sendHomeToRack;

-(void)showLedgerLine:(BOOL)show;

@end
