/* Utils.m
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

#import "Utils.h"
#include "linphone/linphonecore.h"
#import <CommonCrypto/CommonDigest.h>
#import <sys/utsname.h>
#import <asl.h>

@implementation LinphoneLogger

#define FILE_SIZE 32
#define DOMAIN_SIZE 3

+ (void)log:(OrtpLogLevel)severity file:(const char *)file line:(int)line format:(NSString *)format, ... {
	va_list args;
	va_start(args, format);
	NSString *str = [[NSString alloc] initWithFormat:format arguments:args];
	const char *utf8str = [str cStringUsingEncoding:NSString.defaultCStringEncoding];
	const char *filename = strchr(file, '/') ? strrchr(file, '/') + 1 : file;
	ortp_log(severity, "(%*s:%-4d) %s", FILE_SIZE, filename + MAX((int)strlen(filename) - FILE_SIZE, 0), line, utf8str);
	va_end(args);
}

+ (void)enableLogs:(OrtpLogLevel)level {
	BOOL enabled = (level >= ORTP_DEBUG && level < ORTP_ERROR);
	static BOOL stderrInUse = NO;
	if (!stderrInUse) {
		asl_add_log_file(NULL, STDERR_FILENO);
		stderrInUse = YES;
	}
	linphone_core_set_log_collection_path([self cacheDirectory].UTF8String);
	linphone_core_enable_logs_with_cb(linphone_iphone_log_handler);
	linphone_core_enable_log_collection(enabled);
	if (level == 0) {
		linphone_core_set_log_level(ORTP_FATAL);
		ortp_set_log_level("ios", ORTP_FATAL);
		NSLog(@"I/%s/Disabling all logs", ORTP_LOG_DOMAIN);
	} else {
		NSLog(@"I/%s/Enabling %s logs", ORTP_LOG_DOMAIN, (enabled ? "all" : "application only"));
		linphone_core_set_log_level(level);
		ortp_set_log_level("ios", level == ORTP_DEBUG ? ORTP_DEBUG : ORTP_MESSAGE);
	}
}

+ (NSString *)cacheDirectory {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	NSString *cachePath = [paths objectAtIndex:0];
	BOOL isDir = NO;
	NSError *error;
	// cache directory must be created if not existing
	if (![[NSFileManager defaultManager] fileExistsAtPath:cachePath isDirectory:&isDir] && isDir == NO) {
		if (![[NSFileManager defaultManager] createDirectoryAtPath:cachePath
									   withIntermediateDirectories:NO
														attributes:nil
															 error:&error]) {
			LOGE(@"Could not create cache directory: %@", error);
		}
	}
	return cachePath;
}

#pragma mark - Logs Functions callbacks

/*void linphone_iphone_log_handler(const char *domain, OrtpLogLevel lev, const char *fmt, va_list args) {
	NSString *format = [[NSString alloc] initWithUTF8String:fmt];
	NSString *formatedString;
    if (args == NULL)
    {
        formatedString = format;
    }
    else
    {
    	formatedString = [[NSString alloc] initWithFormat:format arguments:args];
    }
	NSString *lvl = @"";
	switch (lev) {
		case ORTP_FATAL:
			lvl = @"F";
			break;
		case ORTP_ERROR:
			lvl = @"E";
			break;
		case ORTP_WARNING:
			lvl = @"W";
			break;
		case ORTP_MESSAGE:
			lvl = @"I";
			break;
		case ORTP_DEBUG:
		case ORTP_TRACE:
			lvl = @"D";
			break;
		case ORTP_LOGLEV_END:
			return;
	}
	if (!domain)
		domain = "liblinphone";
	// since \r are interpreted like \n, avoid double new lines when logging network packets (belle-sip)
	// output format is like: I/ios/some logs. We truncate domain to **exactly** DOMAIN_SIZE characters to have
	// fixed-length aligned logs
	NSLog(@"%@/%*.*s/%@", lvl, DOMAIN_SIZE, DOMAIN_SIZE, domain,
		  [formatedString stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"]);
}*/

