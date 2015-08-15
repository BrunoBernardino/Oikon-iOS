//
//  SettingsViewController.m
//  Oikon
//
//  Created by Bruno Bernardino on 14/06/14.
//  Copyright (c) 2014 emotionLoop. All rights reserved.
//

#import "SettingsViewController.h"
#import "MainViewController.h"
#import "AppDelegate.h"

@interface SettingsViewController ()

@end

@implementation SettingsViewController

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
	
	// Set title
	[self setTitle:NSLocalizedString(@"Settings", nil)];
	
	// Make the navigationbar color white, background blue
    UIColor *blueColor = [UIColor colorWithRed:62/255.0 green:138/255.0 blue:229/255.0 alpha:1];
	UIColor *whiteColor = [UIColor whiteColor];
    self.navigationController.navigationBar.barTintColor = blueColor;
	self.navigationController.navigationBar.tintColor = whiteColor;
    self.navigationController.navigationBar.translucent = YES;
	
	// Add background gradient
	CAGradientLayer *gradient = [CAGradientLayer layer];
	gradient.frame = self.view.bounds;
	gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor whiteColor] CGColor], (id)[[UIColor colorWithRed:0.878431373 green:0.878431373 blue:0.878431373 alpha:1] CGColor], nil];
	[self.view.layer insertSublayer:gradient atIndex:0];
	
	// Add bottom border each "field view"
	CALayer *bottomBorderForPasscode = [CALayer layer];
	bottomBorderForPasscode.backgroundColor = [UIColor colorWithRed:0.815686275 green:0.815686275 blue:0.815686275 alpha:1].CGColor;
	bottomBorderForPasscode.frame = CGRectMake(0.0f, self.passcodeView.frame.size.height, self.view.bounds.size.width, 0.5f);
	[self.passcodeView.layer addSublayer:bottomBorderForPasscode];
	
	CALayer *bottomBorderForiCloud = [CALayer layer];
	bottomBorderForiCloud.backgroundColor = [UIColor colorWithRed:0.815686275 green:0.815686275 blue:0.815686275 alpha:1].CGColor;
	bottomBorderForiCloud.frame = CGRectMake(0.0f, self.iCloudView.frame.size.height, self.view.bounds.size.width, 0.5f);
	[self.iCloudView.layer addSublayer:bottomBorderForiCloud];
	
	// Make the buttons rounded
	self.removeAllDataButton.layer.cornerRadius = 4;
	
	// Bind tap on remove data buttons
	[self.removeAllDataButton addTarget:self action:@selector(showRemoveDataAlert:) forControlEvents:UIControlEventTouchUpInside];
	
	// Bind toggle on switches
	[self.passcodeSwitch addTarget:self action:@selector(togglePasscodeSwitch:) forControlEvents:UIControlEventValueChanged];
	[self.iCloudSwitch addTarget:self action:@selector(toggleiCloudSwitch:) forControlEvents:UIControlEventValueChanged];
	
	// Load data in view
	[self refreshViewWithSettings];
	
	// Initialize attempts
	self.attempts = 0;
	
	// Initialize temporary passcode
	self.temporaryPasscode = @"";
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// Act on a confirmation button selection
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];

	// Local Data Remove
	if ( [alertView.message rangeOfString:NSLocalizedString(@"remove all local & iCloud data", nil)].location != NSNotFound ) {
		NSLog(@"Tapped for data alert, buttonIndex = %ld", (long)buttonIndex);

		if ( buttonIndex == 1 ) {
			// Remove data
			[appDelegate removeAllData];
		}
	}
	
	// Confirming current passcode for disabling it
	if ( [alertView.message rangeOfString:NSLocalizedString(@"passcode in order to disable it", nil)].location != NSNotFound ) {
		NSLog(@"Tapped for passcode confirmation alert, buttonIndex = %ld", (long)buttonIndex);

		if ( buttonIndex == 1 ) {
			NSString *passcode = [[alertView textFieldAtIndex:0] text];
			
			self.attempts = [NSNumber numberWithInt:[self.attempts intValue] + 1];
			
			// If the user tried more than 3 times, close the app
			if ( [self.attempts intValue] > 3 ) {
				exit( 0 );
			} else {
				// Otherwise let's confirm the passcode is valid
				if ( [appDelegate isPasscodeValid:passcode] ) {
					// Empty passcode
					[self.settings setValue:nil forKey:@"passcode"];
					
					self.attempts = 0;
					
					// Update view
					[self refreshViewWithSettings];
				} else {
					// Show alert indicating the passcode is wrong
					UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Wrong Passcode!", nil) message:[NSString stringWithFormat:NSLocalizedString(@"Please try again. You have used %d of %d attempts before the app auto-closes.", nil), [self.attempts intValue], 3] delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
					
					[alertView show];
				}
			}
		}
	}
	
	// Setting new passcode for enabling it
	if ( [alertView.message rangeOfString:NSLocalizedString(@"type in your new passcode", nil)].location != NSNotFound ) {
		
		if ( buttonIndex == 1 ) {
			NSString *passcode = [[alertView textFieldAtIndex:0] text];

			if ( passcode.length == 4 ) {
				// Save the passcode temporarily
				self.temporaryPasscode = passcode;

				// Ask for passcode confirmation
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"New Passcode", nil) message:NSLocalizedString(@"Please confirm your new passcode.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"Confirm", nil), nil];
				alert.alertViewStyle = UIAlertViewStylePlainTextInput;
				UITextField *alertTextField = [alert textFieldAtIndex:0];
				
				[alertTextField setKeyboardType:UIKeyboardTypeNumberPad];
				[alertTextField setSecureTextEntry:YES];
				
				[alert show];
			} else {
				// Show alert indicating the passcode needs to be 4 characters long
				UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Invalid Passcode!", nil) message:NSLocalizedString(@"The passcode needs to be 4 digits.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
				
				[alertView show];
			}
			
		}
	}
	
	// Confirming new passcode for enabling it
	if ( [alertView.message rangeOfString:NSLocalizedString(@"confirm your new passcode", nil)].location != NSNotFound ) {
		
		if ( buttonIndex == 1 ) {
			NSString *passcode = [[alertView textFieldAtIndex:0] text];
			
			if ( [passcode isEqualToString:self.temporaryPasscode] ) {
				// Set Passcode
				[self.settings setValue:[NSNumber numberWithInt:[passcode intValue]] forKey:@"passcode"];
				
				// Update view
				[self refreshViewWithSettings];
			} else {
				// Show alert indicating the passcode did not match
				UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Invalid Passcode!", nil) message:NSLocalizedString(@"The passcodes do not match.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
				
				[alertView show];
				
				// Clear the temporary passcode
				self.temporaryPasscode = @"";
			}
			
		}
	}
}

