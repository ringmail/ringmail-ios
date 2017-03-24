#import "FavoriteModelController.h"

#import <UIKit/UIColor.h>

#import "Favorite.h"
#import "FavoritesPage.h"
#import "LinphoneManager.h"

@implementation FavoriteModelController

@synthesize mainCount;

- (instancetype)init
{
    if (self = [super init]) {
        mainCount = [NSNumber numberWithInteger:0];
    }
    return self;
}

- (FavoritesPage *)fetchNewFavoritesPageWithCount:(NSInteger)count;
{
	NSAssert(count >= 1, @"Count should be a positive integer");
	// TODO: move this to SendViewController.mm and pass value into root component data
	NSArray* favQuery = [[[LinphoneManager instance] chatManager] dbGetMainList:nil favorites:YES];
	//
	UIImage *defaultImage = [UIImage imageNamed:@"avatar_unknown_small.png"];
	NSMutableArray* favData = [NSMutableArray array];
	for (NSDictionary* r in favQuery)
    {
        NSString *address = [r objectForKey:@"session_tag"];
		NSMutableDictionary *newdata = [NSMutableDictionary dictionaryWithDictionary:r];
		NSNumber *contactId = r[@"contact_id"];
		ABRecordRef contact = NULL;
		if (NILIFNULL(contactId) != nil)
		{
    		contact = [[[LinphoneManager instance] fastAddressBook] getContactById:contactId];
    		if (contact)
    		{
    			UIImage *customImage = [FastAddressBook getContactImage:contact thumbnail:true];
                [newdata setObject:((customImage != nil) ? customImage : defaultImage) forKey:@"image"];
                [newdata setObject:[FastAddressBook getContactDisplayName:contact] forKey:@"label"];
    		}
		}
	   	if (! contact)
		{
            [newdata setObject:defaultImage forKey:@"image"];
            [newdata setObject:address forKey:@"label"];
		}
		NSArray *nameParts = [newdata[@"label"] componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
		newdata[@"name"] = nameParts[0];
		[favData addObject:newdata];
	}
	NSMutableArray *favList = [NSMutableArray array];
	NSInteger added = 0;
	for (NSUInteger i = 0; i < count; i++)
    {
		NSInteger mainIndex = [mainCount intValue] + i;
		if ([favData count] > mainIndex)
		{
			Favorite* favItem = [[Favorite alloc] initWithData:[favData objectAtIndex:mainIndex]];
			[favList addObject:favItem];
			added++;
		}
	}
	FavoritesPage *favsPage = [[FavoritesPage alloc] initWithFavorites:favList position:[mainCount integerValue]];
	mainCount = [NSNumber numberWithInteger:[mainCount integerValue] + added];
	return favsPage;
}

@end
