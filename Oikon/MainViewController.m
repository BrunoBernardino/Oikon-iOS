//
//  MainViewController.m
//  Oikon
//
//  Created by Bruno Bernardino on 25/05/14.
//  Copyright (c) 2014 emotionLoop. All rights reserved.
//

#import "MainViewController.h"
#import "ListViewController.h"
#import "AppDelegate.h"
#import "Toast/UIView+Toast.h"

// If screen height is bigger than 568, this is a tall screen
#define IS_SCREEN_TALL ( ([[UIScreen mainScreen] bounds].size.height - 568 > 0) ? YES : NO )
#define SCREEN_HEIGHT_DIFFERENCE ([[UIScreen mainScreen] bounds].size.height - 568)

@interface MainViewController ()

@end

@implementation MainViewController

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
	
	// Listen for resume (for passcode)
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationBecameActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
	
	// Listen for iCloud changes (when they will happen)
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(iCloudWillUpdate:) name:NSPersistentStoreCoordinatorStoresWillChangeNotification object:nil];
	
	// Listen for iCloud changes (after it's done)
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(iCloudDidUpdate:) name:NSPersistentStoreCoordinatorStoresDidChangeNotification object:nil];
	
	// Set the status bar to white
	[self setNeedsStatusBarAppearanceUpdate];
	
	// Add background gradient
	CAGradientLayer *gradient = [CAGradientLayer layer];
	gradient.frame = self.view.bounds;
	gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor whiteColor] CGColor], (id)[[UIColor colorWithRed:0.878431373 green:0.878431373 blue:0.878431373 alpha:1] CGColor], nil];
	[self.view.layer insertSublayer:gradient atIndex:0];
	
	// Set title
	[self setTitle:NSLocalizedString(@"Oikon", nil)];
    
    // Make the navigationbar color white, background blue
    UIColor *blueColor = [UIColor colorWithRed:62/255.0 green:138/255.0 blue:229/255.0 alpha:1];
	UIColor *whiteColor = [UIColor whiteColor];
    [[UINavigationBar appearance] setBarTintColor:blueColor];
    self.navigationController.navigationBar.barTintColor = blueColor;
	self.navigationController.navigationBar.tintColor = whiteColor;
    self.navigationController.navigationBar.translucent = YES;
	
	// Set placeholder colors to black
	//UIColor *blackColor = [UIColor blackColor];
	
	//self.expenseValueTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"9.99", nil) attributes:@{NSForegroundColorAttributeName: blackColor}];
	
	//self.expenseNameTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"coffee", nil) attributes:@{NSForegroundColorAttributeName: blackColor}];
	
	//self.expenseDateTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"today", nil) attributes:@{NSForegroundColorAttributeName: blackColor}];
	
	//self.expenseTypeTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"uncategorized", nil) attributes:@{NSForegroundColorAttributeName: blackColor}];
	
	// Set placeholder in locale for value
	NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    numberFormatter.locale = [NSLocale currentLocale];
    [numberFormatter setNumberStyle: NSNumberFormatterDecimalStyle];
	
	NSNumber *placeholderValue = [[NSNumber alloc] initWithDouble:9.99];
    
    self.expenseValueTextField.placeholder = [numberFormatter stringFromNumber:placeholderValue];
	
	// Make the buttons rounded
	self.simpleAddExpenseButton.layer.cornerRadius = 4;
	self.advancedAddExpenseButton.layer.cornerRadius = 4;
	
	// Bind tap on add expense buttons
	[self.simpleAddExpenseButton addTarget:self action:@selector(saveExpense:) forControlEvents:UIControlEventTouchUpInside];
	[self.advancedAddExpenseButton addTarget:self action:@selector(saveExpense:) forControlEvents:UIControlEventTouchUpInside];
    
    // Add "Add" button to navigation controller
	UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Add", nil) style:UIBarButtonItemStylePlain target:self action:@selector(saveExpense:)];
	self.navigationItem.rightBarButtonItem = addButton;
	
	// Bind tap on option buttons
	[self.moreOptionsButton addTarget:self action:@selector(scrollToMore:) forControlEvents:UIControlEventTouchUpInside];
	[self.lessOptionsButton addTarget:self action:@selector(scrollToLess:) forControlEvents:UIControlEventTouchUpInside];
    
    // Add menu button to nav bar
    UIBarButtonItem *menuBarButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menu"] style:UIBarButtonItemStylePlain target:self action:@selector(showMenu:)];
    [menuBarButton setTintColor:[UIColor whiteColor]];
    
    self.navigationItem.leftBarButtonItems = [[NSArray alloc] initWithObjects:menuBarButton, nil];
    
    // Look in this view for keyboard actions on expense value
    self.expenseValueTextField.delegate = self;

    // Look in this view for keyboard actions on expense name
    self.expenseNameTextField.delegate = self;
	
	// Make sure the date text view will trigger an action in this view controller
	self.expenseDateTextField.delegate = self;
	
	// Make sure the type text view will trigger an action in this view controller
	self.expenseTypeTextField.delegate = self;
	
    // Set image paths
    [self.moreOptionsImageView setImage:[UIImage imageNamed:@"more-options"]];
    [self.lessOptionsImageView setImage:[UIImage imageNamed:@"less-options"]];
    
	// Initialize expense types
	[self getAllExpenseTypes];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
			[datePicker setDate:[self getDateFromString:self.expenseDateTextField.text]];
		}

		[datePicker addTarget:self action:@selector(updateDateField:) forControlEvents:UIControlEventValueChanged];
	
		// If the date field has focus, display a date picker instead of keyboard.
		self.expenseDateTextField.inputView = datePicker;

		// Set the text to the date currently displayed by the picker.
		self.expenseDateTextField.text = [self formatDate:datePicker.date];
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
			self.expenseTypeTextField.text = [self.expenseTypes[0] valueForKey:@"name"];
		} else {
			NSInteger rowToSelect = (long) [self getIndexForExpenseTypeName:self.expenseTypeTextField.text];
			
			[pickerView selectRow:rowToSelect inComponent:0 animated:NO];
			[pickerView reloadAllComponents];
		}
	}
}

