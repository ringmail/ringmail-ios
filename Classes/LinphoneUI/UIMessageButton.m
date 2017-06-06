/* UIMessageButton.m
 *
 * Copyright (C) 2011  Belledonne Comunications, Grenoble, France
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

#import "UIMessageButton.h"
#import "LinphoneManager.h"
#import "RgManager.h"

#import "PhoneMainView.h"

#import <CoreTelephony/CTCallCenter.h>

@implementation UIMessageButton

@synthesize addressField;

#pragma mark - Lifecycle Functions

- (void)initUIMessageButton {
	[self addTarget:self action:@selector(touchUp:) forControlEvents:UIControlEventTouchUpInside];
}

- (id)init {
	self = [super init];
	if (self) {
		[self initUIMessageButton];
	}
	return self;
}

- (id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		[self initUIMessageButton];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
	self = [super initWithCoder:decoder];
	if (self) {
		[self initUIMessageButton];
	}
	return self;
}

#pragma mark -

- (void)touchUp:(id)sender {
	NSString *address = [addressField text];
	if ([address length] > 0)
	{
		if ([RgManager checkRingMailAddress:address])
		{
    		LinphoneManager *lm = [LinphoneManager instance];
            ABRecordRef contact = [[lm fastAddressBook] getContact:address];
        	NSNumber *contactNum = nil;
        	if (contact != NULL)
        	{
        		contactNum = [[lm fastAddressBook] getContactId:contact];
        	}
			NSDictionary *sessionData = [[lm chatManager] dbGetSessionID:address to:nil contact:contactNum uuid:nil];
            [[LinphoneManager instance] setChatSession:sessionData[@"id"]];
            [[PhoneMainView instance] changeCurrentView:[MessageViewController compositeViewDescription] push:TRUE];
		}
	}
}

@end
