#import "JSQMessages.h"
#import "RgChatModelData.h"

@interface RgMessagesViewController : JSQMessagesViewController

@property (strong, nonatomic) RgChatModelData *demoData;

- (void)receiveMessagePressed:(UIBarButtonItem *)sender;

@end
