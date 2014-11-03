//
//  FuelStationViewController.h
//  TopDon
//
//  Created by Pavel Yankelevich on 10/2/14.
//  Copyright (c) 2014 Pavel Yankelevich. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GasStation.h"
#import "DWTagList.h"

@interface FuelStationViewController : UITableViewController<MKMapViewDelegate, UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate,UIWebViewDelegate>

@property (assign, nonatomic) GasStation* gasStation;

@property (weak, nonatomic) IBOutlet MKMapView *stationMapView;

- (IBAction)navigateToStation:(id)sender;
@property (weak, nonatomic) IBOutlet DWTagList *fuelTypesView;
@property (weak, nonatomic) IBOutlet DWTagList *servicesView;
@property (weak, nonatomic) IBOutlet DWTagList *additionalServices;

@property (weak, nonatomic) IBOutlet UIWebView *promo;
@property (weak, nonatomic) IBOutlet UILabel *street;
@property (weak, nonatomic) IBOutlet UILabel *city;
@end