// Called when the date picker changes.
- (void)updateDateField:(id)sender
{
    UIDatePicker *picker = (UIDatePicker*) self.expenseDateTextField.inputView;
    self.expenseDateTextField.text = [self formatDate:picker.date];
}


// Formats the date chosen with the date picker
- (NSString *)formatDate:(NSDate *)date
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	NSLocale* locale = [[NSLocale alloc] initWithLocaleIdentifier:NSLocalizedString(@"en_US", nil)];
	[dateFormatter setLocale:locale];
	[dateFormatter setDateStyle:NSDateFormatterShortStyle];
    [dateFormatter setDateFormat:NSLocalizedString(@"MMM, d, yyyy", nil)];
    NSString *formattedDate = [dateFormatter stringFromDate:date];
    return formattedDate;
}

// Return a date from a string
- (NSDate *)getDateFromString:(NSString *)date
{
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	NSLocale* locale = [[NSLocale alloc] initWithLocaleIdentifier:NSLocalizedString(@"en_US", nil)];
	[dateFormatter setLocale:locale];
	[dateFormatter setDateFormat:NSLocalizedString(@"MMM, d, yyyy", nil)];
	return [dateFormatter dateFromString:date];
}

// Prepares data source for expense type picker view
- (NSInteger)numberOfComponentsInPickerView: (UIPickerView *)pickerView
{
	return 1;
}

// Return how many rows the expense type picker has
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
	return self.expenseTypes.count;
}

// Set the title for each row in the expense type picker
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [self.expenseTypes[row] valueForKey:@"name"];
}

// Called when an option for the expense type picker is selected
-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row
	  inComponent:(NSInteger)component
{
	self.expenseTypeTextField.text = [self.expenseTypes[row] valueForKey:@"name"];
}

// Action for tapping on "return key" for keyboards
- (BOOL) textFieldShouldReturn:(UITextField *)textField {
    // If on name, close the keyboard
    if ( textField == self.expenseNameTextField ) {
        [textField resignFirstResponder];
    }

    return YES;
}

