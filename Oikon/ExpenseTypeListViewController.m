//
//  ExpenseTypeListViewController.m
//  Oikon
//
//  Created by Bruno Bernardino on 07/06/14.
//  Copyright (c) 2014 emotionLoop. All rights reserved.
//

#import "ExpenseTypeListViewController.h"
#import "ExpenseTypeListViewCell.h"
#import "AppDelegate.h"
#import "Toast/UIView+Toast.h"

@interface ExpenseTypeListViewController ()

@end

@implementation ExpenseTypeListViewController

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
	
	// Add background gradient
	CAGradientLayer *gradient = [CAGradientLayer layer];
	gradient.frame = self.view.bounds;
	gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor whiteColor] CGColor], (id)[[UIColor colorWithRed:0.878431373 green:0.878431373 blue:0.878431373 alpha:1] CGColor], nil];
	[self.view.layer insertSublayer:gradient atIndex:0];
	
	// Set title
	[self setTitle:NSLocalizedString(@"Expense Types", nil)];
	
	// Make the navigationbar color white, background blue
    UIColor *blueColor = [UIColor colorWithRed:62/255.0 green:138/255.0 blue:229/255.0 alpha:1];
	UIColor *whiteColor = [UIColor whiteColor];
    self.navigationController.navigationBar.barTintColor = blueColor;
	self.navigationController.navigationBar.tintColor = whiteColor;
    self.navigationController.navigationBar.translucent = YES;
    
    // Listen for iCloud changes (after it's done)
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(iCloudDidUpdate:) name:NSPersistentStoreCoordinatorStoresDidChangeNotification object:nil];
	
	// Make the button rounded
	self.addExpenseTypeButton.layer.cornerRadius = 4;
	
	// Tell the table view to look for data in this view controller
	self.expenseTypeListTableView.dataSource = self;
	
	// Make sure the table view will trigger an action in this view controller
	self.expenseTypeListTableView.delegate = self;
	
	// Bind tap on add expense type button
	[self.addExpenseTypeButton addTarget:self action:@selector(addNewExpenseType:) forControlEvents:UIControlEventTouchUpInside];
	
	// Set default expenseTypes array
	self.expenseTypes = [NSMutableArray alloc];
	
	// Set expense type being updated to nil
	self.expenseTypeBeingUpdated = nil;
	
	// Fetch expenses
	[self getAllExpenseTypes];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.expenseTypes.count;
}


// Format & Display Cell Rows
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *CellIdentifier = @"expenseTypeTableCell";
	
    ExpenseTypeListViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
	
	long row = indexPath.row;
    
	NSString *expenseTypeName = [ self.expenseTypes[row] valueForKey:@"name" ];
    NSString *expenseTypeExpenseCount = [ NSString stringWithFormat:@"%ld",(long)[self getExpenseTypeCount:expenseTypeName] ];
	
	cell.nameLabel.text = expenseTypeName;
	cell.expensesCountLabel.text = expenseTypeExpenseCount;
    
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// Ask for changing name in modal
	self.expenseTypeBeingUpdated = [self.expenseTypes objectAtIndex:indexPath.row];
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Update Expense Type", nil) message:NSLocalizedString(@"Please type the new name of the expense type", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"Update", nil), nil];
	alert.alertViewStyle = UIAlertViewStylePlainTextInput;
	UITextField *textField = [alert textFieldAtIndex:0];
	// Set the current name in the modal
	textField.text = [self.expenseTypeBeingUpdated valueForKey:@"name"];
	// Set capitalization for text field
	textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
	textField.autocorrectionType = UITextAutocorrectionTypeYes;
	[alert show];
}

// Allow expense types to be deleted
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
	return YES;
}

// Delete expense type
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if ( editingStyle == UITableViewCellEditingStyleDelete ) {
		AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
		
		NSManagedObjectContext *context = [appDelegate managedObjectContext];
		NSManagedObject *expenseTypeToRemove = self.expenseTypes[ indexPath.row ];
		NSString *expenseTypeNameToRemove = [expenseTypeToRemove valueForKey:@"name"];
		
		// Delete from core data
		[context deleteObject:expenseTypeToRemove];
		[context save:nil];
		
		// Change all expenses with this expense type to nil
		[self removeExpenseTypeFromExpenses:expenseTypeNameToRemove];

		// Delete from view
		[self.expenseTypes removeObjectAtIndex:indexPath.row];
		[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
		
		// Reload data
		[self getAllExpenseTypes];
	} else {
		NSLog(@"Unhandled editing style!");
	}
}

