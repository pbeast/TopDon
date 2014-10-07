//
//  FilterView.m
//  TopDon
//
//  Created by Pavel Yankelevich on 9/30/14.
//  Copyright (c) 2014 Pavel Yankelevich. All rights reserved.
//

#import "FilterView.h"

@implementation FilterView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if (self) {
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (IBAction)fuelTagged:(id)sender {
    
    UIButton* btn = sender;
    BOOL shouldShow = ![btn isSelected];
    [btn setSelected:shouldShow];
    
    if (_filterDelegate != nil)
        [_filterDelegate shouldShow:shouldShow fuelWithId:[btn tag]];
}

- (IBAction)serviceTagged:(id)sender {
    UIButton* btn = sender;
    BOOL shouldShow = ![btn isSelected];
    [btn setSelected:shouldShow];
    
    if (_filterDelegate != nil)
        [_filterDelegate shouldShow:shouldShow serviceWithId:[btn tag]];
}

- (IBAction)additionalServiceTagged:(id)sender {
    UIButton* btn = sender;
    BOOL shouldShow = ![btn isSelected];
    [btn setSelected:shouldShow];
    
    if (_filterDelegate != nil)
        [_filterDelegate shouldShow:shouldShow extServiceWithId:[btn tag]];
}
@end