// Get all expenses types
- (void)getAllExpenseTypes
{
	AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
	
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
	
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"ExpenseType" inManagedObjectContext:context];
	
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
	
	// Sort expense types by name
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
	[request setSortDescriptors:sortDescriptors];
	
	self.expenseTypes = [[NSMutableArray alloc] init];
	[self.expenseTypes addObject:@{@"name":NSLocalizedString(@"uncategorized", nil)}];
	
	@try {
		NSError *error;
		NSArray *objects = [context executeFetchRequest:request error:&error];
		
		//NSLog( @"%lu expense types found", (unsigned long)[objects count] );
		
		[self.expenseTypes addObjectsFromArray:objects];
	}
	@catch (NSException *exception) {
		NSLog( @"Exception: %@", exception );
	}
}

// Scroll to bottom (more options)
- (void)scrollToMore:(UIButton *)sender
{
    int heightOfMoreView = self.moreOptionsPageView.frame.origin.y - 64;
	[self.scrollView setContentOffset:CGPointMake(0,heightOfMoreView) animated:YES];
}

// Scroll to top (less options)
- (void)scrollToLess:(UIButton *)sender
{
	[self.scrollView setContentOffset:CGPointMake(0,-64) animated:YES];
}

// Save expense
- (IBAction)saveExpense:(id)sender
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
    NSString *expenseName = [self.expenseNameTextField.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
	NSString *expenseType = self.expenseTypeTextField.text;
	NSDate *expenseDate = [self getDateFromString:self.expenseDateTextField.text];
    
    //
    // START: Validate fields for common errors
    //
    
    // Check if value has been set (and allow negatives!)
    if ( expenseValue == 0 ) {
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
    NSManagedObject *newExpense;
    newExpense = [NSEntityDescription
                  insertNewObjectForEntityForName:@"Expense"
                  inManagedObjectContext:context];
    [newExpense setValue: expenseValue forKey:@"value"];
    [newExpense setValue: expenseName forKey:@"name"];
	[newExpense setValue: expenseType forKey:@"type"];
	[newExpense setValue: expenseDate forKey:@"date"];

    @try {
        NSError *error;
        [context save:&error];
        
        // Cleanup fields
        self.expenseValueTextField.text = @"";
        self.expenseNameTextField.text = @"";
        self.expenseDateTextField.text = @"";
        self.expenseTypeTextField.text = @"";
        
        //UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Expense Added!", nil) message:NSLocalizedString(@"Your expense was added successfully.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        
        [self.view makeToast:NSLocalizedString(@"Expense Added!", nil) duration:1.0 position:CSToastPositionBottom];
        
        //[alertView show];
		
		// Scroll to top
		[self.scrollView setContentOffset:CGPointMake(0,-64) animated:YES];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@", exception);
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Expense Error!", nil) message:NSLocalizedString(@"There was an error adding your expense. Please confirm the value types match.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        
        [alertView show];
    }
	
	// Close keyboard/pickers after save
	[self closeAllKeyboardsAndPickers];
	
	[[self view] endEditing:YES];
}

- (NSInteger)getIndexForExpenseTypeName:(NSString *)expenseTypeName
{
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name = %@", expenseTypeName];
	NSUInteger index = [self.expenseTypes indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop) {
		return [predicate evaluateWithObject:obj];
	}];
	
	return (int) index;
}

// Show Menu
- (void)showMenu:(id)sender
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil
													otherButtonTitles:
								  NSLocalizedString(@"Manage Expense Types", nil),
								  NSLocalizedString(@"View Past Expenses", nil),
								  NSLocalizedString(@"Settings", nil),
								  nil
							];
    
    [actionSheet showInView:self.view];
}

