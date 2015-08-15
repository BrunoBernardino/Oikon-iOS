//
//  PasscodeViewController.m
//  Oikon
//
//  Created by Bruno Bernardino on 14/06/14.
//  Copyright (c) 2014 emotionLoop. All rights reserved.
//

#import "PasscodeViewController.h"
#import "AppDelegate.h"

@interface PasscodeViewController ()

@end

@implementation PasscodeViewController

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
	[self setTitle:NSLocalizedString(@"Unlock App", nil)];
	
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
	
	// Add "Unlock" button to navigation controller
	UIBarButtonItem *unlockButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Unlock", nil) style:UIBarButtonItemStylePlain target:self action:@selector(validatePasscode:)];
	self.navigationItem.rightBarButtonItem = unlockButton;
	
	// Initialize attempts
	self.attempts = 0;
	
	// Look into this view for overriding behaviors in the text field
	self.passcodeTextField.delegate = self;
	
	// Clear textview
	self.passcodeTextField.text = @"";
	
	// This code below for some reason needs a delay, or the textfield has an erratic behavior
	double delayInSeconds = 0.1;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		// Focus textview
		[self.passcodeTextField becomeFirstResponder];
	});
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// Close app on tapping back, if willAskForPasscode is YES
- (void)viewWillDisappear:(BOOL)animated {
	AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
	
	NSLog(@"PASSCODE WILL DISAPPEAR");
	
	if ( appDelegate.willAskForPasscode ) {
		exit( 0 );
	}
	
    [super viewWillDisappear:animated];
}

// Don't allow more than 4 characters on the passcode
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSUInteger newLength = [textField.text length] + [string length] - range.length;
    return (newLength > 4) ? NO : YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
	return YES;
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

// Attempt passcode validation
- (IBAction) validatePasscode:(id)sender
{
	AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
	
	NSString *passcode = [self.passcodeTextField text];
	
	self.attempts = [NSNumber numberWithInt:[self.attempts intValue] + 1];
		
	// If the user tried more than 3 times, close the app
	if ( [self.attempts intValue] > 3 ) {
		exit( 0 );
	} else {
		// Otherwise let's confirm the passcode is valid
		if ( [appDelegate isPasscodeValid:passcode] ) {
			appDelegate.willAskForPasscode = NO;
				
			// Go back to view
			[self.navigationController popToRootViewControllerAnimated:YES];
		} else {
			// Show alert indicating the passcode is wrong
			UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Wrong Passcode!", nil) message:[NSString stringWithFormat:NSLocalizedString(@"Please try again. You have used %d of %d attempts before the app auto-closes.", nil), [self.attempts intValue], 3] delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
				
			[alertView show];
		}
	}
}

@end
