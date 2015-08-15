//
//  ListViewController.m
//  Oikon
//
//  Created by Bruno Bernardino on 25/05/14.
//  Copyright (c) 2014 emotionLoop. All rights reserved.
//

#import "ListViewController.h"
#import "ExpenseViewController.h"
#import "MainViewController.h"
#import "ListViewCell.h"
#import "AppDelegate.h"

@interface ListViewController ()

@end

@implementation ListViewController

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
	[self setTitle:NSLocalizedString(@"Past Expenses", nil)];
	
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
	
	// Add "Export" button to navigation controller
	UIBarButtonItem *exportButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(showExportExpenseOptions:)];
	self.navigationItem.rightBarButtonItem = exportButton;
    
    // Allow tapping on "Type" table header label to filter by expense types
    UITapGestureRecognizer *typeTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showExpenseTypeFilter)];
    [self.tableHeaderType addGestureRecognizer:typeTapGesture];
    
    // Allow tapping on "Name" table header label to filter by expense name
    UITapGestureRecognizer *nameTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showExpenseNameFilter:)];
    [self.tableHeaderName addGestureRecognizer:nameTapGesture];
	
	// Tell the table view to look for data in this view controller
	self.expensesTableView.dataSource = self;
	
	// Make sure the table view will trigger an action in this view controller
	self.expensesTableView.delegate = self;
	
	// Make sure the "from date" text view will trigger an action in this view controller
	self.fromDateTextView.delegate = self;
	
	// Make sure the "to date" text view will trigger an action in this view controller
	self.toDateTextView.delegate = self;
	
	// Set default expenses array
	self.expenses = [NSMutableArray alloc];
    
    // Fetch previous search dates
    [self fetchSearchSettings];
	
	// Set default from and to dates to the current month (first to last day), if none was set before
	if ( ! self.currentFromDate || ! self.currentToDate ) {
		[self setDefaultSearchDates];
	}
	
	// Fetch expenses
	[self getAllExpenses];
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
    return self.expenses.count;
}


// Format & Display Cell Rows
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *CellIdentifier = @"expenseTableCell";

    ListViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
		
	long row = indexPath.row;
    
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    numberFormatter.locale = [NSLocale currentLocale];
    [numberFormatter setNumberStyle: NSNumberFormatterDecimalStyle];
	
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:NSLocalizedString(@"MMM, d", nil)];
	NSLocale* locale = [[NSLocale alloc] initWithLocaleIdentifier:NSLocalizedString(@"en_US", nil)];
	[dateFormatter setLocale:locale];
    
    NSString *expenseValue = [NSString stringWithFormat:@"%@",[numberFormatter stringFromNumber:[NSNumber numberWithFloat: [[self.expenses[row] valueForKey:@"value"] floatValue]]]];
    NSString *expenseName = [ self.expenses[row] valueForKey:@"name" ];
	NSString *expenseType = [ self.expenses[row] valueForKey:@"type" ];
	NSString *expenseDate = [dateFormatter stringFromDate:[self.expenses[row] valueForKey:@"date"]];
	
	if ( expenseType.length <= 0 ) {
		expenseType = @"—";
	}
	
	if ( expenseDate.length <= 0 ) {
		expenseDate = @"—";
	}
	
	cell.nameLabel.text = expenseName;
	cell.typeLabel.text = expenseType;
	cell.dateLabel.text = expenseDate;
	cell.valueLabel.text = expenseValue;
    
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	self.selectedExpense = self.expenses[ indexPath.row ];
	
	//[self.navigationController pushViewController:vc animated:YES];
	[self performSegueWithIdentifier:@"showExpense" sender:self];
}

// Allow expenses to be deleted
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
	return YES;
}

