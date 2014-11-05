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
#import "MBProgressHUD.h"
#import "MKAnnotationView+WebCache.h"

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

#define LOCATION_UPDATE_THRESHOLD   1000

@interface ViewController ()
{
    FilterView* pullRightView;
    CLLocationManager *locationManager;
    CLLocation *currentLocation;
    NSMutableArray* foundGasStations;
    
    UILongPressGestureRecognizer *tapRecognizer;
    CGPoint longTapPoint;
    
    NSMutableArray* allowedFuels;
    NSMutableArray* allowedServices;
    NSMutableArray* allowedExtServices;
    
    BOOL geoLocationIsWorking;
    
    CGPoint startingPoint;
    NSSet *lastTouches;
    UIGestureRecognizerState state;
    NSTimer *progressTimer;
    NSDate *startDate;
    BOOL shouldTrigger;
    BOOL is_triggered;
    UIView *progressView;
    CALayer *progressLayer;
    
    BOOL shouldMoveMapOnLocationChange;
    NSString* baseLogoUrl;
    
    BOOL isFirstAppearence;
    
    NSString* serverUrl;
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
    pullRightView.openedCenter = CGPointMake(self.view.bounds.size.width - 85, verticalOffset + h / 2.0);
    pullRightView.closedCenter = CGPointMake(self.view.bounds.size.width + 85, verticalOffset + h / 2.0);
    pullRightView.center = pullRightView.closedCenter;
    pullRightView.animate = YES;
    pullRightView.toggleOnTap = YES;
    
    pullRightView.handleView.backgroundColor = [UIColor clearColor];
    pullRightView.handleView.frame = CGRectMake(0, panelHeight / 2 - 25, 15, 50);
    
    pullRightView.delegate = self;
    pullRightView.filterDelegate = self;
    
    [self.view addSubview:pullRightView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    serverUrl = @"http://80.254.99.158/API/TradePointMaintanance.asmx/LocateAround";
    //serverUrl = @"http://topdonkabinet.ru/API/TradePointMaintanance.asmx/LocateAround";

    
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    
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
    
    shouldMoveMapOnLocationChange = YES;
  
    tapRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longTapOnMap:)];
    tapRecognizer.minimumPressDuration = 1;
    [self.mapView addGestureRecognizer:tapRecognizer];
    
    [[self newsLine] setMarqueeType:MLContinuous];
    [[self newsLine] setBackgroundColor:[UIColor blackColor]];
    [[self newsLine] setRate:55];
    
    isFirstAppearence = YES;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (isFirstAppearence){
        isFirstAppearence = NO;
        
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0"))
        {
            geoLocationIsWorking = NO;
            [locationManager requestWhenInUseAuthorization];
        }
        else{
            geoLocationIsWorking = YES;
            [locationManager startUpdatingLocation];
        }
    }
    
    self.navigationController.navigationBarHidden = YES;
}

#pragma mark - locationManager callbacks and helpers

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

-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse || status == kCLAuthorizationStatusAuthorizedAlways)
    {
        geoLocationIsWorking = YES;
        shouldMoveMapOnLocationChange = YES;
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
    currentLocation = newLocation;
    
    //[currentLocation distanceFromLocation:newLocation]>LOCATION_UPDATE_THRESHOLD &&
    if (shouldMoveMapOnLocationChange){
        shouldMoveMapOnLocationChange = NO;
        currentLocation = newLocation;
        [self centerMap:self];
        
        [self.centerMapBtn setHidden:NO];
        
        [self showFilterView];
        
    }
}

#pragma mark - Long tap progress display and handling

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *) event
{
    UITouch *touch = [[event allTouches] anyObject];
    if ([self.searchField isFirstResponder] && (self.searchField != touch.view))
    {
        [self.searchField resignFirstResponder];
        
        return;
    }

    UIView *view = nil;
    for (UIGestureRecognizer *recognizer in touch.gestureRecognizers) {
        if ([recognizer isEqual:tapRecognizer]) {
            view = recognizer.view;
            break;
        }
    }
    
    startingPoint = [touch locationInView:view];
    
//    NSLog(@"touchesBegan @ %f, %f", startingPoint.x, startingPoint.y);

    
    lastTouches = touches;
    [self setupLongTapProgress];
}

- (void)handleTimer:(NSTimer *)timer {
    NSTimeInterval timerElapsed = [[NSDate new] timeIntervalSinceDate:startDate];
    shouldTrigger = timerElapsed >= tapRecognizer.minimumPressDuration;
    if (timerElapsed >= 0.25f && progressView == nil) {
        [self setupProgressView];
    }
    if (shouldTrigger && !is_triggered) {
        is_triggered = YES;
        state = UIGestureRecognizerStateBegan;
    }
    [self updateProgressLayer:(timerElapsed / tapRecognizer.minimumPressDuration)];
}

