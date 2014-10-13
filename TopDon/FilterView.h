//
//  FilterView.h
//  TopDon
//
//  Created by Pavel Yankelevich on 9/30/14.
//  Copyright (c) 2014 Pavel Yankelevich. All rights reserved.
//

#import "PullableView.h"

@protocol FilterViewDelegate<NSObject>

-(void)shouldShow:(BOOL)show fuelWithId:(int)fuelId;
-(void)shouldShow:(BOOL)show serviceWithId:(int)serviceId;
-(void)shouldShow:(BOOL)show extServiceWithId:(int)extServiceId;

@end

@interface FilterView : PullableView
{
    
}

@property (readwrite,assign) id<FilterViewDelegate> filterDelegate;

- (IBAction)fuelTagged:(id)sender;
- (IBAction)serviceTagged:(id)sender;
- (IBAction)additionalServiceTagged:(id)sender;



@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray *fuelButtons;
@end
