/* UICallButton.m
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

#import "UICallButton.h"
#import "LinphoneManager.h"

#import "PhoneMainView.h"

#import <CoreTelephony/CTCallCenter.h>

@implementation UICallButton

@synthesize addressField;

#pragma mark - Lifecycle Functions

- (void)initUICallButton {
	[self addTarget:self action:@selector(touchUp:) forControlEvents:UIControlEventTouchUpInside];
}

- (id)init {
	self = [super init];
	if (self) {
		[self initUICallButton];
	}
	return self;
}

- (id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		[self initUICallButton];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
	self = [super initWithCoder:decoder];
	if (self) {
		[self initUICallButton];
	}
	return self;
}

#pragma mark -

- (void)touchUp:(id)sender {
	__block NSString *address = [addressField text];
	address = [address stringByReplacingOccurrencesOfRegex:@"^\\s+" withString:@""];
	address = [address stringByReplacingOccurrencesOfRegex:@"\\s+$" withString:@""];
	if ([address length] > 0)
    {
        if ([RgManager checkRingMailAddress:address])
        {
			if ([[address substringToIndex:1] isEqualToString:@"#"])
			{
				[[RgNetwork instance] lookupHashtag:@{
					@"hashtag": address,
				} callback:^(AFHTTPRequestOperation *operation, id responseObject) {
					NSDictionary* res = responseObject;
					NSString *ok = [res objectForKey:@"result"];
					if ([ok isEqualToString:@"ok"])
					{
		                [[[LinphoneManager instance] chatManager] dbInsertCall:@{
                            @"sip": @"",
                            @"address": address,
                            @"state": [NSNumber numberWithInt:0],
                            @"inbound": [NSNumber numberWithBool:NO],
					    }];
    					[[NSNotificationCenter defaultCenter] postNotificationName:kRgLaunchBrowser object:self userInfo:@{
    						@"address": [res objectForKey:@"target"],
    					}];
    					[[NSNotificationCenter defaultCenter] postNotificationName:kRgMainRefresh object:self userInfo:nil];
					}
				}];
			}
			else
			{
				[RgManager startCall:address contact:NULL video:NO];
			}
        }
	}
}

@end
