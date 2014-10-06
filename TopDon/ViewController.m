//
//  ViewController.m
//  TopDon
//
//  Created by Pavel Yankelevich on 9/28/14.
//  Copyright (c) 2014 Pavel Yankelevich. All rights reserved.
//

#import "ViewController.h"
#import "FilterView.h"

@interface ViewController ()
{
    FilterView* pullRightView;
    CLLocationManager *locationManager;
    CLLocation *currentLocation;
    
    int n;
}
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    
//    float panelWidth = 200;
//    
//    float w = self.view.bounds.size.width;
    float panelHeight = 350;
    float verticalOffset = self.mapView.frame.origin.y / 2;
    float  h = self.view.bounds.size.height;
    
//    pullRightView = [[PullableView alloc] initWithFrame:CGRectMake(w, verticalOffset + h / 2.0 - panelHeight / 2.0, panelWidth, panelHeight)];
    
    pullRightView = [[[NSBundle mainBundle] loadNibNamed:@"FilterView" owner:self options:nil] objectAtIndex:0];
//    pullRightView.backgroundColor = [UIColor darkGrayColor];
    pullRightView.openedCenter = CGPointMake(self.view.bounds.size.width - 94, verticalOffset + h / 2.0);
    pullRightView.closedCenter = CGPointMake(self.view.bounds.size.width + 85, verticalOffset + h / 2.0);
    pullRightView.center = pullRightView.closedCenter;
    pullRightView.animate = YES;
    pullRightView.toggleOnTap = YES;
    
    pullRightView.layer.cornerRadius = 6;
    
    pullRightView.handleView.backgroundColor = [UIColor clearColor];
    pullRightView.handleView.frame = CGRectMake(0, panelHeight / 2 - 25, 15, 50);
    
    pullRightView.delegate = self;
    
    [self.view addSubview:pullRightView];

    locationManager = [[CLLocationManager alloc] init];
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    locationManager.delegate = self;
    [locationManager startUpdatingLocation];
        
    currentLocation = [[CLLocation alloc] initWithLatitude:0 longitude:0];
    
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(foundTap:)];
    
    tapRecognizer.numberOfTapsRequired = 1;
    
    tapRecognizer.numberOfTouchesRequired = 1;
    
    [self.mapView addGestureRecognizer:tapRecognizer];
    
    n = 0;
}

-(IBAction)foundTap:(UITapGestureRecognizer *)recognizer
{
    if (n >= 1)
        return;
    
    n++;
    
    CGPoint point = [recognizer locationInView:self.mapView];
    
    CLLocationCoordinate2D tapPoint = [self.mapView convertPoint:point toCoordinateFromView:self.mapView];
    
    MKPointAnnotation *point1 = [[MKPointAnnotation alloc] init];
    point1.coordinate = tapPoint;
    point1.title = [NSString stringWithFormat:@"Заправка №%d", n];
    point1.subtitle = @"ТОП ДОН";
    
    [self.mapView addAnnotation:point1];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    static NSString *identifier = @"FuelLocation";
    if ([annotation isKindOfClass:[MKPointAnnotation class]]) {
        
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

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
//    MyLocation *location = (MyLocation*)view.annotation;
//    
//    NSDictionary *launchOptions = @{MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeD};
//    [location.mapItem openInMapsWithLaunchOptions:launchOptions];
    
    
    [self performSegueWithIdentifier:@"fuelStationSegue" sender:self];
}

-(void)viewWillAppear:(BOOL)animated
{
    self.navigationController.navigationBarHidden = YES;
    
    
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *newLocation = [locations objectAtIndex:0];
    
    if ([currentLocation distanceFromLocation:newLocation]>100){
        
        currentLocation = newLocation;
        [self centerMap:self];
    }
    
}

-(void)pullableView:(PullableView *)pView didChangeState:(BOOL)opened{
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *) event
{
    UITouch *touch = [[event allTouches] anyObject];
    if ([self.searchField isFirstResponder] && (self.searchField != touch.view))
    {
        [self.searchField resignFirstResponder];
    }
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
}
@end
