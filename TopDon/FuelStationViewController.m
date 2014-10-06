//
//  FuelStationViewController.m
//  TopDon
//
//  Created by Pavel Yankelevich on 10/2/14.
//  Copyright (c) 2014 Pavel Yankelevich. All rights reserved.
//

#import "FuelStationViewController.h"
#import "CMMapLauncher.h"

@interface FuelStationViewController ()
{
    NSMutableArray *navigators;
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
}

-(void)viewWillAppear:(BOOL)animated
{
    self.navigationController.navigationBarHidden = NO;
    
    [self.stationMapView setCenterCoordinate:_gasStation .coordinate];
    MKCoordinateRegion region =
    MKCoordinateRegionMakeWithDistance(_gasStation .coordinate, 100, 100);
    [self.stationMapView setRegion:region animated:YES];
    
    [self.stationMapView addAnnotation:_gasStation];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    static NSString *identifier = @"GasStation";
    if ([annotation isKindOfClass:[GasStation class]]) {
        
        MKAnnotationView *annotationView = (MKAnnotationView *) [self.stationMapView dequeueReusableAnnotationViewWithIdentifier:identifier];
        if (annotationView == nil) {
            annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
            annotationView.enabled = YES;
            annotationView.canShowCallout = YES;
            annotationView.image = [UIImage imageNamed:@"fuelPin.png"];
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 5;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
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

/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}
*/

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


@end
