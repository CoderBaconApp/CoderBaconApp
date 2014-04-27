//
//  CBADatePicker.m
//  CoderBacon
//
//  Created by Justin Steffen on 4/27/14.
//  Copyright (c) 2014 Justin Steffen. All rights reserved.
//

#import "CBADatePickerViewController.h"
#import "CBAUsersViewController.h"
#import "CBAEventStore.h"

@interface CBADatePickerViewController ()
@property (strong, nonatomic) IBOutlet UIDatePicker *datePicker;
@property (strong, nonatomic) NSMutableDictionary *currentEvent;
@end

@implementation CBADatePickerViewController

- (instancetype)init{
    self = [super init];
    
    if (self) {
        self.title = @"Select date";
        
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Next"
                                                                                  style:UIBarButtonItemStylePlain
                                                                                 target:self
                                                                                 action:@selector(nextButtonTapped:)];
        _currentEvent = [[CBAEventStore sharedStore] currentEvent];

    }
    return self;
}

#pragma mark View Lifecycle

- (void) viewDidLoad {
    [super viewDidLoad];
    
    self.datePicker.minimumDate = [NSDate date];
}

#pragma mark Actions

- (IBAction)nextButtonTapped:(id)sender {
    NSLog(@"nextButtonTapped");
    self.currentEvent[@"meetup_date"] = [self.datePicker date];
    NSLog(@"currentEvent: %@", self.currentEvent);
    
    CBAUsersViewController *usersViewController = [[CBAUsersViewController alloc] init];
    [self.navigationController pushViewController:usersViewController animated:YES];
}

@end
