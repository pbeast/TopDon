//
//  FuelStationViewController.h
//  TopDon
//
//  Created by Pavel Yankelevich on 10/2/14.
//  Copyright (c) 2014 Pavel Yankelevich. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GasStation.h"
@interface FuelStationViewController : UITableViewController<MKMapViewDelegate, UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate>

@property (assign, nonatomic) GasStation* gasStation;

@property (weak, nonatomic) IBOutlet MKMapView *stationMapView;

- (IBAction)navigateToStation:(id)sender;
@end
