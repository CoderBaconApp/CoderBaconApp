//
//  CBAUsersViewController.m
//  CoderBacon
//
//  Created by Justin Steffen on 4/24/14.
//  Copyright (c) 2014 Justin Steffen. All rights reserved.
//

#import "CBAUsersViewController.h"
#import "CBAClient.h"
#import "CBAEventStore.h"

static const NSInteger CBAMaxInvitations = 2;

@interface CBAUsersViewController () <UITableViewDataSource, UITableViewDelegate, UISearchDisplayDelegate>

@property (nonatomic) NSArray *users;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UISearchDisplayController *searchController;
@property (nonatomic, strong) NSMutableArray *filteredUsers;
@property (nonatomic, strong) NSMutableArray *selectedUsers;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIView *footerView;
@property (strong, nonatomic) IBOutlet UILabel *footerLabel;
@property (readonly) NSInteger remainingInvitations;
@property (strong, nonatomic) NSMutableDictionary *currentEvent;
@end

@implementation CBAUsersViewController

- (instancetype)init{
    self = [super init];
    
    if (self) {
        self.title = @"Invite Friends";
        
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Next"
                                                                                  style:UIBarButtonItemStylePlain
                                                                                 target:self
                                                                                 action:@selector(nextButtonTapped:)];
        
        _filteredUsers = [[NSMutableArray alloc] init];
        _selectedUsers = [[NSMutableArray alloc] init];
        
        _currentEvent = [[CBAEventStore sharedStore] currentEvent];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updateTableViewForDynamicTypeSize)
                                                     name:UIContentSizeCategoryDidChangeNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

#pragma mark Properties

- (NSInteger)remainingInvitations {
    return CBAMaxInvitations - [self.selectedUsers count];
}

#pragma mark View Lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupTableView];
    [self setupSearchBar];
    
    CBAClient *client = [[CBAClient alloc] init];
    
    [client getUsersOnSuccess:^(NSDictionary *data) {
        NSLog(@"Success: %@", data);
        self.users = data[@"users"];
        [self.tableView reloadData];
        
    } onError:^(NSError *err) {
        NSLog(@"Error: %@", err);
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self updateTableViewForDynamicTypeSize];
    [self updateFooter];
}


#pragma mark Action
- (IBAction)nextButtonTapped:(id)sender {
    NSLog(@"nextButtonTapped");
    
    if (self.remainingInvitations == 0) {
        NSMutableArray *selectedUsers = [[NSMutableArray alloc] initWithCapacity:[self.selectedUsers count]];
        
        for (NSDictionary *user in self.selectedUsers) {
            [selectedUsers addObject:user[@"id"]];
        }
        self.currentEvent[@"users"] = selectedUsers;
    }
    
    NSLog(@"currentEvent: %@", self.currentEvent);
}

#pragma mark UITableView Helper Methods
- (void) setupTableView {
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [[self tableView] registerClass:[UITableViewCell class] forCellReuseIdentifier:@"UITableViewCell"];
}

- (NSDictionary *)tableView:(UITableView *)tableView userForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *user;
    
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        user = self.filteredUsers[indexPath.row];
    } else {
        user = self.users[indexPath.row];
    }
    
    return user;
}

-(void)updateTableViewForDynamicTypeSize {
    static NSDictionary *cellHeightDictionary;
    
    if (!cellHeightDictionary) {
        cellHeightDictionary = @{ UIContentSizeCategoryExtraSmall : @44,
                                  UIContentSizeCategorySmall : @44,
                                  UIContentSizeCategoryMedium : @44,
                                  UIContentSizeCategoryLarge : @44,
                                  UIContentSizeCategoryExtraLarge : @55,
                                  UIContentSizeCategoryExtraExtraLarge : @65,
                                  UIContentSizeCategoryExtraExtraExtraLarge : @75 };
    }
    
    NSString *userSize = [[UIApplication sharedApplication] preferredContentSizeCategory];
    
    NSNumber *cellHeight = cellHeightDictionary[userSize];
    [self.tableView setRowHeight:cellHeight.floatValue];
    [self.tableView reloadData];
}

#pragma mark UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return [self.filteredUsers count];
    } else {
        return [self.users count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell" forIndexPath:indexPath];
    NSDictionary *user = [self tableView:tableView userForRowAtIndexPath:indexPath];
    
    UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    cell.textLabel.font = font;
    
    NSString *userName = user[@"username"];
    NSString *email = user[@"email"];
    
    if (userName != (id)[NSNull null] && [userName length] > 0) {
        cell.textLabel.text = userName;
    }
    else {
        cell.textLabel.text = email;
    }

    if ([self.selectedUsers containsObject:user]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

#pragma mark UITableViewDelegate Methods
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *user = [self tableView:tableView userForRowAtIndexPath:indexPath];
    
    //NSLog(@"selected user: %@", user);
    
    [tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:NO];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (cell.accessoryType == UITableViewCellAccessoryNone && self.remainingInvitations > 0) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        // Reflect selection in data model
        [self.selectedUsers addObject:user];
    } else if (cell.accessoryType == UITableViewCellAccessoryCheckmark) {
        cell.accessoryType = UITableViewCellAccessoryNone;
        // Reflect deselection in data model
        [self.selectedUsers removeObject:user];
    }
    
    [self updateFooter];
    NSLog(@"Selected Users: %@", self.selectedUsers);
}

#pragma mark Search Bar Helper Methods
-(void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope {
    // Update the filtered array based on the search text and scope.
    // Remove all objects from the filtered search array
    [self.filteredUsers removeAllObjects];
    // Filter the array using NSPredicate
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"email contains[cd] %@ OR name contains[cd] %@", searchText, searchText];

    self.filteredUsers = [NSMutableArray arrayWithArray:[self.users filteredArrayUsingPredicate:predicate]];
}

- (void)setupSearchBar {
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    self.tableView.tableHeaderView = self.searchBar;
    
    self.searchController = [[UISearchDisplayController alloc] initWithSearchBar:self.searchBar contentsController:self];
    self.searchController.searchResultsDataSource = self;
    self.searchController.searchResultsDelegate = self;
    self.searchController.delegate = self;
    [self.searchDisplayController.searchResultsTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"UITableViewCell"];
}

#pragma mark UISearchDisplayController Delegate Methods
-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    // Tells the table data source to reload when text changes
    [self filterContentForSearchText:searchString scope:
     [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}

- (void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller {
    [self.tableView reloadData];
}

#pragma mark Footer Helper Methods
- (void)updateFooter {
    if (self.remainingInvitations > 0) {
        self.footerLabel.text = [NSString stringWithFormat:@"%d invites left", self.remainingInvitations];
    }
    else {
        self.footerLabel.text = @"Ready for next step!";
        
    }
}


@end
