//
//  GasStation.m
//  TopDon
//
//  Created by Pavel Yankelevich on 10/4/14.
//  Copyright (c) 2014 Pavel Yankelevich. All rights reserved.
//

#import "GasStation.h"

@implementation GasStation


-(id)initWithServerObject:(NSDictionary*)object
{
	self = [super init];
	if (self != nil) {
        CLLocationCoordinate2D cord;
        cord.latitude = [[object objectForKey:@"Latitude"] doubleValue];
        cord.latitude = [[object objectForKey:@"Longitude"] doubleValue];
        
        self.coordinate = cord;
        self.title = [[object objectForKey:@"BusinessUnitName"] string];
    }
    
	return self;
}

@end
