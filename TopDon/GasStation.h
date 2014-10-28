//
//  GasStation.h
//  TopDon
//
//  Created by Pavel Yankelevich on 10/4/14.
//  Copyright (c) 2014 Pavel Yankelevich. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface GasStation : MKPointAnnotation

-(id)initWithServerObject:(NSDictionary*)object andBaseLogoUrl:(NSString*)baseLogoUrl;

@property (copy, readonly) NSArray* FuelTypes;
@property (copy, readonly) NSArray* TechnicalServices;
@property (copy, readonly) NSArray* AdditionalServices;
@property (copy, readonly) NSString* promoText;

@property (copy, readonly) NSString* city;
@property (copy, readonly) NSString* street;
@property (copy, readonly) NSString* houseNumber;

@property (copy, readonly) NSString* brandImage;

@property (readonly) int BusinessUnitInternalKey;

@end
