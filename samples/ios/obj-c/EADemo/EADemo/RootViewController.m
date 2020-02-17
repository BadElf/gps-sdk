/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    View controller for watching the device come and go
 */

#import "RootViewController.h"
#import "EADSessionTransferViewController.h"
#import "EADSessionController.h"

#import <ExternalAccessory/ExternalAccessory.h>

@interface RootViewController ()

@property (nonatomic, strong) NSMutableArray *accessoryList;
@property (nonatomic, strong) EAAccessory *selectedAccessory;
@property (nonatomic, strong) EADSessionController *eaSessionController;
@property (nonatomic, strong) IBOutlet UIAlertController *protocolSelectionAlertController;
@property (nonatomic, strong) IBOutlet UIView *noExternalAccessoriesPosterView;
@property (nonatomic, strong) IBOutlet UILabel *noExternalAccessoriesLabelView;
@property (nonatomic, strong) NSArray *supportedProtocolsStrings;

@end

@implementation RootViewController

- (void)viewDidLoad {
    // Create the view that gets shown when no accessories are connected
    _noExternalAccessoriesPosterView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [_noExternalAccessoriesPosterView setBackgroundColor:[UIColor whiteColor]];
    _noExternalAccessoriesLabelView = [[UILabel alloc] initWithFrame:CGRectMake(60, 170, 240, 50)];
    [_noExternalAccessoriesLabelView setText:@"No Accessories Connected"];
    [_noExternalAccessoriesPosterView addSubview:_noExternalAccessoriesLabelView];
    [[self view] addSubview:_noExternalAccessoriesPosterView];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_accessoryDidConnect:) name:EAAccessoryDidConnectNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_accessoryDidDisconnect:) name:EAAccessoryDidDisconnectNotification object:nil];
    [[EAAccessoryManager sharedAccessoryManager] registerForLocalNotifications];

    _eaSessionController = [EADSessionController sharedController];
    _accessoryList = [[NSMutableArray alloc] initWithArray:[[EAAccessoryManager sharedAccessoryManager] connectedAccessories]];

    if ([_accessoryList count] == 0) {
        [_noExternalAccessoriesPosterView setHidden:NO];
    } else {
        [_noExternalAccessoriesPosterView setHidden:YES];
    }
    // load the UISupportedExternalAccessory property to know which protocolStrings are registered in the app
    NSBundle *mainBundle = [NSBundle mainBundle];
    self.supportedProtocolsStrings = [mainBundle objectForInfoDictionaryKey:@"UISupportedExternalAccessoryProtocols"];

    [super viewDidLoad];
}

- (void)viewDidUnload {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:EAAccessoryDidConnectNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:EAAccessoryDidDisconnectNotification object:nil];

    _accessoryList = nil;

    _selectedAccessory = nil;

//    _protocolSelectionAlertController = nil;

    [super viewDidUnload];
}

#pragma mark UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_accessoryList count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *eaAccessoryCellIdentifier = @"eaAccessoryCellIdentifier";
    NSUInteger row = [indexPath row];

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:eaAccessoryCellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:eaAccessoryCellIdentifier];
    }

    NSString *eaAccessoryName = [[_accessoryList objectAtIndex:row] name];
    if (!eaAccessoryName || [eaAccessoryName isEqualToString:@""]) {
        eaAccessoryName = @"unknown";
    }

	[[cell textLabel] setText:eaAccessoryName];
	
    return cell;
}
 