// Don't allow more than 4 characters on the passcode
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSUInteger newLength = [textField.text length] + [string length] - range.length;
    return (newLength > 4) ? NO : YES;
}

// Load settings into view
- (void) refreshViewWithSettings
{
	self.settings = [NSUserDefaults standardUserDefaults];
	[self.settings synchronize];
	
	NSLog(@"Refreshing view settings");
	
	NSMutableDictionary *iCloudSettings = [[self.settings objectForKey:@"iCloud"] mutableCopy];

	NSNumber *currentPasscode = [self.settings valueForKey:@"passcode"];
	BOOL isiCloudEnabled = [[iCloudSettings valueForKey:@"isEnabled"] isEqual:@YES] ? YES : NO;
	
	//NSLog(@"Current Passcode = %@", currentPasscode);
	//NSLog(@"iCloud Settings = %@", iCloudSettings);
	
	// Passcode switch
	if ( currentPasscode != nil ) {
		[ self.passcodeSwitch setOn:YES ];
	} else {
		[ self.passcodeSwitch setOn:NO ];
	}
	
	// iCloud switch
	if ( isiCloudEnabled ) {
		[ self.iCloudSwitch setOn:YES ];

		// Show sync view
		self.syncStatusView.hidden = NO;
		
		// Set sync text
		[self setiCloudSyncLabelText];
	} else {
		[ self.iCloudSwitch setOn:NO ];

		// Hide sync view
		self.syncStatusView.hidden = YES;
	}
}

// Show alert to remove all data
- (IBAction)showRemoveDataAlert:(id)sender
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Are you sure?", nil) message:NSLocalizedString(@"This will remove all local & iCloud data, including expenses, and expense types.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"Confirm", nil), nil];
	
	[alertView show];
}

