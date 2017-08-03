#import "Favorite.h"
#import "RingKit.h"
#import "RKContactStore.h"
#import "LinphoneManager.h"

@implementation Favorite

- (instancetype)initWithData:(NSDictionary *)data
{
	if (self = [super init])
	{
		_data = [data copy];
	}
	return self;
}

- (void)favoriteClick
{
	ABRecordRef contact = [[[LinphoneManager instance] fastAddressBook] getContactById:self.data[@"contactId"]];
	if (contact != NULL)
	{
        NSString *rgAddress = [[RKContactStore sharedInstance] defaultPrimaryAddress:contact];
        if (rgAddress != nil)
        {
    		RKCommunicator* comm = [RKCommunicator sharedInstance];
    		RKAddress* address = [RKAddress newWithString:rgAddress];
    		RKThread* thread = [comm getThreadByAddress:address];
    		[comm startMessageView:thread];
        }
	}
}

@end
