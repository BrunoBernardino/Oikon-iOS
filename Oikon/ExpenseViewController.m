//
//  ExpenseViewController.m
//  Oikon
//
//  Created by Bruno Bernardino on 08/06/14.
//  Copyright (c) 2014 emotionLoop. All rights reserved.
//

#import "ExpenseViewController.h"
#import "MainViewController.h"
#import "AppDelegate.h"
#import "Toast/UIView+Toast.h"

// If screen width is bigger than 320, this is a wide screen
#define IS_SCREEN_WIDE ( ([[UIScreen mainScreen] bounds].size.width - 320 > 0) ? YES : NO )
#define SCREEN_WIDTH_DIFFERENCE ([[UIScreen mainScreen] bounds].size.width - 320)

@interface ExpenseViewController ()

@end

@implementation ExpenseViewController

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
	[self setTitle:NSLocalizedString(@"Expense", nil)];
	
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
	
	// Add "Save" button to navigation controller
	UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save", nil) style:UIBarButtonItemStylePlain target:self action:@selector(updateExpense:)];
	self.navigationItem.rightBarButtonItem = saveButton;
	
	// Add bottom border each "field view"
	CALayer *bottomBorderForName = [CALayer layer];
	bottomBorderForName.backgroundColor = [UIColor colorWithRed:0.815686275 green:0.815686275 blue:0.815686275 alpha:1].CGColor;
	bottomBorderForName.frame = CGRectMake(0.0f, self.expenseNameView.frame.size.height, self.expenseNameView.frame.size.width + SCREEN_WIDTH_DIFFERENCE, 0.5f);
	[self.expenseNameView.layer addSublayer:bottomBorderForName];
	
	CALayer *bottomBorderForType = [CALayer layer];
	bottomBorderForType.backgroundColor = [UIColor colorWithRed:0.815686275 green:0.815686275 blue:0.815686275 alpha:1].CGColor;
	bottomBorderForType.frame = CGRectMake(0.0f, self.expenseTypeView.frame.size.height, self.expenseTypeView.frame.size.width + SCREEN_WIDTH_DIFFERENCE, 0.5f);
	[self.expenseTypeView.layer addSublayer:bottomBorderForType];
	
	CALayer *bottomBorderForDate = [CALayer layer];
	bottomBorderForDate.backgroundColor = [UIColor colorWithRed:0.815686275 green:0.815686275 blue:0.815686275 alpha:1].CGColor;
	bottomBorderForDate.frame = CGRectMake(0.0f, self.expenseDateView.frame.size.height, self.expenseDateView.frame.size.width + SCREEN_WIDTH_DIFFERENCE, 0.5f);
	[self.expenseDateView.layer addSublayer:bottomBorderForDate];
	
	CALayer *bottomBorderForValue = [CALayer layer];
	bottomBorderForValue.backgroundColor = [UIColor colorWithRed:0.815686275 green:0.815686275 blue:0.815686275 alpha:1].CGColor;
	bottomBorderForValue.frame = CGRectMake(0.0f, self.expenseValueView.frame.size.height, self.expenseValueView.frame.size.width + SCREEN_WIDTH_DIFFERENCE, 0.5f);
	[self.expenseValueView.layer addSublayer:bottomBorderForValue];
    
    // Look in this view for keyboard actions on expense value
    self.expenseValueTextField.delegate = self;
    
    // Look in this view for keyboard actions on expense name
    self.expenseNameTextField.delegate = self;
	
	// Make sure the date text view will trigger an action in this view controller
	self.expenseDateTextField.delegate = self;
	
	// Make sure the type text view will trigger an action in this view controller
	self.expenseTypeTextField.delegate = self;
	
	// Attach main view controller reference
	NSString *storyboardName = @"Main";
    NSString *language = @"Base";
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *preferred = [[mainBundle preferredLocalizations] objectAtIndex:0];
    if ( [[mainBundle localizations] containsObject:preferred] ) {
        language = preferred;
    }
    
    NSBundle *bundle = [NSBundle bundleWithPath:[mainBundle pathForResource:language ofType:@"lproj"]];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle:bundle];
	self.mainViewControllerReference = [storyboard instantiateViewControllerWithIdentifier:@"MainViewController"];
	
	// Initialize expense data
	[self fillDataFromReceivedExpense];
	
	// Fetch expense types
	[self.mainViewControllerReference getAllExpenseTypes];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// Action for tapping on "return key" for keyboards
- (BOOL) textFieldShouldReturn:(UITextField *)textField {
    // If on name, close the keyboard
    if ( textField == self.expenseNameTextField ) {
        [textField resignFirstResponder];
    }
    
    return YES;
}