#pragma mark UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger row = [indexPath row];

    _selectedAccessory = [_accessoryList objectAtIndex:row];

    _protocolSelectionAlertController = [UIAlertController alertControllerWithTitle:@"Select Protocol"
                                                                            message:nil
                                                                     preferredStyle:UIAlertControllerStyleActionSheet];

    NSArray *protocolStrings = [_selectedAccessory protocolStrings];

    for(NSString *protocolString in protocolStrings)
    {
        UIAlertAction *protocolAction = [UIAlertAction actionWithTitle:protocolString style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {

            if (_selectedAccessory)
            {
                BOOL  matchFound = FALSE;
                for ( NSString *item in self.supportedProtocolsStrings)
                {
                    if ([item compare: protocolString] == NSOrderedSame)
                    {
                        matchFound = TRUE;
                        NSLog(@"match found - protocolString %@", protocolString);
                    }
                }

                
                if (matchFound == FALSE)
                {
                    UIAlertController *invalidProtocolAlertController;

                    invalidProtocolAlertController = [UIAlertController alertControllerWithTitle:@"Alert"
                                                                                          message:@"protocolString unregistered"
                                                                                    preferredStyle:UIAlertControllerStyleActionSheet];
                    UIAlertAction *ok = [UIAlertAction
                                         actionWithTitle:@"OK"
                                         style: UIAlertActionStyleDefault
                                         handler:^(UIAlertAction *action)
                                         {
                                             [invalidProtocolAlertController dismissViewControllerAnimated:YES completion:nil];

                                         }];
                    
                    [invalidProtocolAlertController addAction:ok];
                    // Present alert controller
                    
                    [self presentViewController: invalidProtocolAlertController animated:YES completion:nil];
                    _selectedAccessory = nil;

                
                }
                else
                {
                    [_eaSessionController setupControllerForAccessory:_selectedAccessory
                                                   withProtocolString:[action title]];

                    EADSessionTransferViewController *sessionTransferViewController =
                    [self.storyboard instantiateViewControllerWithIdentifier:@"EADSessionTransfer"];
                    
                    [[self navigationController] pushViewController:sessionTransferViewController animated:YES];
                }
            }
            
            _selectedAccessory = nil;
            _protocolSelectionAlertController = nil;
        }];
        [_protocolSelectionAlertController addAction:protocolAction];
    }

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        _selectedAccessory = nil;
        _protocolSelectionAlertController = nil;
    }];
    [_protocolSelectionAlertController addAction:cancelAction];

    [self presentViewController:_protocolSelectionAlertController animated:YES completion:nil];

    [[self tableView] deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 100;
}

#pragma mark Internal

- (void)_accessoryDidConnect:(NSNotification *)notification {
    EAAccessory *connectedAccessory = [[notification userInfo] objectForKey:EAAccessoryKey];

    [_accessoryList addObject:connectedAccessory];

    if ([_accessoryList count] == 0) {
        [_noExternalAccessoriesPosterView setHidden:NO];
    } else {
        [_noExternalAccessoriesPosterView setHidden:YES];
    }

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:([_accessoryList count] - 1) inSection:0];
    [[self tableView] insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationLeft];
}

- (void)_accessoryDidDisconnect:(NSNotification *)notification {
    EAAccessory *disconnectedAccessory = [[notification userInfo] objectForKey:EAAccessoryKey];

    if (_selectedAccessory && [disconnectedAccessory connectionID] == [_selectedAccessory connectionID])
    {
        // clear the protocolSelectionAlertController if the accessory is disconnected
        [_protocolSelectionAlertController dismissViewControllerAnimated:YES completion:^(void) {
            _selectedAccessory = nil;
            _protocolSelectionAlertController = nil;
        }];
        

    }

    int disconnectedAccessoryIndex = 0;
    for(EAAccessory *accessory in _accessoryList) {
        if ([disconnectedAccessory connectionID] == [accessory connectionID]) {
            break;
        }
        disconnectedAccessoryIndex++;
    }

    if (disconnectedAccessoryIndex < [_accessoryList count]) {
        [_accessoryList removeObjectAtIndex:disconnectedAccessoryIndex];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:disconnectedAccessoryIndex inSection:0];
        [[self tableView] deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationRight];
	} else {
        NSLog(@"could not find disconnected accessory in accessory list");
    }

    if ([_accessoryList count] == 0) {
        [_noExternalAccessoriesPosterView setHidden:NO];
    } else {
        [_noExternalAccessoriesPosterView setHidden:YES];
    }
}

@end
