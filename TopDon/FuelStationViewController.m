//
//  FuelStationViewController.m
//  TopDon
//
//  Created by Pavel Yankelevich on 10/2/14.
//  Copyright (c) 2014 Pavel Yankelevich. All rights reserved.
//

#import "FuelStationViewController.h"
#import "CMMapLauncher.h"
#import "MKAnnotationView+WebCache.h"

@interface FuelStationViewController ()
{
    NSMutableArray *navigators;
    BOOL isHtmlLoaded;
    int height;
}
@end

@implementation FuelStationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.stationMapView.delegate = self;
    
    isHtmlLoaded = NO;
}

-(void)viewWillAppear:(BOOL)animated
{
   // [super viewWillAppear:animated];

    self.navigationController.navigationBarHidden = NO;
    
    [self.stationMapView setCenterCoordinate:_gasStation .coordinate];
    MKCoordinateRegion region =
    MKCoordinateRegionMakeWithDistance(_gasStation .coordinate, 500, 500);
    [self.stationMapView setRegion:region animated:YES];
    
    [self.stationMapView addAnnotation:_gasStation];
//    [self.stationMapView selectAnnotation:_gasStation animated:NO];
  
    
    NSString* content = [NSString stringWithFormat:@"<html><head><base href='%@'></head><body style='margin-top: 0px;margin-bottom: 0px;'><div id='foo'>%@</div></body></html>", _gasStation.baseWebUrl, _gasStation.promoText];
    
    [[self promo] loadHTMLString:content baseURL:[NSURL URLWithString:@""]];
//    [[self promo] setText:_gasStation.promoText];
    [[[self promo] scrollView] setScrollEnabled:NO];
    
    [[self street] setText:[NSString stringWithFormat:@"%@ %@", _gasStation.street, _gasStation.houseNumber]];
    
    [[self city] setText:_gasStation.city];
    
//--------------------
    NSMutableArray* fuels = [NSMutableArray array];

    [self.fuelTypesView setAutomaticResize:YES];
    [self.fuelTypesView setScrollEnabled:NO];
    [self.fuelTypesView setViewOnly:YES];

    if ([_gasStation FuelTypes] != nil)
    {
        for (NSDictionary* fuel in [_gasStation FuelTypes]) {
            [fuels addObject:[fuel objectForKey:@"Name"]];
        }
        
        [self.fuelTypesView setTags:fuels];
    }
    else
        [self.fuelTypesView setTags:@[@"N/A"]];
    
    //--------------------

    NSMutableArray* services = [NSMutableArray array];
    [self.servicesView setAutomaticResize:YES];
    [self.servicesView setScrollEnabled:NO];
    [self.servicesView setViewOnly:YES];

    if ([_gasStation TechnicalServices] != nil)
    {
        for (NSDictionary* service in [_gasStation TechnicalServices]) {
                [services addObject:[service objectForKey:@"Name"]];
        }
        
        [self.servicesView setTags:services];
    }
    else
        [self.servicesView setTags:@[@"N/A"]];

    //--------------------
    
    NSMutableArray* extServices = [NSMutableArray array];
    [self.additionalServices setViewOnly:YES];
    [self.additionalServices setAutomaticResize:YES];
    [self.additionalServices setScrollEnabled:NO];

    if ([_gasStation AdditionalServices] != nil)
    {
        for (NSDictionary* extService in [_gasStation AdditionalServices]) {
            [extServices addObject:[extService objectForKey:@"Name"]];
        }
        
        [self.additionalServices setTags:extServices];
    }
    else
        [self.additionalServices setTags:@[@"N/A"]];

    [self.tableView setSeparatorColor:[UIColor clearColor]];
}


#pragma mark - Web View Delegate