// Try to save or update expense type
- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	NSString *buttonTitle = [alertView buttonTitleAtIndex:buttonIndex];

	// Add new expense type
	if ( [buttonTitle isEqualToString:NSLocalizedString(@"Add", nil)] ) {
		[self saveExpenseType:[[alertView textFieldAtIndex:0] text]];
	}
	
	// Updade expense type
	if ( [buttonTitle isEqualToString:NSLocalizedString(@"Update", nil)] ) {
		[self updateExpenseType:[[alertView textFieldAtIndex:0] text]];
	}
}

-(void)viewWillAppear:(BOOL)animated
{
	// Initialize expense types
	[self getAllExpenseTypes];
	
	[super viewWillAppear:animated];
}

// Save expense
- (IBAction)addNewExpenseType:(id)sender
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Add New Expense Type", nil) message:NSLocalizedString(@"Please type the name of the new expense type", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"Add", nil), nil];
	alert.alertViewStyle = UIAlertViewStylePlainTextInput;
	
	// Set capitalization for text field
	UITextField *textField = [alert textFieldAtIndex:0];
	textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
	textField.autocorrectionType = UITextAutocorrectionTypeYes;
	[alert show];
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
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
	[request setSortDescriptors:sortDescriptors];
	
	@try {
		NSError *error;
		NSArray *objects = [context executeFetchRequest:request error:&error];
		
		self.expenseTypes = [NSMutableArray arrayWithArray:objects];
	}
	@catch (NSException *exception) {
		NSLog( @"Exception: %@", exception );
		
		self.expenseTypes = [NSMutableArray arrayWithArray:@[]];
	}
	
	// Reload view with new data
	[self.expenseTypeListTableView reloadData];
}

// Get a count of all expenses for a given expense type
- (NSInteger)getExpenseTypeCount:(NSString *)expenseTypeName
{
	AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
	
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
	
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Expense" inManagedObjectContext:context];
	
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
	[request setEntity:entityDesc];
	
	// Add expense type name to search
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(type = %@)", expenseTypeName];
    [request setPredicate:predicate];
	
	@try {
		NSError *error;
		NSArray *objects = [context executeFetchRequest:request error:&error];
		
		return objects.count;
	}
	@catch (NSException *exception) {
		NSLog( @"Exception: %@", exception );
		
		return 0;
	}
}

// Get a count of all expense types with a given name
- (NSInteger)getExpenseTypeCountWithName:(NSString *)expenseTypeName caseSensitive:(BOOL)isCaseSensitive
{
	AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
	
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
	
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"ExpenseType" inManagedObjectContext:context];
	
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
	[request setEntity:entityDesc];
	
	NSPredicate *predicate = [NSPredicate alloc];
	
	// Add expense type name to search
	if ( isCaseSensitive ) {
		predicate = [NSPredicate predicateWithFormat:@"(name = %@)", expenseTypeName];
	} else {
		predicate = [NSPredicate predicateWithFormat:@"(name =[c] %@)", expenseTypeName];
	}

    [request setPredicate:predicate];
	
	@try {
		NSError *error;
		NSArray *objects = [context executeFetchRequest:request error:&error];
		
		return objects.count;
	}
	@catch (NSException *exception) {
		NSLog( @"Exception: %@", exception );
		
		return 0;
	}
}

// Save expense type
- (void)saveExpenseType:(NSString *)expenseTypeName
{
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    //
    // START: Validate fields for common errors
    //
    
    // Check if the expense type name is not empty
    if ( expenseTypeName.length <= 0 ) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Oops!", nil) message:NSLocalizedString(@"Please confirm the name of the expense type.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        
        [alertView show];
        
        return;
    }
	
	// Check if the expense type name is "uncategorized" (case insensitive, not allowed)
	if ( [expenseTypeName caseInsensitiveCompare:NSLocalizedString(@"uncategorized", nil)] == NSOrderedSame ) {
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Oops!", nil) message:NSLocalizedString(@"Your expense type can't be called 'uncategorized'.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        
        [alertView show];
        
        return;
	}
	
	// Check if an expense type with that name already exists
	if ( [self getExpenseTypeCountWithName:expenseTypeName caseSensitive:NO] > 0 ) {
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Oops!", nil) message:NSLocalizedString(@"An expense type with the same name already exists.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        
        [alertView show];
        
        return;
	}
	
    //
    // END: Validate fields for common errors
    //
    
    //
    // Save object
    //
    
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    NSManagedObject *newExpenseType;
    newExpenseType = [NSEntityDescription
                  insertNewObjectForEntityForName:@"ExpenseType"
                  inManagedObjectContext:context];
    [newExpenseType setValue:expenseTypeName forKey:@"name"];
	
    @try {
        NSError *error;
        [context save:&error];
        
        // Reload data
		[self getAllExpenseTypes];
        
        //UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Expense Type Added!", nil) message:NSLocalizedString(@"Your expense type was added successfully.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        
        [self.view makeToast:NSLocalizedString(@"Expense Type Added!", nil) duration:1.0 position:CSToastPositionBottom];
        
        //[alertView show];
		
		// Scroll to top
		[self.expenseTypeListTableView setContentOffset:CGPointMake(0,0) animated:YES];
    }
    @catch (NSException *exception) {
        NSLog( @"Exception: %@", exception );
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Expense Type Error!", nil) message:NSLocalizedString(@"There was an error adding your expense type. Please confirm the name does not already exist.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        
        [alertView show];
    }
}

