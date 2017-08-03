//
//  RgChatQuestionTable.m
//  ringmail
//
//  Created by Mike Frager on 11/15/15.
//
//

#import "LinphoneManager.h"
#import "PhoneMainView.h"
#import "RgChatQuestionTable.h"
#import "RgChatQuestionInputCell.h"

@implementation RgChatQuestionTable

- (void)viewDidLoad
{
    self.tableViewModel = [[DXTableViewModel alloc] init];
    self.answerList = [NSMutableArray array];
    
    __block NSMutableArray *answers = self.answerList;
    
    DXTableViewSection *answerSection = [[DXTableViewSection alloc] initWithName:@"Answer"];
    answerSection.headerTitle = @"Answers:";
  
    DXTableViewSection *questionSection = [[DXTableViewSection alloc] initWithName:@"Question"];
    questionSection.headerTitle = @"Question:";
    DXTableViewRow *questionRow = [[DXTableViewRow alloc] initWithCellReuseIdentifier:@"InputCell"];
    questionRow.cellNib = [UINib nibWithNibName:@"RgChatQuestionInputCell" bundle:nil];
    questionRow.editingStyle = UITableViewCellEditingStyleNone;
    [questionSection addRow:questionRow];
    
    DXTableViewRow *addRow = [[DXTableViewRow alloc] initWithCellReuseIdentifier:@"InputCell"];
    addRow.cellNib = [UINib nibWithNibName:@"RgChatQuestionInputCell" bundle:nil];
    addRow.editingStyle = UITableViewCellEditingStyleInsert;
    
    void (^removeItemActionBlock)() = ^(DXTableViewRow *row) {
        NSUInteger index = [row.rowIndexPath indexAtPosition:1];
        [answers removeObjectAtIndex:index];
        NSLog(@"RingMail - Answers: %@", answers);
        [answerSection deleteRows:@[row] withRowAnimation:UITableViewRowAnimationFade];
    };
    
    void (^addItemActionBlock)() = ^(DXTableViewRow *row) {
        RgChatQuestionInputCell *inputCell = (RgChatQuestionInputCell*) row.cell;
        __block NSString* theAnswer = [NSString stringWithString:inputCell.textField.text];
        inputCell.textField.text = @"";
        if (! [theAnswer isEqualToString:@""] && [answers count] < 5) // Max 5 answers
        {
            DXTableViewRow *newRow = [[DXTableViewRow alloc] initWithCellReuseIdentifier:@"AnswerCell"];
            newRow.cellClass = [UITableViewCell class];
            newRow.configureCellBlock = ^(DXTableViewRow *row, UITableViewCell *cell) {
                cell.textLabel.text = theAnswer;
            };
            newRow.commitEditingStyleForRowBlock = removeItemActionBlock;
            [self insertRows:@[newRow] section:answerSection withRowAnimation:UITableViewRowAnimationTop];
            [answers addObject:theAnswer];
            NSLog(@"RingMail - Answers: %@", answers);
            [row.tableView deselectRowAtIndexPath:row.rowIndexPath animated:YES];
        }
    };
    addRow.commitEditingStyleForRowBlock = addItemActionBlock;
    [answerSection addRow:addRow];
    
    DXTableViewSection *sendSection = [[DXTableViewSection alloc] initWithName:@"Send"];
    sendSection.headerHeight = 0.0;
    sendSection.footerHeight = 0.0;
    DXTableViewRow *sendRow = [[DXTableViewRow alloc] initWithCellReuseIdentifier:@"SendCell"];
    sendRow.cellClass = [UITableViewCell class];
    sendRow.editingStyle = UITableViewCellEditingStyleNone;
    sendRow.configureCellBlock = ^(DXTableViewRow *row, UITableViewCell *cell) {
        cell.textLabel.text = @"Send Question";
    };
    sendRow.didSelectRowBlock = ^(DXTableViewRow *row) {
        RgChatQuestionInputCell *inputCell = (RgChatQuestionInputCell*)questionRow.cell;
        NSString* theQuestion = [NSString stringWithString:inputCell.textField.text];
        if (! [theQuestion isEqualToString:@""])
        {
            RgChatQuestionInputCell *lastCell = (RgChatQuestionInputCell*)addRow.cell;
            NSString* lastAnswer = [NSString stringWithString:lastCell.textField.text];
            if (! [lastAnswer isEqualToString:@""])
            {
                [answers addObject:lastAnswer];
            }
            if ([answers count] > 1) // Minimum 2 items
            {
                NSLog(@"RingMail: Send Question: %@\nAnswers: %@", theQuestion, answers);
                //NSString *chatRoom = [[LinphoneManager instance] chatTag];
                //[[[LinphoneManager instance] chatManager] sendQuestionTo:chatRoom question:theQuestion answers:answers];
                lastCell.textField.text = @"";
                inputCell.textField.text = @"";
                NSMutableArray *rowList = [NSMutableArray arrayWithArray:[answerSection rows]];
                [rowList removeLastObject];
                for (DXTableViewRow *aRow in rowList)
                {
                    [answerSection deleteRows:@[aRow] withRowAnimation:UITableViewRowAnimationNone];
                }
                answers = [NSMutableArray array];
                [[PhoneMainView instance] popCurrentView];
            }
            else
            {
                if (! [lastAnswer isEqualToString:@""])
                {
                    [answers removeLastObject];
                }
            }
        }
        [row.tableView deselectRowAtIndexPath:row.rowIndexPath animated:YES];

    };
    [sendSection addRow:sendRow];
   
    [self.tableViewModel addSection:questionSection];
    [self.tableViewModel addSection:answerSection];
    [self.tableViewModel addSection:sendSection];
    [self setEditing:YES];
    self.tableViewModel.tableView = self.questionTable;
}

- (void)insertRows:(NSArray *)rows section:(DXTableViewSection*)section withRowAnimation:(UITableViewRowAnimation)animation
{
    NSMutableArray *indexPaths = [NSMutableArray array];
    for (DXTableViewRow *aRow in rows) {
        // TODO: insert whole array at once, inserting element by element changes the order
       [indexPaths addObject:[section insertRow:aRow atIndex:[section numberOfRows] - 1]];
    }
    [self.tableViewModel.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:animation];
}


@end
