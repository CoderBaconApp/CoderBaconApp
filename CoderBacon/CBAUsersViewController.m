//
//  CBAUsersViewController.m
//  CoderBacon
//
//  Created by Justin Steffen on 4/24/14.
//  Copyright (c) 2014 Justin Steffen. All rights reserved.
//

#import "CBAUsersViewController.h"
#import "CBAClient.h"

@interface CBAUsersViewController ()

@property (nonatomic) NSArray *users;

@end
@implementation CBAUsersViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[self tableView] registerClass:[UITableViewCell class] forCellReuseIdentifier:@"UITableViewCell"];
    
    CBAClient *client = [[CBAClient alloc] init];
    
    [client getUsersOnSuccess:^(NSDictionary *data) {
        NSLog(@"Success: %@", data);
        self.users = data[@"users"];
        [self.tableView reloadData];
        
    } onError:^(NSError *err) {
        NSLog(@"Error: %@", err);
    }];
}

#pragma mark UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[self users] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell" forIndexPath:indexPath];
    NSDictionary *user = self.users[indexPath.row];
    NSString *userName = user[@"username"];
    
    if (userName != (id)[NSNull null] && [userName length] > 0) {
        cell.textLabel.text = userName;
    }
    else {
        cell.textLabel.text = user[@"email"];
    }
    
    return cell;
}


@end