-(void)webViewDidFinishLoad:(UIWebView *)webView{
    NSString *h = [[self promo] stringByEvaluatingJavaScriptFromString:@"document.getElementById(\"foo\").offsetHeight;"];
    
    height = [h intValue];
    isHtmlLoaded = YES;
    
    [[self tableView] reloadData];
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if (navigationType == UIWebViewNavigationTypeLinkClicked)
    {
        if ([[UIApplication sharedApplication] canOpenURL:[request URL]])
            [[UIApplication sharedApplication] openURL:[request URL]];

        return false;
    }
    
    return true;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [_gasStation.promoText isEqualToString:@""] ? 5 :  6;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

#pragma mark - Table View Delegate

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return section < 4 && section > 1 ? 7 : 0;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *tmp = @[@182, @41, @103, @103, @103, @92];
    
    if( indexPath.section == 2){
        CGRect r= self.fuelTypesView.bounds;
        r.size.height = self.fuelTypesView.fittedSize.height + 5;
        return r.size.height;
    }
    
    if( indexPath.section == 3){
        CGRect r= self.servicesView.bounds;
        r.size.height = self.servicesView.fittedSize.height + 5;
        return r.size.height;
    }
    
    if( indexPath.section == 4){
        CGRect r= self.additionalServices.bounds;
        r.size.height = self.additionalServices.fittedSize.height + 5;
        return r.size.height;
    }
    
    if( indexPath.section == 4){
        CGRect r= self.additionalServices.bounds;
        r.size.height = self.additionalServices.fittedSize.height + 5;
        return r.size.height;
    }
    
    if( indexPath.section == 5){
        if (isHtmlLoaded)
            return height + 12;
        
        return 102;
    }

    return [[tmp objectAtIndex:indexPath.section] integerValue];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    static NSString *identifier = @"GasStation";
    if ([annotation isKindOfClass:[GasStation class]]) {
        
        MKAnnotationView *annotationView = (MKAnnotationView *) [self.stationMapView dequeueReusableAnnotationViewWithIdentifier:identifier];
        if (annotationView == nil) {
            annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
            annotationView.enabled = YES;
            annotationView.canShowCallout = YES;

            GasStation *gasStation = (GasStation*)annotation;

            [annotationView sd_setImageWithURL:[NSURL URLWithString:gasStation.brandImage] placeholderImage:[UIImage imageNamed:@"fuelPin.png"] options:SDWebImageRefreshCached];
        } else {
            annotationView.annotation = annotation;
        }
        
        return annotationView;
    }
    
    return nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation Program Selection
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0)
        return;
    
    CMMapPoint * mapPoint = [CMMapPoint mapPointWithName:[_gasStation title] coordinate:_gasStation.coordinate];
    [CMMapLauncher launchMapApp:[[navigators objectAtIndex:(buttonIndex - 1)] intValue] forDirectionsTo:mapPoint];
}

- (IBAction)navigateToStation:(id)sender
{
    UIActionSheet * as = [[UIActionSheet alloc] initWithTitle:@"Какой программой воспользоваться?" delegate:self cancelButtonTitle:@"Отмена" destructiveButtonTitle:nil otherButtonTitles:nil];

    navigators = [[NSMutableArray alloc] init];
    if ([CMMapLauncher isMapAppInstalled:CMMapAppAppleMaps]){
        [navigators addObject:[NSNumber numberWithInt:CMMapAppAppleMaps]];
        [as addButtonWithTitle:@"Карты Apple"];
    }
    
    if ([CMMapLauncher isMapAppInstalled:CMMapAppGoogleMaps]){
        [navigators addObject:[NSNumber numberWithInt:CMMapAppGoogleMaps]];
        [as addButtonWithTitle:@"Карты Google"];
    }
    
    if ([CMMapLauncher isMapAppInstalled:CMMapAppWaze]){
        [navigators addObject:[NSNumber numberWithInt:CMMapAppWaze]];
        [as addButtonWithTitle:@"Waze"];
    }
    
    if ([CMMapLauncher isMapAppInstalled:CMMapAppYandex]){
        [navigators addObject:[NSNumber numberWithInt:CMMapAppYandex]];
        [as addButtonWithTitle:@"Яндекс Навигатор"];
    }
    
    if ([navigators count] == 0)
    {
        
    }
    else if ([navigators count] == 1)
    {
        [CMMapLauncher launchMapApp:[[navigators objectAtIndex:0] integerValue] forDirectionsTo:[CMMapPoint mapPointWithName:self.gasStation.title coordinate:self.gasStation.coordinate]];
    }
    else
      [as showInView:self.view];
}

@end
