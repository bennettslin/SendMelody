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

@end
