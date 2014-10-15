//
//  ViewController.h
//  TopDon
//
//  Created by Pavel Yankelevich on 9/28/14.
//  Copyright (c) 2014 Pavel Yankelevich. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FilterView.h"
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "MarqueeLabel.h"

@interface ViewController : UIViewController<PullableViewDelegate, MKMapViewDelegate, CLLocationManagerDelegate, FilterViewDelegate>


-(void)checkLocationMonitoring;

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
- (IBAction)centerMap:(id)sender;
@property (weak, nonatomic) IBOutlet UITextField *searchField;
@property (weak, nonatomic) IBOutlet UIButton *centerMapBtn;

@property (weak, nonatomic) IBOutlet MarqueeLabel *newsLine;
@end
