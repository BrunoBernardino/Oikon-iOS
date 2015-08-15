//
//  ListFilterTypeViewController.m
//  Oikon
//
//  Created by Bruno Bernardino on 01/09/14.
//  Copyright (c) 2014 emotionLoop. All rights reserved.
//

#import "ListFilterTypeViewController.h"
#import "MainViewController.h"
#import "ListViewController.h"
#import "FilterViewCell.h"
#import "AppDelegate.h"

@interface ListFilterTypeViewController ()

@end

@implementation ListFilterTypeViewController

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
	[self setTitle:NSLocalizedString(@"Filter Types", nil)];
	
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
    
    // Have the table view fetch data from this ViewController
    self.TypeListTableView.delegate = self;
    self.TypeListTableView.dataSource = self;
    
    // Bind tap on show all button
    [self.showAllButton addTarget:self action:@selector(showAllExpenseTypes:) forControlEvents:UIControlEventTouchUpInside];
    
    // Fetch previous search dates
    [self fetchSearchSettings];
    
    // Fetch expense types
	[self.mainViewControllerReference getAllExpenseTypes];
    
    [self.TypeListTableView reloadData];
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
    return self.mainViewControllerReference.expenseTypes.count;
}


// Format & Display Cell Rows
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *CellIdentifier = @"filterTypeTableCell";
    
    FilterViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
	long row = indexPath.row;
    
    NSString *expenseTypeName = [ self.mainViewControllerReference.expenseTypes[row] valueForKey:@"name" ];
	
	cell.expenseTypeNameLabel.text = expenseTypeName;
	cell.expenseTypeSwitch.on = [self isExpenseTypeFiltered:expenseTypeName];
    
    // Add action for toggling switch
    [cell.expenseTypeSwitch addTarget:self action:@selector(toggleCellSwitch:) forControlEvents:UIControlEventValueChanged];
    
    return cell;
}

// Handle the toggle on a cell switch
- (IBAction)toggleCellSwitch:(id)sender
{
	UISwitch *switchView = (UISwitch *)sender;
    
	BOOL newSwitchValue = switchView.isOn;
    
    FilterViewCell *cell = (FilterViewCell *)[[switchView superview] superview];// Yep, apparently we need to go up 2 views to get to the cell
    NSString *expenseType = cell.expenseTypeNameLabel.text;
    
    NSUInteger currentExpenseTypeIndex = [self.currentFilterTypes indexOfObject:expenseType];
    BOOL hasExpenseType = [self.currentFilterTypes containsObject:expenseType];
	
    // We're adding an expense type to the filters
    if ( newSwitchValue == YES ) {
        // Check if the object doesn't exist
        if ( ! hasExpenseType ) {
            // Add item to the array
            [self.currentFilterTypes addObject:expenseType];
        }
    } else {
        // Check if the object exists
        if ( hasExpenseType ) {
            // Remove item from the array
            [self.currentFilterTypes removeObjectAtIndex:currentExpenseTypeIndex];
        }
    }
	
    [self updateSearchSettings];
}

// Show all button toggle (empty array)
- (IBAction)showAllExpenseTypes:(id)sender
{
    // Empty the array
    [self.currentFilterTypes removeAllObjects];
    
    // Update the settings
    [self updateSearchSettings];
    
    // Reload table so all switches are on
    [self.TypeListTableView reloadData];
}


/*- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // toggle switchView inside
    static NSString *CellIdentifier = @"filterTypeTableCell";
    
    FilterViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    NSLog(@"Toggling switch from row");
    
    cell.expenseTypeSwitch.on = ! cell.expenseTypeSwitch.isOn;
    
    [self toggleCellSwitch:cell.expenseTypeSwitch];
}*/

// Update search settings
- (void) updateSearchSettings
{
    self.settings = [NSUserDefaults standardUserDefaults];
	[self.settings synchronize];
    
    [self.settings setValue:self.currentFilterTypes forKey:@"filterTypes"];
}

// Fetch search settings
- (void) fetchSearchSettings
{
    self.settings = [NSUserDefaults standardUserDefaults];
	[self.settings synchronize];
    
    NSArray *filterTypes = [self.settings valueForKey:@"filterTypes"];
    
    if ( filterTypes.count > 0 ) {
        self.currentFilterTypes = [[NSMutableArray alloc] initWithArray:filterTypes copyItems:YES];
    } else {
        self.currentFilterTypes = [[NSMutableArray alloc] init];
    }
}

// Is an expense type filtered
- (BOOL)isExpenseTypeFiltered:(NSString *)expenseType
{
    // If the array is empty, no expenses are filtered
    if ( self.currentFilterTypes.count == 0 ) {
        return NO;
    }

    NSUInteger currentExpenseTypeIndex = [self.currentFilterTypes indexOfObject:expenseType];
	
    // Check if the expense type is filtered
    if ( currentExpenseTypeIndex != NSNotFound ) {
        return YES;
    } else {
        return NO;
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
