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
#import "MBProgressHUD.h"

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

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
    
    BOOL geoLocationIsWorking;
}
@end

@implementation ViewController

- (void)showFilterView
{
    if (pullRightView != nil)
        return;
    
    float panelHeight = 350;
    float verticalOffset = self.mapView.frame.origin.y / 2;
    float  h = self.view.bounds.size.height;
    
    pullRightView = [[[NSBundle mainBundle] loadNibNamed:@"FilterView" owner:self options:nil] objectAtIndex:0];
    //    pullRightView.backgroundColor = [UIColor darkGrayColor];
    pullRightView.openedCenter = CGPointMake(self.view.bounds.size.width - 85, verticalOffset + h / 2.0);
    pullRightView.closedCenter = CGPointMake(self.view.bounds.size.width + 85, verticalOffset + h / 2.0);
    pullRightView.center = pullRightView.closedCenter;
    pullRightView.animate = YES;
    pullRightView.toggleOnTap = YES;
    
//    pullRightView.layer.cornerRadius = 6;
    
    pullRightView.handleView.backgroundColor = [UIColor clearColor];
    pullRightView.handleView.frame = CGRectMake(0, panelHeight / 2 - 25, 15, 50);
    
    pullRightView.delegate = self;
    pullRightView.filterDelegate = self;
    
    [self.view addSubview:pullRightView];
}

- (BOOL)locationServicesAvailable
{
    if ([CLLocationManager locationServicesEnabled] == NO) {
        return NO;
    } else if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
        return NO;
    } else if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted) {
        return NO;
    }
    return YES;
}

- (void)showGeoservicesRequiredAlert
{
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"TOPDON" message:@"Для корректной работы требуется разрешить использования сервисов геолокации. Включить службы геолокации можно в меню «Настройки» > «Приватность» > «Службы геолокации»." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [av show];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    allowedFuels = [NSMutableArray array];
    allowedServices = [NSMutableArray array];
    allowedExtServices = [NSMutableArray array];
    
    pullRightView = nil;


    currentLocation = [[CLLocation alloc] initWithLatitude:0 longitude:0];

    
    if (![self locationServicesAvailable])
    {
        [self showGeoservicesRequiredAlert];
        geoLocationIsWorking = NO;
        
        return;
    }
    
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;

    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0"))
    {
        geoLocationIsWorking = NO;
        [locationManager requestWhenInUseAuthorization];
    }
    else{
        geoLocationIsWorking = YES;
        [locationManager startUpdatingLocation];
    }
  
    tapRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longTapOnMap:)];
    tapRecognizer.minimumPressDuration = 0.75;
    [self.mapView addGestureRecognizer:tapRecognizer];
    
//    ZCSHoldProgress *holdProgress = [[ZCSHoldProgress alloc] initWithTarget:self action:@selector(gestureRecogizerTarget:)];
//    holdProgress.minimumPressDuration = 1.0;
//    holdProgress.size = 100;
//    holdProgress.minimumSize = 20;
//    holdProgress.borderSize = 2;
//    [self.mapView addGestureRecognizer:holdProgress];
    
//    UILabel *label = [UILabel new];
//    label.text = @"To be, or not to be: that is the question: Whether 'tis nobler in the mind to suffer...";
//    [label sizeToFit];
//    
//    [label setBackgroundColor:[UIColor greenColor]];
//    [[self marqueeView] setViewToScroll:label];
//    
//    [[self marqueeView] beginScrolling];
    
    [[self newsLine] setMarqueeType:MLContinuous];
    [[self newsLine] setBackgroundColor:[UIColor blackColor]];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.navigationController.navigationBarHidden = YES;
}

-(void)checkLocationMonitoring
{
//    if (!geoLocationIsWorking){
//        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")){
//            geoLocationIsWorking = NO;
//            [locationManager requestWhenInUseAuthorization];
//        }
//        else{
//            geoLocationIsWorking = YES;
//            [locationManager startUpdatingLocation];
//        }
//    }
}

-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse || status == kCLAuthorizationStatusAuthorizedAlways)
    {
        geoLocationIsWorking = YES;

        [locationManager startUpdatingLocation];
    }
    else if (kCLAuthorizationStatusDenied == status){
        geoLocationIsWorking = NO;

        [self showGeoservicesRequiredAlert];
    }
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