// Handle the toggle on the passcode switch
- (IBAction)togglePasscodeSwitch:(id)sender
{
	UISwitch *switchView = (UISwitch *)sender;

	BOOL currentSwitchValue = NO;
	BOOL newSwitchValue = switchView.isOn;
	
	NSNumber *currentPasscode = [self.settings valueForKey:@"passcode"];
	
	// Consider the switch enabled if there was a passcode
	if ( currentPasscode != nil ) {
		currentSwitchValue = YES;
	}
	
	// Trying to disable passcode
	if ( currentSwitchValue && ! newSwitchValue ) {
		// Ask for current passcode
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Current Passcode", nil) message:NSLocalizedString(@"Please type in your current passcode in order to disable it.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"Confirm", nil), nil];
		alert.alertViewStyle = UIAlertViewStylePlainTextInput;
		UITextField *alertTextField = [alert textFieldAtIndex:0];
		
		[alertTextField setKeyboardType:UIKeyboardTypeNumberPad];
		[alertTextField setSecureTextEntry:YES];

		[alert show];
	}
	
	// Trying to enable passcode
	if ( ! currentSwitchValue && newSwitchValue ) {
		// Ask for new passcode
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"New Passcode", nil) message:NSLocalizedString(@"Please type in your new passcode.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"Continue", nil), nil];
		alert.alertViewStyle = UIAlertViewStylePlainTextInput;
		UITextField *alertTextField = [alert textFieldAtIndex:0];
		
		[alertTextField setKeyboardType:UIKeyboardTypeNumberPad];
		[alertTextField setSecureTextEntry:YES];
		
		[alert show];
	}
	
	// Update view
	[self refreshViewWithSettings];
}

// Handle the toggle on the iCloud switch
- (IBAction)toggleiCloudSwitch:(id)sender
{
	UISwitch *switchView = (UISwitch *)sender;
	
	BOOL currentSwitchValue = NO;
	BOOL newSwitchValue = switchView.isOn;
	
	NSMutableDictionary *currentiCloud = [[self.settings objectForKey:@"iCloud"] mutableCopy];
	BOOL isiCloudEnabled = [[currentiCloud valueForKey:@"isEnabled"] isEqual:@YES] ? YES : NO;
	
	// Consider the switch enabled if iCloud is enabled
	if ( isiCloudEnabled ) {
		currentSwitchValue = YES;
	}
	
	AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
	
	// Disabling iCloud
	if ( currentSwitchValue && ! newSwitchValue ) {
		[currentiCloud setValue:@NO forKey:@"isEnabled"];

		[self.settings setObject:currentiCloud forKey:@"iCloud"];
		
		[appDelegate migrateDataToLocal];
	}
	
	// Enabling iCloud
	if ( ! currentSwitchValue && newSwitchValue ) {
		[currentiCloud setValue:@YES forKey:@"isEnabled"];
		
		[self.settings setObject:currentiCloud forKey:@"iCloud"];
		
		[appDelegate migrateDataToiCloud];
	}
	
	// Update view
	[self refreshViewWithSettings];
}

// Formats the date for the sync
- (NSString *)formatDate:(NSDate *)date
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	NSLocale* locale = [[NSLocale alloc] initWithLocaleIdentifier:NSLocalizedString(@"en_US", nil)];
	[dateFormatter setLocale:locale];
	[dateFormatter setDateStyle:NSDateFormatterShortStyle];
    [dateFormatter setDateFormat:NSLocalizedString(@"HH:mm:ss - MMM, d, yyyy", nil)];
    NSString *formattedDate = [dateFormatter stringFromDate:date];
    return formattedDate;
}

// Set sync text
- (void) setiCloudSyncLabelText
{
	NSMutableDictionary *currentiCloud = [[self.settings objectForKey:@"iCloud"] mutableCopy];
	NSDate *lastSyncStartDate = [currentiCloud valueForKey:@"lastSyncStart"];
	NSDate *lastSyncEndDate = [currentiCloud valueForKey:@"lastSuccessfulSync"];
	
	// If last sync start date is bigger than the last sync end date, we're synchronizing
	if( lastSyncStartDate != nil && [lastSyncStartDate timeIntervalSinceDate:lastSyncEndDate] > 0 ) {
		self.syncStatusLabel.text = NSLocalizedString(@"now...", nil);
	} else {

		self.syncStatusLabel.text = [NSString stringWithFormat:@"%@", [self formatDate:lastSyncEndDate]];
	}
}

// iCloud did update
-(IBAction)iCloudDidUpdate:(id)sender
{
    NSLog(@"iCloud DID update");
    
    // This was creating an infinite loop, so we only allow this to run once every minute tops.
    BOOL codeHasRunInThePastMinute = NO;
    
    if ( self.lastiCloudFetch != nil ) {
        int secondsAfterLastRun = [[[NSDate alloc] init] timeIntervalSinceDate:self.lastiCloudFetch];
        
        if ( secondsAfterLastRun < 60 ) {
            codeHasRunInThePastMinute = YES;
        } else {
            codeHasRunInThePastMinute = NO;
            self.lastiCloudFetch = [[NSDate alloc] init];
        }
    } else {
        self.lastiCloudFetch = [[NSDate alloc] init];
        codeHasRunInThePastMinute = YES;// We won't allow this to run so soon in the app
    }
    
    // Run the actual code, if there's a need to
    if ( !codeHasRunInThePastMinute ) {
        [self refreshViewWithSettings];
    }
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