- (void)setupLongTapProgress
{
    if (progressTimer == nil) {
        progressTimer =
        [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(handleTimer:) userInfo:nil repeats:YES];
        startDate = [NSDate new];
    }
}

- (void)tearDown {
    [progressTimer invalidate];
    progressTimer = nil;
    [self tearDownProgressView];
    shouldTrigger = NO;
    is_triggered = NO;
}

- (void)setupProgressView
{
    float diameter = 200.0f;
    
    progressView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, diameter, diameter)];
    UITouch *touch = (UITouch *)[lastTouches anyObject];
    UIView *view = nil;
    for (UIGestureRecognizer *recognizer in touch.gestureRecognizers) {
        if ([recognizer isEqual:self]) {
            view = recognizer.view;
            break;
        }
    }
    
    CGPoint center = [touch locationInView:view];
    if (center.x == 0 && center.y == 0)
        return;
    
   progressView.center = center;
   progressView.alpha = 0.75f;
   progressView.layer.borderColor = [[UIColor blackColor] CGColor];
   progressView.layer.borderWidth = 2;
   progressView.layer.cornerRadius = diameter / 2.0f;
   progressLayer = [[CALayer alloc] init];
   progressLayer.frame = CGRectZero;
   progressLayer.backgroundColor = [[UIColor blackColor] CGColor];;
   progressLayer.cornerRadius = diameter / 2.0f;
   
    [progressView.layer addSublayer:progressLayer];
    [self.view addSubview:progressView];
}

- (void)updateProgressLayer:(CGFloat)progress {
    if (progress > 1.0) {
        progressLayer.backgroundColor =  [[UIColor blackColor] CGColor];
        progressView.layer.borderColor =  [[UIColor blackColor] CGColor];
        progressView.hidden = YES;
        return;
    }
    
    float diameter = 200.0f;
    CGFloat size = diameter * progress;
    if (size < 20)
        size = 20;
    
    CGFloat center = (diameter / 2.0f) - (size / 2.0f);
    progressLayer.cornerRadius = size / 2.0f;
    progressLayer.frame = CGRectMake(center, center, size, size);
}

- (void)tearDownProgressView {
    if (progressView == nil)
        return;
    
    [progressView removeFromSuperview];
    progressView = nil;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    lastTouches = touches;
    if (progressTimer != nil) {
        state = UIGestureRecognizerStatePossible;
        [self tearDown];
    }
    
//    UITouch *touch = [[event allTouches] anyObject];
//    CGPoint point = [touch locationInView:_mapView];
//
//    NSLog(@"touchesCancelled @ %f, %f", point.x, point.y);
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
//    UITouch *touch = [[event allTouches] anyObject];
//    CGPoint point = [touch locationInView:_mapView];
//    
//    NSLog(@"touchesCancelled @ %f, %f", point.x, point.y);

    lastTouches = touches;
    if (progressTimer != nil) {
        [self tearDown];
    }
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [[event allTouches] anyObject];
    
    UIView *view = nil;
    for (UIGestureRecognizer *recognizer in touch.gestureRecognizers) {
        if ([recognizer isEqual:tapRecognizer]) {
            view = recognizer.view;
            break;
        }
    }

    if ([view isEqual:_mapView]){
//        shouldMoveMapOnLocationChange = NO;
        //NSLog(@"User moved the map");
    }
}

-(void)longTapOnMap:(UIGestureRecognizer *)recognizer
{
    if (recognizer.state != UIGestureRecognizerStateBegan)
    {
        return;
    }
    
    CGPoint point = [recognizer locationInView:self.mapView];
    if (isnan(point.x) || isnan(point.y))
        return;
    
    CLLocationCoordinate2D tapPoint = [self.mapView convertPoint:point toCoordinateFromView:self.mapView];
    
    [self loadStationsAround:[[CLLocation alloc] initWithLatitude:tapPoint.latitude longitude:tapPoint.longitude]];
}

#pragma mark - Map view delegates

-(void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
//    NSLog(@"regionDidChangeAnimated");
}

