//
//  GasStation.m
//  TopDon
//
//  Created by Pavel Yankelevich on 10/4/14.
//  Copyright (c) 2014 Pavel Yankelevich. All rights reserved.
//

#import "GasStation.h"


@interface GasStation()

@end

@implementation GasStation


-(id)initWithServerObject:(NSDictionary*)object BaseLogoUrl:(NSString*)baseLogoUrl AndBaseAppUrl:(NSString*)baseAppUrl
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
        
        _promoText = [self valueOrEmptyOf:[object objectForKey:@"Promo"]];
        
        _hasNews = ![_promoText isEqualToString:@""];
        
        NSString* newsSuffix = _hasNews ? @"-news" : @"";
        
        _city = [self valueOrEmptyOf:[object objectForKey:@"City"]];
        _street = [self valueOrEmptyOf:[object objectForKey:@"Street"]];
        _houseNumber = [self valueOrEmptyOf:[object objectForKey:@"HouseNumber"]];

        _brandImage = [self valueOrEmptyOf:[object objectForKey:@"BranImage"]];
        
        int scale = [[UIScreen mainScreen] scale];

        _brandImage = [NSString stringWithFormat:@"%@%@%@%@.png", baseLogoUrl, _brandImage, newsSuffix, scale == 1 ? @"" : [NSString stringWithFormat:@"@%dx", scale]];
        
        _BusinessUnitInternalKey = [[object objectForKey:@"BusinessUnitInternalKey"] intValue];
        
        _baseWebUrl = baseAppUrl;
    }
    
	return self;
}

-(NSString*) valueOrEmptyOf:(NSObject*)object
{
    if (object == nil || [object isKindOfClass:[NSNull class]])
        return @"";
    
    return (NSString*)object;
}

@end
