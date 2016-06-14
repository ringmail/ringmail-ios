/* ChatTableViewController.m
 *
 * Copyright (C) 2012  Belledonne Comunications, Grenoble, France
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#import "ChatTableViewController.h"
#import "UIChatCell.h"

#import "FileTransferDelegate.h"

#import "linphone/linphonecore.h"
#import "PhoneMainView.h"
#import "UACellBackgroundView.h"
#import "UILinphone.h"
#import "Utils.h"

@implementation ChatTableViewController

@synthesize chatList;

#pragma mark - Lifecycle Functions

- (id)init {
    if (self = [super init])
    {
        self.chatList = [[LinphoneManager instance].chatManager dbGetSessions];
    }
    return self;
}

#pragma mark - ViewController Functions

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	self.tableView.accessibilityIdentifier = @"ChatRoom list";
	[self loadData];
}

#pragma mark -

- (void)loadData {
    self.chatList = [[LinphoneManager instance].chatManager dbGetSessions];
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        [[self tableView] reloadData];
    }];
}

#pragma mark - UITableViewDataSource Functions

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.chatList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *kCellId = @"UIChatCell";
	UIChatCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellId];
	if (cell == nil) {
		cell = [[UIChatCell alloc] initWithIdentifier:kCellId];

		// Background View
		UACellBackgroundView *selectedBackgroundView = [[UACellBackgroundView alloc] initWithFrame:CGRectZero];
		cell.selectedBackgroundView = selectedBackgroundView;
		[selectedBackgroundView setBackgroundColor:LINPHONE_TABLE_CELL_BACKGROUND_COLOR];
	}
    NSArray *chatData = [self.chatList objectAtIndex:[indexPath row]];
    [cell setChatTag:[chatData objectAtIndex:0]];
    [cell setChatUnread:[chatData objectAtIndex:1]];
    [cell setLastMessage:[chatData objectAtIndex:2]];
    [cell update];
	return cell;
}

#pragma mark - UITableViewDelegate Functions

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	// Dead code
	/*[tableView deselectRowAtIndexPath:indexPath animated:NO];
    NSString *chatRoom = [[self.chatList objectAtIndex:[indexPath row]] objectAtIndex:0];

	// Go to ChatRoom view
    [[LinphoneManager instance] setChatTag:chatRoom];
    [[PhoneMainView instance] changeCurrentView:[ChatRoomViewController compositeViewDescription] push:TRUE];*/
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView
		   editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	// Detemine if it's in editing mode
	if (self.editing) {
		return UITableViewCellEditingStyleDelete;
	}
	return UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)tableView
	commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
	 forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		[tableView beginUpdates];

		/*LinphoneChatRoom *chatRoom = (LinphoneChatRoom *)ms_list_nth_data(data, (int)[indexPath row]);
		LinphoneChatMessage *last_msg = linphone_chat_room_get_user_data(chatRoom);
		if (last_msg) {
			linphone_chat_message_unref(last_msg);
			linphone_chat_room_set_user_data(chatRoom, NULL);
		}

		for (FileTransferDelegate *ftd in [[LinphoneManager instance] fileTransferDelegates]) {
			if (linphone_chat_message_get_chat_room(ftd.message) == chatRoom) {
				[ftd cancel];
			}
		}
		linphone_chat_room_delete_history(chatRoom);
		linphone_chat_room_unref(chatRoom);
		data = ms_list_remove(data, chatRoom);*/

		// will force a call to [self loadData]
		[[NSNotificationCenter defaultCenter] postNotificationName:kRgTextReceived object:self];

		[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
						 withRowAnimation:UITableViewRowAnimationFade];
		[tableView endUpdates];
	}
}

@end