-(void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated
{
//    NSLog(@"regionWillChangeAnimated");
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    static NSString *identifier = @"GasStation";
    if ([annotation isKindOfClass:[GasStation class]]) {
        
        GasStation *gasStation = (GasStation*)annotation;
        
        NSString *stationReusableIdentifier = [NSString stringWithFormat:@"%@-%d%@", identifier, gasStation.BusinessUnitInternalKey, gasStation.hasNews ? @"-news" : @""];
        
        MKAnnotationView *annotationView = (MKAnnotationView *) [_mapView dequeueReusableAnnotationViewWithIdentifier:stationReusableIdentifier];
        
        if (annotationView == nil)
        {
            annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:stationReusableIdentifier];
            annotationView.enabled = YES;
            annotationView.canShowCallout = YES;
            
            [annotationView sd_setImageWithURL:[NSURL URLWithString:gasStation.brandImage] placeholderImage:[UIImage imageNamed:@"fuelPin.png"] options:SDWebImageRefreshCached];
            
            
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

#pragma mark - Misk functions
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
                     
                     [self showFilterView];
                     
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

#pragma mark - Map operations

- (IBAction)centerMap:(id)sender {
    [self.mapView setCenterCoordinate:currentLocation.coordinate];
    MKCoordinateRegion region =
    MKCoordinateRegionMakeWithDistance(currentLocation.coordinate, 1000, 1000);
    [self.mapView setRegion:region animated:YES];
    
    [self loadStationsAround:currentLocation];
    
    //shouldMoveMapOnLocationChange = YES;
}

- (BOOL)connected {
    return [AFNetworkReachabilityManager sharedManager].reachable;
}

-(void)loadStationsAround:(CLLocation *)location
{
    
//    if (![self connected])
//    {
//        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"TOPDON" message:@"Отсутствует подключение к сети интернет. Подключение к сети интернет требуется для правильного функционирования аппликации." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
//        [av show];
//        
//        return;
//    }
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    NSDictionary *parameters = @{
                                 @"longitude" : [NSString stringWithFormat:@"%f", location.coordinate.longitude],
                                 @"latitude" : [NSString stringWithFormat:@"%f", location.coordinate.latitude],
                                 @"applicationPlatform":@"browser" //iOS
                                 };

    NSMutableURLRequest *request = [[AFJSONRequestSerializer serializer] requestWithMethod:@"POST" URLString:serverUrl parameters:parameters error:nil];
    
    AFHTTPRequestOperation *operation = [manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject)
                                         {
                                             NSDictionary* tmp = [((NSDictionary*)responseObject) objectForKey:@"d"];
                                             
                                             if ([[tmp objectForKey:@"Status"] intValue] == 0)
                                             {
                                                 tmp = [tmp objectForKey:@"Data"];
                                                 
                                                 baseLogoUrl = [tmp objectForKey:@"BaseLogoUrl"];
                                                 if (baseLogoUrl == nil || [baseLogoUrl isKindOfClass:[NSNull class]])
                                                     baseLogoUrl = @"";

                                                 NSString* newsLine = [tmp objectForKey:@"NewsLine"];
                                                 if (newsLine != nil && ![newsLine isKindOfClass:[NSNull class]]){
                                                     newsLine = [@" " stringByAppendingString:newsLine];
                                                     [[self newsLine] setText:newsLine];
                                                     if ([[self newsLine] isPaused])
                                                         [[self newsLine] unpauseLabel];
                                                     [[self newsLine] setHidden:NO];
                                                 }
                                                 else{
                                                     [[self newsLine] setText:@""];
                                                     [[self newsLine] pauseLabel];
                                                     [[self newsLine] setHidden:YES];
                                                 }
                                                 
                                                 NSDictionary * stations = [tmp objectForKey:@"TradePoints"];

                                                 foundGasStations = [NSMutableArray array];
                                                 for (NSDictionary * station in stations)
                                                 {
                                                     GasStation *gasStation = [[GasStation alloc] initWithServerObject:station andBaseLogoUrl:baseLogoUrl];
                                                     
                                                     [foundGasStations addObject:gasStation];
                                                 }
                                                 
                                                 [self updatesStationsOnMap];
                                                 
                                                 int radius = [[tmp objectForKey:@"Radius"] intValue];
                                                 MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(location.coordinate, radius, radius);
                                                 [self.mapView setRegion:region animated:YES];
                                             }
                                             else
                                             {
                                                 UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"TOPDON" message:[NSString stringWithFormat:@"Ошибка сервера: %@", [tmp objectForKey:@"Messagev"]] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                                                 [av show];
                                             }
                                         }
                                        failure:^(AFHTTPRequestOperation *operation, NSError *error)
                                         {
                                             NSLog(@"Error: %@", error);
                                             NSLog(@"Response: %@", operation.responseString);
                                             
                                             UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"TOPDON" message:[NSString stringWithFormat:@"%@", error] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
//                                             UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"TOPDON" message:@"Ошибка связи с сервером.", error] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
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
    
    for (GasStation *gasStation in foundGasStations)
    {
        if ([allowedFuels count] > 0)
        {
            if ([[gasStation FuelTypes] count] == 0)
                continue;
            
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
        
        if ([allowedServices count] > 0)
        {
            if ([[gasStation TechnicalServices] count] == 0)
                continue;

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
        
        if ([allowedExtServices count] > 0)
        {
            if ([[gasStation AdditionalServices] count] == 0)
                continue;
            
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

#pragma mark - Filtering

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
