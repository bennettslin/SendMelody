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

  // might not be necessary to have its own symbol
@property (nonatomic) MusicSymbol mySymbol;

-(instancetype)initWithSymbol:(MusicSymbol)symbol;
-(void)modifyGivenSymbol:(MusicSymbol)symbol;

@end
