//
//  GasStation.h
//  TopDon
//
//  Created by Pavel Yankelevich on 10/4/14.
//  Copyright (c) 2014 Pavel Yankelevich. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface GasStation : MKPointAnnotation

-(id)initWithServerObject:(NSDictionary*)object;

@property (assign, readonly) NSArray* FuelTypes;
@property (assign, readonly) NSArray* TechnicalServices;
@property (assign, readonly) NSArray* AdditionalServices;

@end
