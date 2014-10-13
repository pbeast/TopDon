//
//  ViewController.m
//  TopDon
//
//  Created by Pavel Yankelevich on 9/28/14.
//  Copyright (c) 2014 Pavel Yankelevich. All rights reserved.
//

#import "ViewController.h"
#import "GasStation.h"
#import "FuelStationViewController.h"
#import "AFNetworking.h"
#import "ZCSHoldProgress.h"

@interface ViewController ()
{
    FilterView* pullRightView;
    CLLocationManager *locationManager;
    CLLocation *currentLocation;
    NSArray* foundGasStations;
    
    UILongPressGestureRecognizer *tapRecognizer;
    CGPoint longTapPoint;
    
    NSMutableArray* allowedFuels;
    NSMutableArray* allowedServices;
    NSMutableArray* allowedExtServices;
}
@end

@implementation ViewController

- (void)showFilterView
{
    if (pullRightView != nil)
        return;
    
    //    float panelWidth = 200;
    //    
    //    float w = self.view.bounds.size.width;
    float panelHeight = 350;
    float verticalOffset = self.mapView.frame.origin.y / 2;
    float  h = self.view.bounds.size.height;
    
    //    pullRightView = [[PullableView alloc] initWithFrame:CGRectMake(w, verticalOffset + h / 2.0 - panelHeight / 2.0, panelWidth, panelHeight)];
    
    pullRightView = [[[NSBundle mainBundle] loadNibNamed:@"FilterView" owner:self options:nil] objectAtIndex:0];
    //    pullRightView.backgroundColor = [UIColor darkGrayColor];
    pullRightView.openedCenter = CGPointMake(self.view.bounds.size.width - 85, verticalOffset + h / 2.0);
    pullRightView.closedCenter = CGPointMake(self.view.bounds.size.width + 85, verticalOffset + h / 2.0);
    pullRightView.center = pullRightView.closedCenter;
    pullRightView.animate = YES;
    pullRightView.toggleOnTap = YES;
    
    pullRightView.layer.cornerRadius = 6;
    
    pullRightView.handleView.backgroundColor = [UIColor clearColor];
    pullRightView.handleView.frame = CGRectMake(0, panelHeight / 2 - 25, 15, 50);
    
    pullRightView.delegate = self;
    pullRightView.filterDelegate = self;
    
    [self.view addSubview:pullRightView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    allowedFuels = [NSMutableArray array];
    allowedServices = [NSMutableArray array];
    allowedExtServices = [NSMutableArray array];
    
    pullRightView = nil;
    

    
    locationManager = [[CLLocationManager alloc] init];
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    locationManager.delegate = self;
    [locationManager startUpdatingLocation];
        
    currentLocation = [[CLLocation alloc] initWithLatitude:0 longitude:0];
  
    tapRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(foundTap:)];
//    tapRecognizer.numberOfTapsRequired = 1;
//    tapRecognizer.numberOfTouchesRequired = 1;
    tapRecognizer.minimumPressDuration = 0.75;
    [self.mapView addGestureRecognizer:tapRecognizer];
    
//    ZCSHoldProgress *holdProgress = [[ZCSHoldProgress alloc] initWithTarget:self action:@selector(gestureRecogizerTarget:)];
//    holdProgress.minimumPressDuration = 1.0;
//    holdProgress.size = 100;
//    holdProgress.minimumSize = 20;
//    holdProgress.borderSize = 2;
//    [self.mapView addGestureRecognizer:holdProgress];
}

- (void)gestureRecogizerTarget:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        CGPoint point = [gestureRecognizer locationInView:self.mapView];
        
        CLLocationCoordinate2D tapPoint = [self.mapView convertPoint:point toCoordinateFromView:self.mapView];
        
        [self.mapView setCenterCoordinate:tapPoint];
//        MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(tapPoint, 1000, 1000);
//        [self.mapView setRegion:region animated:YES];
        
        GasStation *gasStation = [[GasStation alloc] init];
        gasStation.coordinate = tapPoint;
        gasStation.title = [NSString stringWithFormat:@"Донбайнефтегаз ООО"];
        //gasStation.subtitle = @"ТОП ДОН";
        
        [self.mapView addAnnotation:gasStation];


        
        [self loadStationsAround:[[CLLocation alloc] initWithLatitude:tapPoint.latitude longitude:tapPoint.longitude]];
    }
    else if (gestureRecognizer.state == UIGestureRecognizerStatePossible) {
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *) event
{
    UITouch *touch = [[event allTouches] anyObject];
    if ([self.searchField isFirstResponder] && (self.searchField != touch.view))
    {
        [self.searchField resignFirstResponder];
    }
    
    longTapPoint = CGPointZero;
	for (UIGestureRecognizer *recognizer in touch.gestureRecognizers) {
		if ([recognizer isKindOfClass:[ZCSHoldProgress class]]) {
            longTapPoint = [touch locationInView:recognizer.view];
			break;
		}
	}
}