// Actually go into these viewcontrollers
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *storyboardName = @"Main";
    NSString *language = @"Base";
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *preferred = [[mainBundle preferredLocalizations] objectAtIndex:0];
    if ( [[mainBundle localizations] containsObject:preferred] ) {
        language = preferred;
    }

    NSBundle *bundle = [NSBundle bundleWithPath:[mainBundle pathForResource:language ofType:@"lproj"]];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle:bundle];

    // 0: Manage Expense Types
    // 1: View Past Expenses
    // 2: Settings
    // 3: Cancel
    
	// Manage Expense Types
    if ( buttonIndex == 0 ) {
        UIViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"ExpenseTypeListViewController"];

        [self.navigationController pushViewController:vc animated:YES];
    }
	
	// View Past Expenses
	if ( buttonIndex == 1 ) {
        UIViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"ListViewController"];
		
        [self.navigationController pushViewController:vc animated:YES];
    }
	
	// Settings
	if ( buttonIndex == 2 ) {
        UIViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"SettingsViewController"];
		
        [self.navigationController pushViewController:vc animated:YES];
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

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
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

// Close keyboard/pickers on tap in screen
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	[self closeAllKeyboardsAndPickers];
}

-(void)viewWillDisappear:(BOOL)animated
{
	[self closeAllKeyboardsAndPickers];
	
	[super viewWillDisappear:animated];
}

-(void)viewWillAppear:(BOOL)animated
{
	// Initialize expense types
	[self getAllExpenseTypes];
    
	[super viewWillAppear:animated];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

-(void)viewDidLayoutSubviews
{
    // If there's an input being focused, don't change anything
    if (
        [self.expenseValueTextField isFirstResponder]
        || [self.expenseNameTextField isFirstResponder]
        || [self.expenseDateTextField isFirstResponder]
        || [self.expenseTypeTextField isFirstResponder]
        ) {
        [super viewDidLayoutSubviews];
        
        // Scroll to the right place so things don't look too messed up
        if (
            [self.expenseValueTextField isFirstResponder]
            || [self.expenseNameTextField isFirstResponder]
            ) {
            [self scrollToLess:nil];
        } else {
            [self scrollToMore:nil];
        }

        return;
    }
    
    // If screen is tall, move some things around
    if ( IS_SCREEN_TALL == YES ) {
        NSLog(@"Screen height difference = %d", (int)SCREEN_HEIGHT_DIFFERENCE);
        
        /*// Increase the height of the less options view
         NSLog(@"Increasing the height of the less options view");
         CGRect newLessOptionsViewFrame = self.lessOptionsPageView.frame;
         newLessOptionsViewFrame.size.height = newLessOptionsViewFrame.size.height + SCREEN_HEIGHT_DIFFERENCE;
         [self.lessOptionsPageView setFrame:CGRectMake(newLessOptionsViewFrame.origin.x, newLessOptionsViewFrame.origin.y, newLessOptionsViewFrame.size.width, newLessOptionsViewFrame.size.height)];*/
        
        /*// Update the bounds of the more options view
         CGRect newMoreOptionsViewBounds = self.moreOptionsPageView.bounds;
         newMoreOptionsViewBounds.size.height = newMoreOptionsViewBounds.size.height + (SCREEN_HEIGHT_DIFFERENCE / 2);
         [self.moreOptionsPageView setBounds:CGRectMake(newMoreOptionsViewBounds.origin.x, newMoreOptionsViewBounds.origin.y, newMoreOptionsViewBounds.size.width, newMoreOptionsViewBounds.size.height)];*/
        
        /*// Update Y for the more options view
         NSLog(@"Updating y for the more options view");
         CGRect newMoreOptionsViewFrame = self.moreOptionsPageView.frame;
         newMoreOptionsViewFrame.origin.y = newMoreOptionsViewFrame.origin.y + SCREEN_HEIGHT_DIFFERENCE;
         [self.moreOptionsPageView setFrame:CGRectMake(newMoreOptionsViewFrame.origin.x, newMoreOptionsViewFrame.origin.y, newMoreOptionsViewFrame.size.width, newMoreOptionsViewFrame.size.height)];*/
        
        // Update the frame of the groupped view
        //NSLog(@"Make the groupped view taller");
        //CGRect newGroupedViewFrame = self.groupedView.frame;
        //newGroupedViewFrame.size.height = newGroupedViewFrame.size.height + SCREEN_HEIGHT_DIFFERENCE * 2;
        //[self.groupedView setFrame:CGRectMake(newGroupedViewFrame.origin.x, newGroupedViewFrame.origin.y, newGroupedViewFrame.size.width, newGroupedViewFrame.size.height)];
        
        // Match the scrollview
        //NSLog(@"Matching the height of the scrollview");
        //[self.scrollView setContentSize:CGSizeMake(newGroupedViewFrame.size.width, newGroupedViewFrame.size.height)];
        
        //[self.groupedView setBackgroundColor:[UIColor blueColor]];
        //[self.moreOptionsPageView setBackgroundColor:[UIColor blackColor]];
    } else {
        // Update Y for the more options view
        NSLog(@"Updating y for the scroll view");
        
        NSLog(@"%d", (int)SCREEN_HEIGHT_DIFFERENCE);
        CGRect newFrame = self.groupedView.frame;
        
        // iPhone 4 & 4S
        if ( SCREEN_HEIGHT_DIFFERENCE < -80 ) {
            NSLog(@"iPhone 4 & 4S");
            newFrame.origin.y = 0;
            [self.scrollView setFrame:CGRectMake(self.scrollView.frame.origin.x, newFrame.origin.y, self.scrollView.frame.size.width, newFrame.size.height)];
            [self.scrollView setContentSize:CGSizeMake(newFrame.size.width, newFrame.size.height)];
        } else {
            NSLog(@"iPhone 5 & 5S");
            // iPhone 5 & 5S
            newFrame.origin.y = 0;
            newFrame.size.height = newFrame.size.height + 20;
            
            [self.scrollView setFrame:CGRectMake(self.scrollView.frame.origin.x, newFrame.origin.y, self.scrollView.frame.size.width, newFrame.size.height)];
            //[self.scrollView setContentSize:CGSizeMake(newFrame.size.width, newFrame.size.height)];
        }
    }

    [super viewDidLayoutSubviews];
}

// Hide keyboard when return key is pressed
-(IBAction)textFieldReturn:(id)sender
{
    [sender resignFirstResponder];
}

// Listen if the app was resumed (for passcode)
-(IBAction)applicationBecameActive:(id)sender
{
	double delayInSeconds = 0.1;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		// Ask for Passcode if Necessary
		[self askForPasscodeIfNecessary];
	});
}