// Delete expense
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if ( editingStyle == UITableViewCellEditingStyleDelete ) {
		AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
		
		NSManagedObjectContext *context = [appDelegate managedObjectContext];
		
		// Delete from core data
		[context deleteObject:[self.expenses objectAtIndex:indexPath.row]];
		[context save:nil];
		
		// Delete from view
		[self.expenses removeObjectAtIndex:indexPath.row];
		[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
		
		// Reload data
		[self getAllExpenses];
	} else {
		NSLog(@"Unhandled editing style!");
	}
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *touch = [[event allTouches] anyObject];

	// Set action for tapping the "from date" view
	if ( touch.view == self.fromDateView ) {
		// Trigger date picker
		[self.fromDateTextView becomeFirstResponder];
	}
	
	// Set action for tapping the "to date" view
	if ( touch.view == self.toDateView ) {
		// Trigger date picker
		[self.toDateTextView becomeFirstResponder];
	}
}

// Listener for tapping on text views
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
	// Create a date picker for the date field.
	UIDatePicker *datePicker = [[UIDatePicker alloc] init];
	datePicker.datePickerMode = UIDatePickerModeDate;

	// Show date picker for "from date" text view
	if ( textField == self.fromDateTextView ) {
		// Set date
		[datePicker setDate:self.currentFromDate];
		
		[datePicker addTarget:self action:@selector(updateFromDateField:) forControlEvents:UIControlEventValueChanged];
		
		// If the date field has focus, display a date picker instead of keyboard.
		self.fromDateTextView.inputView = datePicker;
        
        // Add "Done" button
        self.fromDateTextView.inputAccessoryView = [self getDoneToolbar];
		
		// Set the text to the date currently displayed by the picker.
		self.fromDateTextView.text = [self formatDate:datePicker.date];
	}
	
	// Show date picker for "to date" text view
	if ( textField == self.toDateTextView ) {
		// Set date
		[datePicker setDate:self.currentToDate];
		
		[datePicker addTarget:self action:@selector(updateToDateField:) forControlEvents:UIControlEventValueChanged];
		
		// If the date field has focus, display a date picker instead of keyboard.
		self.toDateTextView.inputView = datePicker;
        
        // Add "Done" button
        self.toDateTextView.inputAccessoryView = [self getDoneToolbar];
		
		// Set the text to the date currently displayed by the picker.
		self.toDateTextView.text = [self formatDate:datePicker.date];
	}
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

// Called when the "from date" date picker changes.
- (void)updateFromDateField:(id)sender
{
    UIDatePicker *picker = (UIDatePicker*) self.fromDateTextView.inputView;
    self.fromDateTextView.text = [self formatDate:picker.date];
	
	// Set "from date"
	self.currentFromDate = picker.date;
	
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	NSCalendar *currentCalendar = [NSCalendar currentCalendar];
	NSDateComponents *dateComponents = [currentCalendar components:(NSYearCalendarUnit| NSMonthCalendarUnit| NSDayCalendarUnit) fromDate:self.currentFromDate];
	
	// Set label values
	self.fromDateDayLabel.text = [NSString stringWithFormat:@"%ld", (long)dateComponents.day];
	NSString *monthName = [[dateFormatter monthSymbols] objectAtIndex:(dateComponents.month-1)];// months are 0-based
	self.fromDateMonthLabel.text = monthName;
	
	// Trigger new search
	[self getAllExpenses];
}

// Called when the "to date" date picker changes.
- (void)updateToDateField:(id)sender
{
    UIDatePicker *picker = (UIDatePicker*) self.toDateTextView.inputView;
    self.toDateTextView.text = [self formatDate:picker.date];
	
	// Set "to date"
	self.currentToDate = picker.date;
	
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	NSCalendar *currentCalendar = [NSCalendar currentCalendar];
	NSDateComponents *dateComponents = [currentCalendar components:(NSYearCalendarUnit| NSMonthCalendarUnit| NSDayCalendarUnit) fromDate:self.currentToDate];
	
	// Set label values
	self.toDateDayLabel.text = [NSString stringWithFormat:@"%ld", (long)dateComponents.day];
	NSString *monthName = [[dateFormatter monthSymbols] objectAtIndex:(dateComponents.month-1)];// months are 0-based
	self.toDateMonthLabel.text = monthName;
	
	// Trigger new search
	[self getAllExpenses];
}

// Close keyboard/pickers on tap in screen
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *touch = [[event allTouches] anyObject];
	
	// Ignore if tapping in the "from date" or "to date" views
	if ( touch.view != self.fromDateView && touch.view != self.toDateView ) {
		[self closeAllKeyboardsAndPickers];
	}
}