-(void)viewWillAppear:(BOOL)animated
{
	// Initialize expense data
	[self fillDataFromReceivedExpense];
	
	[super viewWillAppear:animated];
}

// Close keyboard/pickers when screen is being closed
-(void)viewWillDisappear:(BOOL)animated
{
	// Close keyboard/pickers after save
	[self closeAllKeyboardsAndPickers];
	
	[super viewWillDisappear:animated];
}

// Close keyboard/pickers on tap in screen
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	// Close keyboard/pickers after save
	[self closeAllKeyboardsAndPickers];
}

// Listener for tapping on text views
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    // Show default number keyboard for value text view
    if ( textField == self.expenseValueTextField ) {
        // Add "Done" button
        self.expenseValueTextField.inputAccessoryView = [self getDoneToolbar];
    }

	// Show date picker for date text view
	if ( textField == self.expenseDateTextField ) {
		// Create a date picker for the date field.
		UIDatePicker *datePicker = [[UIDatePicker alloc] init];
		datePicker.datePickerMode = UIDatePickerModeDate;
        
        // Add "Done" button
        self.expenseDateTextField.inputAccessoryView = [self getDoneToolbar];
		
		// Set date to now, if nothing is set
		if ( self.expenseDateTextField.text.length <= 0 ) {
			[datePicker setDate:[NSDate date]];
		} else {
			[datePicker setDate:[self.mainViewControllerReference getDateFromString:self.expenseDateTextField.text]];
		}
		
		[datePicker addTarget:self action:@selector(updateDateField:) forControlEvents:UIControlEventValueChanged];
		
		// If the date field has focus, display a date picker instead of keyboard.
		self.expenseDateTextField.inputView = datePicker;
		
		// Set the text to the date currently displayed by the picker.
		self.expenseDateTextField.text = [self.mainViewControllerReference formatDate:datePicker.date];
	}
	
	// Show list picker for expense type text view
	if ( textField == self.expenseTypeTextField ) {
		CGRect pickerFrame = CGRectMake(0, 44, 0, 0);
		UIPickerView *pickerView = [[UIPickerView alloc] initWithFrame:pickerFrame];
		
		self.expenseTypeTextField.inputView = pickerView;
		
		pickerView.delegate = self;
		pickerView.dataSource = self;
        
        // Add "Done" button
        self.expenseTypeTextField.inputAccessoryView = [self getDoneToolbar];
		
		if ( self.expenseTypeTextField.text.length <= 0 ) {
			self.expenseTypeTextField.text = [self.mainViewControllerReference.expenseTypes[0] valueForKey:@"name"];
		} else {
			NSInteger rowToSelect = (long) [self.mainViewControllerReference getIndexForExpenseTypeName:self.expenseTypeTextField.text];
			
			[pickerView selectRow:rowToSelect inComponent:0 animated:NO];
			[pickerView reloadAllComponents];
		}
	}
}

// Called when the date picker changes.
- (void)updateDateField:(id)sender
{
    UIDatePicker *picker = (UIDatePicker*) self.expenseDateTextField.inputView;
    self.expenseDateTextField.text = [self.mainViewControllerReference formatDate:picker.date];
}

// Prepares data source for expense type picker view
- (NSInteger)numberOfComponentsInPickerView: (UIPickerView *)pickerView
{
	return 1;
}

// Return how many rows the expense type picker has
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
	return self.mainViewControllerReference.expenseTypes.count;
}

// Set the title for each row in the expense type picker
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [self.mainViewControllerReference.expenseTypes[row] valueForKey:@"name"];
}

// Called when an option for the expense type picker is selected
-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row
	  inComponent:(NSInteger)component
{
	self.expenseTypeTextField.text = [self.mainViewControllerReference.expenseTypes[row] valueForKey:@"name"];
}

- (void)fillDataFromReceivedExpense
{
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    numberFormatter.locale = [NSLocale currentLocale];
    [numberFormatter setNumberStyle: NSNumberFormatterDecimalStyle];

	// Parse the values for text from the received object
	NSString *expenseValue = [NSString stringWithFormat:@"%@",[numberFormatter stringFromNumber:[NSNumber numberWithFloat: [[self.currentExpense valueForKey:@"value"] floatValue]]]];
	NSString *expenseName = [self.currentExpense valueForKey:@"name"];
	NSString *expenseType = [self.currentExpense valueForKey:@"type"];
	NSString *expenseDate = [self.mainViewControllerReference formatDate:[self.currentExpense valueForKey:@"date"]];
	
	// Show "uncategorized" if nothing is set
	if ( expenseType.length <= 0 ) {
		expenseType = NSLocalizedString(@"uncategorized", nil);
	}

	// Set the values from the received object
	self.expenseNameTextField.text = expenseName;
	self.expenseTypeTextField.text = expenseType;
	self.expenseDateTextField.text = expenseDate;
	self.expenseValueTextField.text = expenseValue;
}

