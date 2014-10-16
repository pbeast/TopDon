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
        cord.longitude = [[object objectForKey:@"Longitude"] doubleValue];
        
        self.coordinate = cord;
        self.title = [object objectForKey:@"BusinessUnitName"];
        self.subtitle = [object objectForKey:@"Name"];
        
        id tmp = [object objectForKey:@"FuelTypes"];
        if ([tmp isKindOfClass:[NSArray class]])
            _FuelTypes = tmp;
        else
            _FuelTypes = nil;
        
        tmp = [object objectForKey:@"TechnicalServices"];
        if ([tmp isKindOfClass:[NSArray class]])
            _TechnicalServices = tmp;
        else
            _TechnicalServices = nil;
        
        tmp = [object objectForKey:@"AdditionalServices"];
        if ([tmp isKindOfClass:[NSArray class]])
            _AdditionalServices = tmp;
        else
            _AdditionalServices = nil;
        
        _promoText = [object objectForKey:@"Promo"];
        if (_promoText == nil)
            _promoText = @"";
    }
    
	return self;
}

@end