-(void)viewWillAppear:(BOOL)animated
{
    // Fetch settings
    [self fetchSearchSettings];
    
	// Initialize expense types
	[self getAllExpenses];
	
	[super viewWillAppear:animated];
}

-(void)viewWillDisappear:(BOOL)animated
{
	[self closeAllKeyboardsAndPickers];
	
	[super viewWillDisappear:animated];
}

// Actions for export options
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // 0: Email
    if ( buttonIndex == 0 ) {
        [self exportCSVToEmail];
    }
}

// Show export options
- (void)showExportExpenseOptions:(id)sender
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Export CSV to...", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil
													otherButtonTitles:
								  NSLocalizedString(@"Email", nil),
								  /*@"Dropbox",
								  @"Google Drive",
								  @"SugarSync",*/
								  nil
								  ];
    
    [actionSheet showInView:self.view];
}

// Set from and to dates to the current month (first and last day)
- (void) setDefaultSearchDates
{
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	NSDate *currentDate = [NSDate date];
	NSCalendar *currentCalendar = [NSCalendar currentCalendar];
	NSDateComponents *dateComponents = [currentCalendar components:(NSYearCalendarUnit| NSMonthCalendarUnit| NSDayCalendarUnit) fromDate:currentDate];
	
	// Set format for text views
	[dateFormatter setDateFormat:NSLocalizedString(@"MMM, d yyyy", nil)];
	
	//
	// Set "from date"
	//
	[dateComponents setDay:1];
	self.currentFromDate = [currentCalendar dateFromComponents:dateComponents];

	// Set "from date" day label
	self.fromDateDayLabel.text = [NSString stringWithFormat:@"%ld", (long)dateComponents.day];
	// Set "from date" month label
	NSString *monthName = [[dateFormatter monthSymbols] objectAtIndex:(dateComponents.month-1)];// months are 0-based
	self.fromDateMonthLabel.text = monthName;
	
	// Set "from date" text view
	self.fromDateTextView.text = [dateFormatter stringFromDate:self.currentFromDate];
	
	//
	// Set "to date"
	//
	NSRange daysRange = [currentCalendar rangeOfUnit:NSDayCalendarUnit inUnit:NSMonthCalendarUnit forDate:currentDate];
	[dateComponents setDay:daysRange.length];// Last day of the current month
	self.currentToDate = [currentCalendar dateFromComponents:dateComponents];
	
	// Set "to date" day label
	self.toDateDayLabel.text = [NSString stringWithFormat:@"%ld", (long)dateComponents.day];
	// Set "to date" month label
	monthName = [[dateFormatter monthSymbols] objectAtIndex:(dateComponents.month-1)];// months are 0-based
	self.toDateMonthLabel.text = monthName;
	
	// Set "to date" text view
	self.toDateTextView.text = [dateFormatter stringFromDate:self.currentToDate];
}