-(void)foundTap:(UIGestureRecognizer *)recognizer
{
    if (recognizer.state != UIGestureRecognizerStateBegan)
    {
        return;
    }
    
    CGPoint point = [recognizer locationInView:self.mapView];
    
    CLLocationCoordinate2D tapPoint = [self.mapView convertPoint:point toCoordinateFromView:self.mapView];
    
//    GasStation *gasStation = [[GasStation alloc] init];
//    gasStation.coordinate = tapPoint;
//    gasStation.title = [NSString stringWithFormat:@"Донбайнефтегаз ООО"];
//    //gasStation.subtitle = @"ТОП ДОН";
//    
//    [self.mapView addAnnotation:gasStation];
    
    
    [self loadStationsAround:[[CLLocation alloc] initWithLatitude:tapPoint.latitude longitude:tapPoint.longitude]];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    static NSString *identifier = @"GasStation";
    if ([annotation isKindOfClass:[GasStation class]]) {
        
        MKAnnotationView *annotationView = (MKAnnotationView *) [_mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
        if (annotationView == nil) {
            annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
            annotationView.enabled = YES;
            annotationView.canShowCallout = YES;
            annotationView.image = [UIImage imageNamed:@"fuelPin.png"];
            annotationView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];

        } else {
            annotationView.annotation = annotation;
        }
        
        return annotationView;
    }
    
    return nil;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    GasStation *gasStation = (GasStation*)view.annotation;
    [self performSegueWithIdentifier:@"fuelStationSegue" sender:gasStation];

//    NSDictionary *launchOptions = @{MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeD};
//    [location.mapItem openInMapsWithLaunchOptions:launchOptions];
}

-(void)viewWillAppear:(BOOL)animated
{
    self.navigationController.navigationBarHidden = YES;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    FuelStationViewController *fsvc = [segue destinationViewController];
    GasStation * gasStation = sender;
    
    [fsvc setTitle:gasStation.title];
    [fsvc setGasStation:sender];
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *newLocation = [locations objectAtIndex:0];
    
    if ([currentLocation distanceFromLocation:newLocation]>100){
        
        currentLocation = newLocation;
        [self centerMap:self];
        
        [self.centerMapBtn setHidden:NO];

        [self showFilterView];

    }
    
}

-(void)pullableView:(PullableView *)pView didChangeState:(BOOL)opened{
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.searchField resignFirstResponder];
    
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"" message:[textField text] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    
    [av show];
    
    return NO;
}

- (IBAction)centerMap:(id)sender {
    [self.mapView setCenterCoordinate:currentLocation.coordinate];
    MKCoordinateRegion region =
    MKCoordinateRegionMakeWithDistance(currentLocation.coordinate, 1000, 1000);
    [self.mapView setRegion:region animated:YES];
    
    [self loadStationsAround:currentLocation];
}

-(void)loadStationsAround:(CLLocation *)location
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    NSString* serverUrl = @"http://80.254.99.158/API/TradePointMaintanance.asmx/LocateAround";
    
    NSDictionary *parameters = @{
                                 @"longitude" : [NSString stringWithFormat:@"%f", location.coordinate.longitude],
                                 @"latitude" : [NSString stringWithFormat:@"%f", location.coordinate.latitude]
                                 };

    NSMutableURLRequest *request = [[AFJSONRequestSerializer serializer] requestWithMethod:@"POST" URLString:serverUrl parameters:parameters error:nil];
    
    AFHTTPRequestOperation *operation = [manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject)
                                         {
                                             NSDictionary* tmp = [((NSDictionary*)responseObject) objectForKey:@"d"];
                                             
                                             if ([tmp objectForKey:@"status"] == 0)
                                             {
                                                 tmp = [tmp objectForKey:@"Data"];
                                                 foundGasStations = [tmp objectForKey:@"TradePoints"];

                                                 [self updatesStationsOnMap];
                                                 
                                                 int radius = [[tmp objectForKey:@"Radius"] intValue];
                                                 MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(location.coordinate, radius, radius);
                                                 [self.mapView setRegion:region animated:YES];
                                             }
                                         }
                                        failure:^(AFHTTPRequestOperation *operation, NSError *error)
                                         {
                                             NSLog(@"Error: %@", error);
                                             NSLog(@"Response: %@", operation.responseString);
                                             
                                             UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"TOPDON" message:[NSString stringWithFormat:@"%@", error] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                                             [av show];
                                         }];
    
    operation.responseSerializer = [AFJSONResponseSerializer serializer];
    
    [manager.operationQueue addOperation:operation];

}

-(void) updatesStationsOnMap
{
    for (MKPointAnnotation* annotation in _mapView.annotations) {
        if ([annotation isKindOfClass:[GasStation class]]) {
            [_mapView removeAnnotation:annotation];
        }
    }
    
    for (NSDictionary* fuelStation in foundGasStations) {
        GasStation *gasStation = [[GasStation alloc] initWithServerObject:fuelStation];
                
        [self.mapView addAnnotation:gasStation];
    }
}

-(void)shouldShow:(BOOL)show fuelWithId:(int)fuelId
{
    if (show)
        [allowedFuels addObject:[NSNumber numberWithInt:fuelId]];
    else
    {
        int index = [allowedFuels indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            *stop = [obj intValue] == fuelId;
            
            return *stop;
        }];
        
        if (index >= 0)
            [allowedFuels removeObjectAtIndex:index];
    }
    
    [self updatesStationsOnMap];
}

-(void)shouldShow:(BOOL)show serviceWithId:(int)serviceId{
    if (show)
        [allowedServices addObject:[NSNumber numberWithInt:serviceId]];
    else
    {
        int index = [allowedFuels indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            *stop = [obj intValue] == serviceId;
            
            return *stop;
        }];
        
        if (index >= 0)
            [allowedServices removeObjectAtIndex:index];
    }
    
    [self updatesStationsOnMap];
}

-(void)shouldShow:(BOOL)show extServiceWithId:(int)extServiceId{
    if (show)
        [allowedExtServices addObject:[NSNumber numberWithInt:extServiceId]];
    else
    {
        int index = [allowedExtServices indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            *stop = [obj intValue] == extServiceId;
            
            return *stop;
        }];
        
        if (index >= 0)
            [allowedExtServices removeObjectAtIndex:index];
    }
    
    [self updatesStationsOnMap];
}

@end