void linphone_iphone_log_handler(const char *domain, OrtpLogLevel lev, const char *fmt, va_list args) {
	NSString *format = [[NSString alloc] initWithUTF8String:fmt];
	NSString *formatedString = [[NSString alloc] initWithFormat:format arguments:args];
	int lvl = ASL_LEVEL_NOTICE;
	switch (lev) {
		case ORTP_FATAL:
			lvl = ASL_LEVEL_CRIT;
			break;
		case ORTP_ERROR:
			lvl = ASL_LEVEL_ERR;
			break;
		case ORTP_WARNING:
			lvl = ASL_LEVEL_WARNING;
			break;
		case ORTP_MESSAGE:
			lvl = ASL_LEVEL_NOTICE;
			break;
		case ORTP_DEBUG:
		case ORTP_TRACE:
			lvl = ASL_LEVEL_INFO;
			break;
		case ORTP_LOGLEV_END:
			return;
	}
	if (!domain)
		domain = "lib";
	// since \r are interpreted like \n, avoid double new lines when logging network packets (belle-sip)
	// output format is like: I/ios/some logs. We truncate domain to **exactly** DOMAIN_SIZE characters to have
	// fixed-length aligned logs
	asl_log(NULL, NULL, lvl, "%*.*s/%s", DOMAIN_SIZE, DOMAIN_SIZE, domain,
			[formatedString stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"].UTF8String);
}

@end

@implementation LinphoneUtils

+ (BOOL)findAndResignFirstResponder:(UIView *)view {
	if (view.isFirstResponder) {
		[view resignFirstResponder];
		return YES;
	}
	for (UIView *subView in view.subviews) {
		if ([LinphoneUtils findAndResignFirstResponder:subView])
			return YES;
	}
	return NO;
}

+ (void)adjustFontSize:(UIView *)view mult:(float)mult {
	if ([view isKindOfClass:[UILabel class]]) {
		UILabel *label = (UILabel *)view;
		UIFont *font = [label font];
		[label setFont:[UIFont fontWithName:font.fontName size:font.pointSize * mult]];
	} else if ([view isKindOfClass:[UITextField class]]) {
		UITextField *label = (UITextField *)view;
		UIFont *font = [label font];
		[label setFont:[UIFont fontWithName:font.fontName size:font.pointSize * mult]];
	} else if ([view isKindOfClass:[UIButton class]]) {
		UIButton *button = (UIButton *)view;
		UIFont *font = button.titleLabel.font;
		[button.titleLabel setFont:[UIFont fontWithName:font.fontName size:font.pointSize * mult]];
	} else {
		for (UIView *subView in [view subviews]) {
			[LinphoneUtils adjustFontSize:subView mult:mult];
		}
	}
}

+ (void)buttonFixStates:(UIButton *)button {
	// Set selected+over title: IB lack !
	[button setTitle:[button titleForState:UIControlStateSelected]
			forState:(UIControlStateHighlighted | UIControlStateSelected)];

	// Set selected+over titleColor: IB lack !
	[button setTitleColor:[button titleColorForState:UIControlStateHighlighted]
				 forState:(UIControlStateHighlighted | UIControlStateSelected)];

	// Set selected+disabled title: IB lack !
	[button setTitle:[button titleForState:UIControlStateSelected]
			forState:(UIControlStateDisabled | UIControlStateSelected)];

	// Set selected+disabled titleColor: IB lack !
	[button setTitleColor:[button titleColorForState:UIControlStateDisabled]
				 forState:(UIControlStateDisabled | UIControlStateSelected)];
}

+ (void)buttonFixStatesForTabs:(UIButton *)button {
	// Set selected+over title: IB lack !
	[button setTitle:[button titleForState:UIControlStateSelected]
			forState:(UIControlStateHighlighted | UIControlStateSelected)];

	// Set selected+over titleColor: IB lack !
	[button setTitleColor:[button titleColorForState:UIControlStateSelected]
				 forState:(UIControlStateHighlighted | UIControlStateSelected)];

	// Set selected+disabled title: IB lack !
	[button setTitle:[button titleForState:UIControlStateSelected]
			forState:(UIControlStateDisabled | UIControlStateSelected)];

	// Set selected+disabled titleColor: IB lack !
	[button setTitleColor:[button titleColorForState:UIControlStateDisabled]
				 forState:(UIControlStateDisabled | UIControlStateSelected)];
}

+ (void)buttonMultiViewAddAttributes:(NSMutableDictionary *)attributes button:(UIButton *)button {
	[LinphoneUtils addDictEntry:attributes item:[button titleForState:UIControlStateNormal] key:@"title-normal"];
	[LinphoneUtils addDictEntry:attributes
						   item:[button titleForState:UIControlStateHighlighted]
							key:@"title-highlighted"];
	[LinphoneUtils addDictEntry:attributes item:[button titleForState:UIControlStateDisabled] key:@"title-disabled"];
	[LinphoneUtils addDictEntry:attributes item:[button titleForState:UIControlStateSelected] key:@"title-selected"];
	[LinphoneUtils addDictEntry:attributes
						   item:[button titleForState:UIControlStateDisabled | UIControlStateHighlighted]
							key:@"title-disabled-highlighted"];
	[LinphoneUtils addDictEntry:attributes
						   item:[button titleForState:UIControlStateSelected | UIControlStateHighlighted]
							key:@"title-selected-highlighted"];
	[LinphoneUtils addDictEntry:attributes
						   item:[button titleForState:UIControlStateSelected | UIControlStateDisabled]
							key:@"title-selected-disabled"];

	[LinphoneUtils addDictEntry:attributes
						   item:[button titleColorForState:UIControlStateNormal]
							key:@"title-color-normal"];
	[LinphoneUtils addDictEntry:attributes
						   item:[button titleColorForState:UIControlStateHighlighted]
							key:@"title-color-highlighted"];
	[LinphoneUtils addDictEntry:attributes
						   item:[button titleColorForState:UIControlStateDisabled]
							key:@"title-color-disabled"];
	[LinphoneUtils addDictEntry:attributes
						   item:[button titleColorForState:UIControlStateSelected]
							key:@"title-color-selected"];
	[LinphoneUtils addDictEntry:attributes
						   item:[button titleColorForState:UIControlStateDisabled | UIControlStateHighlighted]
							key:@"title-color-disabled-highlighted"];
	[LinphoneUtils addDictEntry:attributes
						   item:[button titleColorForState:UIControlStateSelected | UIControlStateHighlighted]
							key:@"title-color-selected-highlighted"];
	[LinphoneUtils addDictEntry:attributes
						   item:[button titleColorForState:UIControlStateSelected | UIControlStateDisabled]
							key:@"title-color-selected-disabled"];

	[LinphoneUtils addDictEntry:attributes item:NSStringFromUIEdgeInsets([button titleEdgeInsets]) key:@"title-edge"];
	[LinphoneUtils addDictEntry:attributes
						   item:NSStringFromUIEdgeInsets([button contentEdgeInsets])
							key:@"content-edge"];
	[LinphoneUtils addDictEntry:attributes item:NSStringFromUIEdgeInsets([button imageEdgeInsets]) key:@"image-edge"];

	[LinphoneUtils addDictEntry:attributes item:[button imageForState:UIControlStateNormal] key:@"image-normal"];
	[LinphoneUtils addDictEntry:attributes
						   item:[button imageForState:UIControlStateHighlighted]
							key:@"image-highlighted"];
	[LinphoneUtils addDictEntry:attributes item:[button imageForState:UIControlStateDisabled] key:@"image-disabled"];
	[LinphoneUtils addDictEntry:attributes item:[button imageForState:UIControlStateSelected] key:@"image-selected"];
	[LinphoneUtils addDictEntry:attributes
						   item:[button imageForState:UIControlStateDisabled | UIControlStateHighlighted]
							key:@"image-disabled-highlighted"];
	[LinphoneUtils addDictEntry:attributes
						   item:[button imageForState:UIControlStateSelected | UIControlStateHighlighted]
							key:@"image-selected-highlighted"];
	[LinphoneUtils addDictEntry:attributes
						   item:[button imageForState:UIControlStateSelected | UIControlStateDisabled]
							key:@"image-selected-disabled"];

	[LinphoneUtils addDictEntry:attributes
						   item:[button backgroundImageForState:UIControlStateNormal]
							key:@"background-normal"];
	[LinphoneUtils addDictEntry:attributes
						   item:[button backgroundImageForState:UIControlStateHighlighted]
							key:@"background-highlighted"];
	[LinphoneUtils addDictEntry:attributes
						   item:[button backgroundImageForState:UIControlStateDisabled]
							key:@"background-disabled"];
	[LinphoneUtils addDictEntry:attributes
						   item:[button backgroundImageForState:UIControlStateSelected]
							key:@"background-selected"];
	[LinphoneUtils addDictEntry:attributes
						   item:[button backgroundImageForState:UIControlStateDisabled | UIControlStateHighlighted]
							key:@"background-disabled-highlighted"];
	[LinphoneUtils addDictEntry:attributes
						   item:[button backgroundImageForState:UIControlStateSelected | UIControlStateHighlighted]
							key:@"background-selected-highlighted"];
	[LinphoneUtils addDictEntry:attributes
						   item:[button backgroundImageForState:UIControlStateSelected | UIControlStateDisabled]
							key:@"background-selected-disabled"];
}

+ (void)buttonMultiViewApplyAttributes:(NSDictionary *)attributes button:(UIButton *)button {
	[button setTitle:[LinphoneUtils getDictEntry:attributes key:@"title-normal"] forState:UIControlStateNormal];
	[button setTitle:[LinphoneUtils getDictEntry:attributes key:@"title-highlighted"]
			forState:UIControlStateHighlighted];
	[button setTitle:[LinphoneUtils getDictEntry:attributes key:@"title-disabled"] forState:UIControlStateDisabled];
	[button setTitle:[LinphoneUtils getDictEntry:attributes key:@"title-selected"] forState:UIControlStateSelected];
	[button setTitle:[LinphoneUtils getDictEntry:attributes key:@"title-disabled-highlighted"]
			forState:UIControlStateDisabled | UIControlStateHighlighted];
	[button setTitle:[LinphoneUtils getDictEntry:attributes key:@"title-selected-highlighted"]
			forState:UIControlStateSelected | UIControlStateHighlighted];
	[button setTitle:[LinphoneUtils getDictEntry:attributes key:@"title-selected-disabled"]
			forState:UIControlStateSelected | UIControlStateDisabled];

	[button setTitleColor:[LinphoneUtils getDictEntry:attributes key:@"title-color-normal"]
				 forState:UIControlStateNormal];
	[button setTitleColor:[LinphoneUtils getDictEntry:attributes key:@"title-color-highlighted"]
				 forState:UIControlStateHighlighted];
	[button setTitleColor:[LinphoneUtils getDictEntry:attributes key:@"title-color-disabled"]
				 forState:UIControlStateDisabled];
	[button setTitleColor:[LinphoneUtils getDictEntry:attributes key:@"title-color-selected"]
				 forState:UIControlStateSelected];
	[button setTitleColor:[LinphoneUtils getDictEntry:attributes key:@"title-color-disabled-highlighted"]
				 forState:UIControlStateDisabled | UIControlStateHighlighted];
	[button setTitleColor:[LinphoneUtils getDictEntry:attributes key:@"title-color-selected-highlighted"]
				 forState:UIControlStateSelected | UIControlStateHighlighted];
	[button setTitleColor:[LinphoneUtils getDictEntry:attributes key:@"title-color-selected-disabled"]
				 forState:UIControlStateSelected | UIControlStateDisabled];

	[button setTitleEdgeInsets:UIEdgeInsetsFromString([LinphoneUtils getDictEntry:attributes key:@"title-edge"])];
	[button setContentEdgeInsets:UIEdgeInsetsFromString([LinphoneUtils getDictEntry:attributes key:@"content-edge"])];
	[button setImageEdgeInsets:UIEdgeInsetsFromString([LinphoneUtils getDictEntry:attributes key:@"image-edge"])];

	[button setImage:[LinphoneUtils getDictEntry:attributes key:@"image-normal"] forState:UIControlStateNormal];
	[button setImage:[LinphoneUtils getDictEntry:attributes key:@"image-highlighted"]
			forState:UIControlStateHighlighted];
	[button setImage:[LinphoneUtils getDictEntry:attributes key:@"image-disabled"] forState:UIControlStateDisabled];
	[button setImage:[LinphoneUtils getDictEntry:attributes key:@"image-selected"] forState:UIControlStateSelected];
	[button setImage:[LinphoneUtils getDictEntry:attributes key:@"image-disabled-highlighted"]
			forState:UIControlStateDisabled | UIControlStateHighlighted];
	[button setImage:[LinphoneUtils getDictEntry:attributes key:@"image-selected-highlighted"]
			forState:UIControlStateSelected | UIControlStateHighlighted];
	[button setImage:[LinphoneUtils getDictEntry:attributes key:@"image-selected-disabled"]
			forState:UIControlStateSelected | UIControlStateDisabled];

	[button setBackgroundImage:[LinphoneUtils getDictEntry:attributes key:@"background-normal"]
					  forState:UIControlStateNormal];
	[button setBackgroundImage:[LinphoneUtils getDictEntry:attributes key:@"background-highlighted"]
					  forState:UIControlStateHighlighted];
	[button setBackgroundImage:[LinphoneUtils getDictEntry:attributes key:@"background-disabled"]
					  forState:UIControlStateDisabled];
	[button setBackgroundImage:[LinphoneUtils getDictEntry:attributes key:@"background-selected"]
					  forState:UIControlStateSelected];
	[button setBackgroundImage:[LinphoneUtils getDictEntry:attributes key:@"background-disabled-highlighted"]
					  forState:UIControlStateDisabled | UIControlStateHighlighted];
	[button setBackgroundImage:[LinphoneUtils getDictEntry:attributes key:@"background-selected-highlighted"]
					  forState:UIControlStateSelected | UIControlStateHighlighted];
	[button setBackgroundImage:[LinphoneUtils getDictEntry:attributes key:@"background-selected-disabled"]
					  forState:UIControlStateSelected | UIControlStateDisabled];
}

+ (void)addDictEntry:(NSMutableDictionary *)dict item:(id)item key:(id)key {
	if (item != nil && key != nil) {
		[dict setObject:item forKey:key];
	}
}

+ (id)getDictEntry:(NSDictionary *)dict key:(id)key {
	if (key != nil) {
		return [dict objectForKey:key];
	}
	return nil;
}

+ (NSString *)deviceName {
	struct utsname systemInfo;
	uname(&systemInfo);

	return [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
}

@end

@implementation NSNumber (HumanReadableSize)

- (NSString *)toHumanReadableSize {
	float floatSize = [self floatValue];
	if (floatSize < 1023)
		return ([NSString stringWithFormat:@"%1.0f bytes", floatSize]);
	floatSize = floatSize / 1024;
	if (floatSize < 1023)
		return ([NSString stringWithFormat:@"%1.1f KB", floatSize]);
	floatSize = floatSize / 1024;
	if (floatSize < 1023)
		return ([NSString stringWithFormat:@"%1.1f MB", floatSize]);
	floatSize = floatSize / 1024;

	return ([NSString stringWithFormat:@"%1.1f GB", floatSize]);
}

@end

@implementation NSString (md5)

- (NSString *)md5 {
	const char *ptr = [self UTF8String];
	unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
	CC_MD5(ptr, (unsigned int)strlen(ptr), md5Buffer);
	NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
	for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
		[output appendFormat:@"%02x", md5Buffer[i]];
	}

	return output;
}

@end