// Get all expenses from a range (set in self.currentFromDate and self.currentToDate)
- (void)getAllExpenses
{
	AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
	
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
	
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Expense" inManagedObjectContext:context];
	
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
	[request setEntity:entityDesc];
	
	// Sort expenses by date
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
	[request setSortDescriptors:sortDescriptors];
	
	// Check if the dates are valid
	if ( ! self.currentFromDate || ! self.currentToDate ) {
		// If not, set the dates as the current month (first to last day)
		NSLog( @"DATES WERE NOT VALID!!!" );
		[self setDefaultSearchDates];
	}
    
    //
    // Update dates' times
    //
    
    // Make start date's time = 00:00:00
    NSCalendar *currentCalendar = [NSCalendar currentCalendar];
    NSDateComponents *fromDateComponents = [currentCalendar components:(NSYearCalendarUnit| NSMonthCalendarUnit| NSDayCalendarUnit| NSHourCalendarUnit| NSMinuteCalendarUnit| NSSecondCalendarUnit) fromDate:self.currentFromDate];
    
    [fromDateComponents setHour:0];
    [fromDateComponents setMinute:0];
    [fromDateComponents setSecond:0];
    self.currentFromDate = [currentCalendar dateFromComponents:fromDateComponents];
    
    // Make end date's time = 23:59:59
    NSDateComponents *toDateComponents = [currentCalendar components:(NSYearCalendarUnit| NSMonthCalendarUnit| NSDayCalendarUnit| NSHourCalendarUnit| NSMinuteCalendarUnit| NSSecondCalendarUnit) fromDate:self.currentToDate];
    
    [toDateComponents setHour:23];
    [toDateComponents setMinute:59];
    [toDateComponents setSecond:59];
    self.currentToDate = [currentCalendar dateFromComponents:toDateComponents];

    //
    // Update search settings and search
    //
    
    [self updateSearchSettings];
    
    NSMutableArray *usedPredicates = [[NSMutableArray alloc] init];
	
	// Add dates to search
    NSPredicate *datesPredicate = [NSPredicate predicateWithFormat:@"(date >= %@) and (date <= %@)", self.currentFromDate, self.currentToDate];
    [usedPredicates addObject:datesPredicate];
    //NSLog(@"Search dates: %@ to %@", self.currentFromDate, self.currentToDate);
    
    // Add any self.currentFilterTypes to search
    NSPredicate *filterTypesPredicate = [[NSPredicate alloc] init];
    if ( self.currentFilterTypes.count > 0 ) {
        // Parse the array, removing "uncategorized"
        NSMutableArray *parsedFilterTypes = [self parsedFilterTypes:self.currentFilterTypes];
        
        BOOL hasUncategorized = [self.currentFilterTypes containsObject:NSLocalizedString(@"uncategorized", nil)];
        
        // If there are still any items, it means we're filtering for more than uncategorized
        if ( parsedFilterTypes.count > 0 ) {
            if ( hasUncategorized ) {
                filterTypesPredicate = [NSPredicate predicateWithFormat:@"(type IN %@) or (type = nil)", parsedFilterTypes];
            } else {
                filterTypesPredicate = [NSPredicate predicateWithFormat:@"(type IN %@)", parsedFilterTypes];
            }
        } else {
            // If not, it just means we were only filtering uncategorized
            filterTypesPredicate = [NSPredicate predicateWithFormat:@"(type = nil)"];
        }
        
        [usedPredicates addObject:filterTypesPredicate];
    }
    
    // Add any self.currentFilterName to search
    NSPredicate *filterNamePredicate = [[NSPredicate alloc] init];
    if ( self.currentFilterName.length > 0 ) {
        filterNamePredicate = [NSPredicate predicateWithFormat:@"(name CONTAINS[cd] %@)", self.currentFilterName];
        
        [usedPredicates addObject:filterNamePredicate];
    }
    
    // Add the predicate to the request
    NSPredicate *finalPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:usedPredicates];
    [request setPredicate:finalPredicate];
	
	@try {
		NSError *error;
		NSArray *objects = [context executeFetchRequest:request error:&error];
		
		/*if ( objects.count == 0 ) {
			UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"No Expenses!", nil) message:NSLocalizedString(@"We couldn't find any expenses for the period set.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
			 
			 [alertView show];
		} else {
			NSLog( @"%lu expenses found", (unsigned long)[objects count] );
		}*/
		
		self.expenses = [NSMutableArray arrayWithArray:objects];
		
		// Calculate and show total
		[self calculateAndShowTotal];
		
		// Reload view with new data
		[self.expensesTableView reloadData];
	}
	@catch (NSException *exception) {
		NSLog( @"%@", exception );
		
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Expenses Error!", nil) message:NSLocalizedString(@"There was an error fetching your expenses. Maybe you don't have any yet?", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        
        [alertView show];
		
		self.expenses = [NSMutableArray arrayWithArray:@[]];
		
		// Reload view with new data
		[self.expensesTableView reloadData];
	}
}

// Calculate and show total for all found expenses
- (void) calculateAndShowTotal
{
	double expensesTotal = 0;
	
	for ( NSManagedObject *expense in self.expenses ) {
		expensesTotal += [[expense valueForKey:@"value"] floatValue];
	}
    
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    numberFormatter.locale = [NSLocale currentLocale];
    [numberFormatter setNumberStyle: NSNumberFormatterDecimalStyle];

	self.totalExpensesValueLabel.text = [NSString stringWithFormat:@"%@",[numberFormatter stringFromNumber:[NSNumber numberWithFloat: expensesTotal]]];
}