// Update expense type
- (void)updateExpenseType:(NSString *)expenseTypeName
{
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    //
    // START: Validate fields for common errors
    //
	
	// Check if there's an expense type being updated
	if ( ! self.expenseTypeBeingUpdated ) {
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Oops!", nil) message:NSLocalizedString(@"We were not able to find the expense type you selected. Please try again.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        
        [alertView show];
        
        return;
	}
    
    // Check if the expense type name is not empty
    if ( expenseTypeName.length <= 0 ) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Oops!", nil) message:NSLocalizedString(@"Please confirm the name of the expense type.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        
        [alertView show];
        
        return;
    }
	
	// Check if the expense type name is "uncategorized" (case insensitive, not allowed)
	if ( [expenseTypeName caseInsensitiveCompare:NSLocalizedString(@"uncategorized", nil)] == NSOrderedSame ) {
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Oops!", nil) message:NSLocalizedString(@"Your expense type can't be called 'uncategorized'.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        
        [alertView show];
        
        return;
	}
	
	// Check if the name is the exact same (case sensitive, in case people want to change capitalization)
	if ( [expenseTypeName isEqualToString:[self.expenseTypeBeingUpdated valueForKey:@"name"]] ) {
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Oops!", nil) message:NSLocalizedString(@"The new name has to be different from the current one.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        
        [alertView show];
        
        return;
	}
	
	// Check if an expense type with that new name already exists
	if ( [self getExpenseTypeCountWithName:expenseTypeName caseSensitive:YES] > 0 ) {
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Oops!", nil) message:NSLocalizedString(@"An expense type with the same name already exists.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        
        [alertView show];
        
        return;
	}
	
    //
    // END: Validate fields for common errors
    //
    
    //
    // Update object
    //
    
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    [self.expenseTypeBeingUpdated setValue:expenseTypeName forKey:@"name"];
	
    @try {
        NSError *error;
        [context save:&error];
        
        // Reload data
		[self getAllExpenseTypes];
        
        //UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Expense Type Updated!", nil) message:NSLocalizedString(@"Your expense type was updated successfully.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        
        [self.view makeToast:NSLocalizedString(@"Expense Type Updated!", nil) duration:1.0 position:CSToastPositionBottom];
        
        //[alertView show];
		
		// Scroll to top
		[self.expenseTypeListTableView setContentOffset:CGPointMake(0,0) animated:YES];
    }
    @catch (NSException *exception) {
        NSLog( @"Exception: %@", exception );
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Expense Type Error!", nil) message:NSLocalizedString(@"There was an error adding your expense type. Please confirm the new name does not already exist.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        
        [alertView show];
    }
	
	// Set expense type being updated to nil
	self.expenseTypeBeingUpdated = nil;
}

// Change all expenses with this expense type to nil
- (void) removeExpenseTypeFromExpenses:(NSString *)expenseTypeName
{
	AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
	
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
	
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Expense" inManagedObjectContext:context];
	
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
	[request setEntity:entityDesc];
	
	// Add expense type name to search
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(type = %@)", expenseTypeName];
    [request setPredicate:predicate];
	
	@try {
		NSError *error;
		NSArray *objects = [context executeFetchRequest:request error:&error];
		
		for (NSManagedObject *object in objects) {
			[object setValue:nil forKey:@"type"];
		}
		
		[context save:&error];
	}
	@catch (NSException *exception) {
		NSLog( @"Exception: %@", exception );
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
        [self getAllExpenseTypes];
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
