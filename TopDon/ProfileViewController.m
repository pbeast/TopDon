//
//  ProfileViewController.m
//  TopDon
//
//  Created by Pavel Yankelevich on 9/28/14.
//  Copyright (c) 2014 Pavel Yankelevich. All rights reserved.
//

#import "ProfileViewController.h"

@interface ProfileViewController ()
{
    UIToolbar* keyboardDoneButtonView;
    UIBarButtonItem* doneButton;
}
@end

@implementation ProfileViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    keyboardDoneButtonView = [[UIToolbar alloc] init];
    [keyboardDoneButtonView sizeToFit];
    doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Готово" style:UIBarButtonItemStyleDone target:self action:@selector(doneClicked:)];
    [doneButton setEnabled:NO];
    
    [keyboardDoneButtonView setItems:[NSArray arrayWithObjects:doneButton, nil]];
    self.cardNumber.inputAccessoryView = keyboardDoneButtonView;
    
    [self.cardNumber addTarget:self action:@selector(cardNumberChanged:) forControlEvents:UIControlEventEditingChanged];
}

-(void)getBalanceOnCard:(NSString*)cardNumber
{
    [[NSUserDefaults standardUserDefaults] setValue:cardNumber forKey:@"loyaltyCardNumber"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeIndeterminate;
        hud.labelText = @"Получение данных";
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            [self.balance setText:[NSString stringWithFormat:@"Баланс: %d", arc4random_uniform(1000) % 1000]];
            [hud hide:YES];
        });
    });
}

- (IBAction)doneClicked:(id)sender
{
    [self.cardNumber resignFirstResponder];

    [self getBalanceOnCard:[self.cardNumber text]];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBarHidden = NO;
    
    NSString* loyaltyCardNumber = [[NSUserDefaults standardUserDefaults] valueForKey:@"loyaltyCardNumber"];
    if (loyaltyCardNumber != nil && [loyaltyCardNumber length]>0)
    {
        [self.cardNumber setText:loyaltyCardNumber];
        [self getBalanceOnCard:loyaltyCardNumber];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    [doneButton setEnabled:NO];
    [doneButton setEnabled:([[self.cardNumber text] length] > 0)];
}

- (IBAction)cardNumberChanged:(UITextField *)textField
{
    [doneButton setEnabled:([[self.cardNumber text] length] > 0)];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