// Formats the date for the CSV file
- (NSString *)formatDateForCSV:(NSDate *)date
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	NSLocale* locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
	[dateFormatter setLocale:locale];
	[dateFormatter setDateStyle:NSDateFormatterShortStyle];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    NSString *formattedDate = [dateFormatter stringFromDate:date];
    return formattedDate;
}

// Generate a CSV file for all found expenses
- (NSString *) getCSVFileString
{
	NSString *fileContents = @"";
	
	// Add Header
	fileContents = [fileContents stringByAppendingString:@"Name,Type,Date,Value"];
	
	for ( NSManagedObject *expense in self.expenses ) {
		// Parse the values for text from the received object
		NSString *expenseValue = [NSString stringWithFormat:@"%0.2f",[[expense valueForKey:@"value"] floatValue]];
		NSString *expenseName = [expense valueForKey:@"name"];
		NSString *expenseType = [expense valueForKey:@"type"];
		NSString *expenseDate = [self formatDateForCSV:[expense valueForKey:@"date"]];
		
		// Show "uncategorized" if nothing is set
		if ( expenseType.length <= 0 ) {
			expenseType = @"uncategorized";
		}
		
		// parse commas, new lines, and quotes for CSV
		expenseName = [expenseName stringByReplacingOccurrencesOfString:@"," withString:@";"];
		expenseName = [expenseName stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
		expenseName = [expenseName stringByReplacingOccurrencesOfString:@"\"" withString:@"'"];
		
		expenseType = [expenseType stringByReplacingOccurrencesOfString:@"," withString:@";"];
		expenseType = [expenseType stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
		expenseType = [expenseType stringByReplacingOccurrencesOfString:@"\"" withString:@"'"];
		
		expenseDate = [expenseDate stringByReplacingOccurrencesOfString:@"," withString:@";"];
		expenseDate = [expenseDate stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
		expenseDate = [expenseDate stringByReplacingOccurrencesOfString:@"\"" withString:@"'"];
		
		expenseValue = [expenseValue stringByReplacingOccurrencesOfString:@"," withString:@";"];
		expenseValue = [expenseValue stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
		expenseValue = [expenseValue stringByReplacingOccurrencesOfString:@"\"" withString:@"'"];
		
		NSString *rowForExpense = [NSString stringWithFormat:@"\n%@,%@,%@,%@", expenseName, expenseType, expenseDate, expenseValue];

		// Append string to file contents
		fileContents = [fileContents stringByAppendingString:rowForExpense];
	}
	
	NSLog(@"Final file contents:\n\n%@", fileContents);
	
	return fileContents;
}

// Export CSV to email and send it
- (IBAction) exportCSVToEmail
{
	NSString *textFileContentsString = [self getCSVFileString];
	NSData *textFileContentsData = [textFileContentsString dataUsingEncoding:NSASCIIStringEncoding];
	
	// Add dates to subject, body, and file name
	NSString *currentFromDate = [self formatDateForCSV:self.currentFromDate];
	NSString *currentToDate = [self formatDateForCSV:self.currentToDate];
	
	NSString *emailSubject = [ NSString stringWithFormat:NSLocalizedString(@"Oikon CSV Export: %@ to %@", nil), currentFromDate, currentToDate ];
	NSString *emailBody = [ NSString stringWithFormat:NSLocalizedString(@"Enjoy this CSV file with my expense data. It's from %@ to %@", nil), currentFromDate, currentToDate ];
	NSString *csvFileName = [ NSString stringWithFormat:@"oikon-export-%@-%@.csv", currentFromDate, currentToDate ];
	
	if ( [MFMailComposeViewController canSendMail] ) {
		MFMailComposeViewController *mailComposeViewController = [[MFMailComposeViewController alloc] init];
		mailComposeViewController.mailComposeDelegate = self;
		[mailComposeViewController setSubject:emailSubject];
		[mailComposeViewController setMessageBody:emailBody isHTML:NO];
		[mailComposeViewController addAttachmentData:textFileContentsData mimeType:@"text/csv" fileName:csvFileName];
		[mailComposeViewController setModalTransitionStyle:UIModalTransitionStyleCrossDissolve];
		
		// Make the navigationbar color white, background blue
		UIColor *blueColor = [UIColor colorWithRed:62/255.0 green:138/255.0 blue:229/255.0 alpha:1];
		UIColor *whiteColor = [UIColor whiteColor];
		[mailComposeViewController.navigationBar setTintColor:whiteColor];
		[mailComposeViewController.navigationBar setBarTintColor:blueColor];
		[mailComposeViewController.navigationBar setTranslucent:YES];
		
		[self.navigationController presentViewController:mailComposeViewController animated:YES completion:^{
			[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
		}];
	} else {
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Oops!", nil) message:NSLocalizedString(@"It seems you don't have email configured on your iOS device. Please take care of that first.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        
        [alertView show];
	}
}

#pragma mark MFMailComposeViewControllerDelegate
-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
	NSLog(@"Finished sending email!");
	[self dismissViewControllerAnimated:YES completion:nil];
}

// Fetch search settings
- (void) fetchSearchSettings
{
    self.settings = [NSUserDefaults standardUserDefaults];
	[self.settings synchronize];
    
    //
    // Dates
    //
	
	NSDate *currentSearchFromDate = [self.settings valueForKey:@"searchFromDate"];
    NSDate *currentSearchToDate = [self.settings valueForKey:@"searchToDate"];
    
    if ( currentSearchFromDate ) {
        self.currentFromDate = currentSearchFromDate;
    }
    
    if ( currentSearchToDate ) {
        self.currentToDate = currentSearchToDate;
    }
    
    //
    // Filter Types
    //
    
    NSArray *filterTypes = [self.settings valueForKey:@"filterTypes"];
    
    if ( filterTypes.count > 0 ) {
        self.currentFilterTypes = [[NSMutableArray alloc] initWithArray:filterTypes copyItems:YES];
    } else {
        self.currentFilterTypes = [[NSMutableArray alloc] init];
    }
    
    //
    // Filter Name
    //
    
    NSString *filterName = [self.settings valueForKey:@"filterName"];
    
    if ( filterName ) {
        self.currentFilterName = filterName;
    } else {
        self.currentFilterName = @"";
    }
    
    //
    // UI Updates
    //
    
    if ( currentSearchFromDate || currentSearchToDate || filterTypes || filterName.length > 0 ) {
        [self updateSearchLabelsAndViews];
    }
}

// Update search settings
- (void) updateSearchSettings
{
    self.settings = [NSUserDefaults standardUserDefaults];
	[self.settings synchronize];

    [self.settings setValue:self.currentFromDate forKey:@"searchFromDate"];
    [self.settings setValue:self.currentToDate forKey:@"searchToDate"];
    [self.settings setValue:self.currentFilterName forKey:@"filterName"];
}

// Close keyboards/pickers
- (void)closeAllKeyboardsAndPickers
{
    [self.fromDateTextView resignFirstResponder];
    [self.toDateTextView resignFirstResponder];
    
    [[self view] endEditing:YES];
}

// Update search labels & views
- (void) updateSearchLabelsAndViews
{
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	NSCalendar *currentCalendar = [NSCalendar currentCalendar];
	NSDateComponents *dateComponentsFrom = [currentCalendar components:(NSYearCalendarUnit| NSMonthCalendarUnit| NSDayCalendarUnit) fromDate:self.currentFromDate];
    NSDateComponents *dateComponentsTo = [currentCalendar components:(NSYearCalendarUnit| NSMonthCalendarUnit| NSDayCalendarUnit) fromDate:self.currentToDate];
	
	// Set format for text views
	[dateFormatter setDateFormat:NSLocalizedString(@"MMM, d yyyy", nil)];
    
	// Set "from date" day label
	self.fromDateDayLabel.text = [NSString stringWithFormat:@"%ld", (long)dateComponentsFrom.day];
	// Set "from date" month label
	NSString *monthName = [[dateFormatter monthSymbols] objectAtIndex:(dateComponentsFrom.month-1)];// months are 0-based
	self.fromDateMonthLabel.text = monthName;
	
	// Set "from date" text view
	self.fromDateTextView.text = [dateFormatter stringFromDate:self.currentFromDate];
	
	// Set "to date" day label
	self.toDateDayLabel.text = [NSString stringWithFormat:@"%ld", (long)dateComponentsTo.day];
	// Set "to date" month label
	monthName = [[dateFormatter monthSymbols] objectAtIndex:(dateComponentsTo.month-1)];// months are 0-based
	self.toDateMonthLabel.text = monthName;
	
	// Set "to date" text view
	self.toDateTextView.text = [dateFormatter stringFromDate:self.currentToDate];
    
    // Show type label with a different color if there's any self.currentFilterTypes
    if ( self.currentFilterTypes.count > 0 ) {
        NSDictionary *underlineAttribute = @{NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)};
        self.tableHeaderType.attributedText = [[NSAttributedString alloc] initWithString:self.tableHeaderType.text attributes:underlineAttribute];
    } else {
        NSDictionary *normalAttribute = @{NSUnderlineStyleAttributeName: @(NSUnderlineStyleNone)};
        self.tableHeaderType.attributedText = [[NSAttributedString alloc] initWithString:self.tableHeaderType.text attributes:normalAttribute];
    }
    
    // Show name label with a different color if there's any self.currentFilterName
    if ( self.currentFilterName.length > 0 ) {
        NSDictionary *underlineAttribute = @{NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)};
        self.tableHeaderName.attributedText = [[NSAttributedString alloc] initWithString:self.tableHeaderName.text attributes:underlineAttribute];
    } else {
        NSDictionary *normalAttribute = @{NSUnderlineStyleAttributeName: @(NSUnderlineStyleNone)};
        self.tableHeaderName.attributedText = [[NSAttributedString alloc] initWithString:self.tableHeaderName.text attributes:normalAttribute];
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

-(void) showExpenseTypeFilter
{
    [self performSegueWithIdentifier:@"showExpenseTypeFilter" sender:self];
}

// Save expense
- (IBAction)showExpenseNameFilter:(id)sender
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Filter By Expense Name", nil) message:NSLocalizedString(@"Please type what should the expense names contain.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"Update", nil), nil];
	alert.alertViewStyle = UIAlertViewStylePlainTextInput;
	
	// Set capitalization for text field
	UITextField *textField = [alert textFieldAtIndex:0];
	textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
	textField.autocorrectionType = UITextAutocorrectionTypeYes;
    textField.text = self.currentFilterName;
	[alert show];
}

// Try to save or update expense type
- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	NSString *buttonTitle = [alertView buttonTitleAtIndex:buttonIndex];
	
	// Updade expense name filter
	if ( [buttonTitle isEqualToString:NSLocalizedString(@"Update", nil)] ) {
        self.currentFilterName = [[alertView textFieldAtIndex:0] text];
		[self updateSearchSettings];
        [self fetchSearchSettings];
        [self getAllExpenses];
        
        [self closeAllKeyboardsAndPickers];
	}
}

// Change @"uncategorized" with @""
- (NSMutableArray *) parsedFilterTypes:filterTypes
{
    NSMutableArray *parsedFilterTypes = [[NSMutableArray alloc] initWithArray:filterTypes copyItems:YES];
    
    NSUInteger uncategorizedIndex = [parsedFilterTypes indexOfObject:NSLocalizedString(@"uncategorized", nil)];
    BOOL hasUncategorized = [parsedFilterTypes containsObject:NSLocalizedString(@"uncategorized", nil)];
	
    // Check if the uncategorized exists in the array
    if ( hasUncategorized ) {
        // Remove item in the array
        [parsedFilterTypes removeObjectAtIndex:uncategorizedIndex];
    }
    
    return parsedFilterTypes;
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
        [self getAllExpenses];
    }
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
	if ( [segue.identifier isEqualToString:@"showExpense"] ) {
		ExpenseViewController *expenseViewController = segue.destinationViewController;
		expenseViewController.currentExpense = self.selectedExpense;
	}
}

@end
