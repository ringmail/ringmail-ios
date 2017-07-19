/* UIHashtagButton.m
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

#import "UIHashtagButton.h"
#import "LinphoneManager.h"

#import "PhoneMainView.h"

#import <CoreTelephony/CTCallCenter.h>

@implementation UIHashtagButton

@synthesize addressField;

#pragma mark - Lifecycle Functions

- (void)initUIHashtagButton {
	[self addTarget:self action:@selector(touchUp:) forControlEvents:UIControlEventTouchUpInside];
}

- (id)init {
	self = [super init];
	if (self) {
		[self initUIHashtagButton];
	}
	return self;
}

- (id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		[self initUIHashtagButton];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
	self = [super initWithCoder:decoder];
	if (self) {
		[self initUIHashtagButton];
	}
	return self;
}

#pragma mark -

- (void)touchUp:(id)sender {
	NSString *address = [addressField text];
	address = [address stringByReplacingOccurrencesOfRegex:@"^\\s+" withString:@""];
	address = [address stringByReplacingOccurrencesOfRegex:@"\\s+$" withString:@""];
	if ([address length] > 0)
    {
        if ([RgManager checkRingMailAddress:address])
        {
			if ([[address substringToIndex:1] isEqualToString:@"#"])
			{
				addressField.text = @"";
				[RgManager startHashtag:address];
			}
        }
	}
}

@end
