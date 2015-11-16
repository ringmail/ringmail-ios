//
//  RgChatQuestionTable.h
//  ringmail
//
//  Created by Mike Frager on 11/15/15.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "DXTableViewModel.h"

@interface RgChatQuestionTable : UITableViewController

@property (nonatomic, strong) IBOutlet UITableView *questionTable;
@property (nonatomic, strong) NSMutableArray *answerList;
@property (nonatomic, strong) DXTableViewModel *tableViewModel;

@end
