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

@property (nonatomic, readonly) MusicSymbol mySymbol;
@property (nonatomic, readonly) NSUInteger noteDuration;
@property (nonatomic) NSInteger staveIndex;

@property (nonatomic) CGPoint homePosition;
@property (nonatomic) BOOL onStaves;

-(instancetype)initWithSymbol:(MusicSymbol)symbol;
-(void)modifyGivenSymbol:(MusicSymbol)symbol;
-(void)centerThisSymbol;

-(void)beginTouch;
-(void)endTouch;

-(void)changeStemDirectionIfNecessary;
-(void)sendHomeToRack;

-(void)modifyLedgersGivenStaveIndex;



@end
