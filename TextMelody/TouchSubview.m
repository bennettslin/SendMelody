//
//  TouchSubview.m
//  SendMelody
//
//  Created by Bennett Lin on 8/30/14.
//  Copyright (c) 2014 Bennett Lin. All rights reserved.
//

#import "TouchSubview.h"

@implementation TouchSubview

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
      self.userInteractionEnabled = YES;
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
