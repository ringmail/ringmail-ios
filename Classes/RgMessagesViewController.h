#import "JSQMessages.h"
#import "RgChatModelData.h"
#import "RgManager.h"

@interface RgMessagesViewController : JSQMessagesViewController

@property (strong, nonatomic) RgChatModelData *chatData;
@property (strong, nonatomic) NSString *chatRoom;

- (void)receiveMessage;
- (void)receiveMessagePressed:(UIBarButtonItem *)sender;

@end
