//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

#import "BlockListViewController.h"
#import "AddToBlockListViewController.h"
#import "BlockListUIUtils.h"
#import "ContactTableViewCell.h"
#import "ContactsViewHelper.h"
#import "OWSTableViewController.h"
#import "PhoneNumber.h"
#import "UIFont+OWS.h"
#import "UIView+OWS.h"
#import <SignalMessaging/Environment.h>
#import <SignalMessaging/OWSContactsManager.h>
#import <SignalServiceKit/OWSBlockingManager.h>
#import <SignalServiceKit/TSGroupThread.h>

NS_ASSUME_NONNULL_BEGIN

@interface BlockListViewController () <ContactsViewHelperDelegate>

@property (nonatomic, readonly) ContactsViewHelper *contactsViewHelper;

@property (nonatomic, readonly) OWSTableViewController *tableViewController;

@end

#pragma mark -

@implementation BlockListViewController

- (OWSBlockingManager *)blockingManager
{
    return OWSBlockingManager.sharedManager;
}

- (void)loadView
{
    [super loadView];

    _contactsViewHelper = [[ContactsViewHelper alloc] initWithDelegate:self];

    self.title
        = NSLocalizedString(@"SETTINGS_BLOCK_LIST_TITLE", @"Label for the block list section of the settings view");

    _tableViewController = [OWSTableViewController new];
    [self.view addSubview:self.tableViewController.view];
    [self addChildViewController:self.tableViewController];
    [_tableViewController.view autoPinEdgesToSuperviewEdges];
    self.tableViewController.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableViewController.tableView.estimatedRowHeight = 60;

    [self updateTableContents];
}

#pragma mark - Table view data source

- (void)updateTableContents
{
    OWSTableContents *contents = [OWSTableContents new];

    __weak BlockListViewController *weakSelf = self;
    ContactsViewHelper *helper = self.contactsViewHelper;

    // "Add" section

    OWSTableSection *addSection = [OWSTableSection new];
    addSection.footerTitle = NSLocalizedString(
        @"BLOCK_USER_BEHAVIOR_EXPLANATION", @"An explanation of the consequences of blocking another user.");

    [addSection
        addItem:[OWSTableItem
                    disclosureItemWithText:NSLocalizedString(@"SETTINGS_BLOCK_LIST_ADD_BUTTON",
                                               @"A label for the 'add phone number' button in the block list table.")
                               actionBlock:^{
                                   AddToBlockListViewController *vc = [[AddToBlockListViewController alloc] init];
                                   [weakSelf.navigationController pushViewController:vc animated:YES];
                               }]];
    [contents addSection:addSection];

    // "Blocklist" section

    NSArray<NSString *> *blockedPhoneNumbers =
        [self.blockingManager.blockedPhoneNumbers sortedArrayUsingSelector:@selector(compare:)];

    if (blockedPhoneNumbers.count > 0) {
        OWSTableSection *blockedContactsSection = [OWSTableSection new];
        blockedContactsSection.headerTitle
            = NSLocalizedString(@"BLOCK_LIST_BLOCKED_USERS_SECTION", @"Section header for users that has been blocked");

        for (NSString *phoneNumber in blockedPhoneNumbers) {
            [blockedContactsSection
                addItem:[OWSTableItem
                            itemWithCustomCellBlock:^{
                                ContactTableViewCell *cell = [ContactTableViewCell new];
                                [cell configureWithRecipientId:phoneNumber contactsManager:helper.contactsManager];
                                return cell;
                            }
                            customRowHeight:UITableViewAutomaticDimension
                            actionBlock:^{
                                [BlockListUIUtils showUnblockPhoneNumberActionSheet:phoneNumber
                                                                 fromViewController:weakSelf
                                                                    blockingManager:helper.blockingManager
                                                                    contactsManager:helper.contactsManager
                                                                    completionBlock:nil];
                            }]];
        }
        [contents addSection:blockedContactsSection];
    }

    NSArray<NSData *> *blockedGroupIds = self.blockingManager.blockedGroupIds;
    if (blockedGroupIds.count > 0) {
        OWSTableSection *blockedGroupsSection = [OWSTableSection new];
        blockedGroupsSection.headerTitle = NSLocalizedString(
            @"BLOCK_LIST_BLOCKED_GROUPS_SECTION", @"Section header for groups that has been blocked");
        for (NSData *groupId in blockedGroupIds) {
            TSGroupThread *groupThread = [TSGroupThread getOrCreateThreadWithGroupId:groupId];
            [blockedGroupsSection addItem:[OWSTableItem
                                              itemWithCustomCellBlock:^{
                                                  ContactTableViewCell *cell = [ContactTableViewCell new];
                                                  [cell configureWithThread:groupThread
                                                            contactsManager:helper.contactsManager];
                                                  return cell;
                                              }
                                              customRowHeight:UITableViewAutomaticDimension
                                              actionBlock:^{
                                                  [BlockListUIUtils showUnblockThreadActionSheet:groupThread
                                                                              fromViewController:weakSelf
                                                                                 blockingManager:helper.blockingManager
                                                                                 contactsManager:helper.contactsManager
                                                                                 completionBlock:nil];
                                              }]];
        }
        [contents addSection:blockedGroupsSection];
    }

    self.tableViewController.contents = contents;
}

#pragma mark - ContactsViewHelperDelegate

- (void)contactsViewHelperDidUpdateContacts
{
    [self updateTableContents];
}

- (BOOL)shouldHideLocalNumber
{
    return YES;
}

@end

NS_ASSUME_NONNULL_END