-(void)longTapOnMap:(UIGestureRecognizer *)recognizer
{
    if (recognizer.state != UIGestureRecognizerStateBegan)
    {
        return;
    }
    
    CGPoint point = [recognizer locationInView:self.mapView];
    
    CLLocationCoordinate2D tapPoint = [self.mapView convertPoint:point toCoordinateFromView:self.mapView];
    
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
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if (![[segue destinationViewController] isKindOfClass:[FuelStationViewController class]])
        return;
    
    FuelStationViewController *fsvc = [segue destinationViewController];
    GasStation * gasStation = sender;
    
    [fsvc setTitle:gasStation.title];
    [fsvc setGasStation:sender];
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
    
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.labelText = @"Идет поиск...";
    
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    
    [geocoder geocodeAddressString:[textField text]
                 completionHandler:^(NSArray* placemarks, NSError* error){
                     
                     [MBProgressHUD hideHUDForView:self.view animated:YES];
                     
                     if ([placemarks count] > 0)
                     {
                         CLPlacemark* aPlacemark = [placemarks objectAtIndex:0];
                         [self loadStationsAround:[aPlacemark location]];
                     }
                     else
                     {
                         UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"TOPDON" message:[NSString stringWithFormat:@"%@ не найденно", [textField text]] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                         [av show];
                     }
//                     for (CLPlacemark* aPlacemark in placemarks)
//                     {
//                         
//                     }
                 }];
    
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
        
        if ([allowedFuels count] > 0){
            BOOL found = YES;
            for (NSNumber *fuelId in allowedFuels) {
                NSUInteger idx = [[gasStation FuelTypes] indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                    
                    *stop = [[obj objectForKey:@"Id"] integerValue] == [fuelId integerValue];
                    
                    return *stop;
                }];
                
                found &= (idx != NSNotFound);
            }
            
            if (!found)
                continue;
        }
        
        if ([allowedServices count] > 0){
            BOOL found = YES;
            for (NSNumber *serviceId in allowedServices) {
                NSUInteger idx = [[gasStation TechnicalServices] indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                    
                    *stop = [[obj objectForKey:@"Id"] integerValue] == [serviceId integerValue];
                    
                    return *stop;
                }];
                
                found &= (idx != NSNotFound);
            }
            
            if (!found)
                continue;
        }
        
        if ([allowedExtServices count] > 0){
            BOOL found = YES;
            for (NSNumber *extServiceId in allowedExtServices) {
                NSUInteger idx = [[gasStation AdditionalServices] indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                    
                    *stop = [[obj objectForKey:@"Id"] integerValue] == [extServiceId integerValue];
                    
                    return *stop;
                }];
                
                found &= (idx != NSNotFound);
            }
            
            if (!found)
                continue;
        }

        [self.mapView addAnnotation:gasStation];
    }
}

-(void)shouldShow:(BOOL)show fuelWithId:(long)fuelId
{
    if (show)
        [allowedFuels addObject:[NSNumber numberWithLong:fuelId]];
    else
    {
        NSUInteger index = [allowedFuels indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            *stop = [obj intValue] == fuelId;
            
            return *stop;
        }];
        
        if (index != NSNotFound)
            [allowedFuels removeObjectAtIndex:index];
    }
    
    [self updatesStationsOnMap];
}

-(void)shouldShow:(BOOL)show serviceWithId:(long)serviceId{
    if (show)
        [allowedServices addObject:[NSNumber numberWithLong:serviceId]];
    else
    {
        NSUInteger index = [allowedServices indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            *stop = [obj intValue] == serviceId;
            
            return *stop;
        }];
        
        if (index != NSNotFound)
            [allowedServices removeObjectAtIndex:index];
    }
    
    [self updatesStationsOnMap];
}

-(void)shouldShow:(BOOL)show extServiceWithId:(long)extServiceId{
    if (show)
        [allowedExtServices addObject:[NSNumber numberWithLong:extServiceId]];
    else
    {
        NSUInteger index = [allowedExtServices indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            *stop = [obj intValue] == extServiceId;
            
            return *stop;
        }];
        
        if (index != NSNotFound)
            [allowedExtServices removeObjectAtIndex:index];
    }
    
    [self updatesStationsOnMap];
}

@end