// Ask for passcode if necessary
- (void)askForPasscodeIfNecessary
{
	AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
	
	NSString *storyboardName = @"Main";
    NSString *language = @"Base";
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *preferred = [[mainBundle preferredLocalizations] objectAtIndex:0];
    if ( [[mainBundle localizations] containsObject:preferred] ) {
        language = preferred;
    }
    
    NSBundle *bundle = [NSBundle bundleWithPath:[mainBundle pathForResource:language ofType:@"lproj"]];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle:bundle];
	
	UIViewController *currentViewController = self.navigationController.visibleViewController;
	UIViewController *passcodeViewController = [storyboard instantiateViewControllerWithIdentifier:@"PasscodeViewController"];
	
	if ( [appDelegate needsToShowPasscode] && ! [currentViewController.title isEqual:NSLocalizedString(@"Unlock App", nil)] ) {
		NSLog(@"PUSHING FOR PASSCODE VIEW");
        [self.navigationController pushViewController:passcodeViewController animated:NO];
	} else {
		NSLog(@"## DOES NOT NEED PASSCODE ##");
	}
}

// iCloud will update
-(IBAction)iCloudWillUpdate:(id)sender
{
	NSLog(@"iCloud WILL update");
	
	AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];

	[appDelegate setiCloudStartSyncDate];
}

// iCloud did update
-(IBAction)iCloudDidUpdate:(id)sender
{
    NSLog(@"iCloud DID update");
	
	AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
	
	[appDelegate setiCloudEndSyncDate];
    
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
        [self getAllExpenseTypes];
    }
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

@end
