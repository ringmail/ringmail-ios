/* UIChatCell.m
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
 *  GNU Library General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#import "UIChatCell.h"
#import "PhoneMainView.h"
#import "LinphoneManager.h"
#import "Utils.h"
#import "RgChatManager.h"

@implementation UIChatCell

@synthesize avatarImage;
@synthesize addressLabel;
@synthesize deleteButton;
@synthesize unreadMessageLabel;
@synthesize unreadMessageView;
@synthesize chatTag = _chatTag;
@synthesize chatUnread = _chatUnread;

#pragma mark - Lifecycle Functions

- (id)initWithIdentifier:(NSString *)identifier {
	if ((self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier]) != nil) {
		NSArray *arrayOfViews = [[NSBundle mainBundle] loadNibNamed:@"UIChatCell" owner:self options:nil];

		if ([arrayOfViews count] >= 1) {

			[self.contentView addSubview:[arrayOfViews objectAtIndex:0]];
		}
	}
	return self;
}

- (NSString *)accessibilityValue {
    return [NSString stringWithFormat:@"%@ (%li)", addressLabel.text, (long)[unreadMessageLabel.text integerValue]];
}

- (void)update {
    NSString *displayName = _chatTag;
	UIImage *image = nil;
	if (_chatTag == nil) {
		LOGW(@"Cannot update chat cell: null chat");
		return;
	}

	ABRecordRef contact = [[[LinphoneManager instance] fastAddressBook] getContact:displayName];
	if (contact != nil) {
		displayName = [FastAddressBook getContactDisplayName:contact];
		image = [FastAddressBook getContactImage:contact thumbnail:true];
	}

	[addressLabel setText:displayName];

	// Avatar
	if (image == nil) {
		image = [UIImage imageNamed:@"avatar_unknown_small.png"];
	}
	[avatarImage setImage:image];

    NSLog(@"Chat Room: %@ Unread: %@", _chatTag, _chatUnread);
    if ([_chatUnread integerValue] > 0)
    {
        unreadMessageLabel.text = [_chatUnread stringValue];
        [unreadMessageView setHidden:FALSE];
    }
    else
    {
        unreadMessageLabel.text = [NSString stringWithFormat:@"0"];
        [unreadMessageView setHidden:TRUE];
    }
}

- (void)setEditing:(BOOL)editing {
	[self setEditing:editing animated:FALSE];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
	if (animated) {
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:0.3];
	}
	if (editing) {
		[deleteButton setAlpha:1.0f];
	} else {
		[deleteButton setAlpha:0.0f];
	}
	if (animated) {
		[UIView commitAnimations];
	}
}

#pragma mark - Action Functions

- (IBAction)onDeleteClick:(id)event {
	/*if (chatRoom != NULL) {
		UIView *view = [self superview];
		// Find TableViewCell
		while (view != nil && ![view isKindOfClass:[UITableView class]])
			view = [view superview];
		if (view != nil) {
			UITableView *tableView = (UITableView *)view;
			NSIndexPath *indexPath = [tableView indexPathForCell:self];
			[[tableView dataSource] tableView:tableView
						   commitEditingStyle:UITableViewCellEditingStyleDelete
							forRowAtIndexPath:indexPath];
		}
	}*/
}

@end