// Update expense
- (IBAction)updateExpense:(id)sender
{
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    numberFormatter.locale = [NSLocale currentLocale];
    [numberFormatter setNumberStyle: NSNumberFormatterDecimalStyle];
    
    // Replace comma decimal to dot decimal
    if ([numberFormatter.currencyDecimalSeparator isEqual: @"."]) {
        self.expenseValueTextField.text = [self.expenseValueTextField.text stringByReplacingOccurrencesOfString:@"," withString:@"."];
    }
    
    // Replace dot decimal to comma decimal
    if ([numberFormatter.currencyDecimalSeparator isEqual: @","]) {
        self.expenseValueTextField.text = [self.expenseValueTextField.text stringByReplacingOccurrencesOfString:@"." withString:@","];
    }
    
    NSNumber *expenseValue = [numberFormatter numberFromString:self.expenseValueTextField.text];
    NSString *expenseName = self.expenseNameTextField.text;
	NSString *expenseType = self.expenseTypeTextField.text;
	NSDate *expenseDate = [self.mainViewControllerReference getDateFromString:self.expenseDateTextField.text];
    
    //
    // START: Validate fields for common errors
    //
    
    // Check if value is greater than 0
    if ( expenseValue <= 0 ) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Oops!", nil) message:NSLocalizedString(@"Please confirm the value of the expense.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        
        [alertView show];
		
        return;
    }
    
    // Check if the expense name is not empty
    if ( expenseName.length <= 0 ) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Oops!", nil) message:NSLocalizedString(@"Please confirm the name of the expense.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        
        [alertView show];
        
        return;
    }
	
    //
    // END: Validate fields for common errors
    //
	
	// Check if the expense type is empty (if empty or uncategorized, set to nil)
    if ( expenseType.length <= 0 || [expenseType isEqualToString:NSLocalizedString(@"uncategorized", nil)] ) {
        expenseType = nil;
    }
	
	// Check if the expense date is empty (if empty, set to now)
    if ( ! expenseDate ) {
        expenseDate = [NSDate date];
    }
    
    //
    // Save object
    //
    
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    [self.currentExpense setValue: expenseValue forKey:@"value"];
    [self.currentExpense setValue: expenseName forKey:@"name"];
	[self.currentExpense setValue: expenseType forKey:@"type"];
	[self.currentExpense setValue: expenseDate forKey:@"date"];
	
    @try {
        NSError *error;
        [context save:&error];
        
        //UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Expense Updated!", nil) message:NSLocalizedString(@"Your expense was updated successfully.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        
        [self.view makeToast:NSLocalizedString(@"Expense Updated!", nil) duration:1.0 position:CSToastPositionBottom];
        
        //[alertView show];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@", exception);
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Expense Error!", nil) message:NSLocalizedString(@"There was an error updating your expense. Please confirm the value types match.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        
        [alertView show];
    }
	
	// Close keyboard/pickers after save
	[self closeAllKeyboardsAndPickers];
}

// Close keyboards/pickers
- (void)closeAllKeyboardsAndPickers
{
    [self.expenseValueTextField resignFirstResponder];
	[self.expenseNameTextField resignFirstResponder];
	[self.expenseDateTextField resignFirstResponder];
	[self.expenseTypeTextField resignFirstResponder];
    
    [[self view] endEditing:YES];
}

// Get Done Toolbar to add to pickers and keyboard
-(UIToolbar *) getDoneToolbar
{
    // Add "Done" button
    UIToolbar *toolBar= [[UIToolbar alloc] initWithFrame:CGRectMake(0,0,320,44)];
    [toolBar setBarStyle:UIBarStyleDefault];
    UIBarButtonItem *barButtonDone = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", nil)
                                                                      style:UIBarButtonItemStylePlain target:self action:@selector(closeAllKeyboardsAndPickers)];
    
    // Pushes button to the right
    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    toolBar.items = [[NSArray alloc] initWithObjects:flex,barButtonDone,nil];
    barButtonDone.tintColor = [UIColor blackColor];
    
    return toolBar;
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
        [self.mainViewControllerReference getAllExpenseTypes];
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
