//
//  MessageViewController.m
//  Messenger
//
//  Created by Ignacio Romero Zurbuchen on 8/15/14.
//  Copyright (c) 2014 Slack Technologies, Inc. All rights reserved.
//

#import "MessageViewController.h"
#import "MessageTableViewCell.h"
#import "MessageTextView.h"
#import "TypingIndicatorView.h"
#import "Message.h"
#import "UIColor+Hex.h"

#import <LoremIpsum/LoremIpsum.h>

#define DEBUG_CUSTOM_TYPING_INDICATOR 0
#define DEBUG_CUSTOM_BOTTOM_VIEW 0

@interface MessageViewController ()

@property (nonatomic, strong) NSArray *users;
@property (nonatomic, strong) NSArray *channels;
@property (nonatomic, strong) NSArray *emojis;
@property (nonatomic, strong) NSArray *commands;

@property (nonatomic, strong) NSArray *searchResult;

@property (nonatomic, strong) UIWindow *pipWindow;

@property (nonatomic, weak) Message *editingMessage;

@end

@implementation MessageViewController

#pragma mark - UICompositeViewDelegate Functions

static UICompositeViewDescription *compositeDescription = nil;

+ (UICompositeViewDescription *)compositeViewDescription {
	if (compositeDescription == nil) {
		compositeDescription = [[UICompositeViewDescription alloc] init:@"Message"
																content:@"MessageViewController"
															   stateBar:@"UIStateBar"
														stateBarEnabled:YES
                                                                 navBar:@"UIChatNavBar"
																 tabBar:nil
                                                          navBarEnabled:YES
														  tabBarEnabled:NO
															 fullscreen:NO
														  landscapeMode:[LinphoneManager runningOnIpad]
														   portraitMode:YES
                                                                segLeft:@"All"
                                                               segRight:@"Missed"];
		compositeDescription.darkBackground = true;
	}
	return compositeDescription;
}

#pragma mark - Init

- (instancetype)init
{
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    [flowLayout setMinimumInteritemSpacing:0];
    [flowLayout setMinimumLineSpacing:0];
    self = [super initWithCollectionViewLayout:flowLayout];
    //self = [super initWithTableViewStyle:UITableViewStylePlain];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

+ (UITableViewStyle)tableViewStyleForCoder:(NSCoder *)decoder
{
    return UITableViewStylePlain;
}

- (void)commonInit
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textInputbarDidMove:) name:SLKTextInputbarDidMoveNotification object:nil];
    
    // Register a SLKTextView subclass, if you need any special appearance and/or behavior customisation.
    [self registerClassForTextView:[MessageTextView class]];
    
#if DEBUG_CUSTOM_TYPING_INDICATOR
    // Register a UIView subclass, conforming to SLKTypingIndicatorProtocol, to use a custom typing indicator view.
    [self registerClassForTypingIndicatorView:[TypingIndicatorView class]];
#endif
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    // SLKTVC's configuration
    self.bounces = YES;
    self.shakeToClearEnabled = YES;
    self.keyboardPanningEnabled = YES;
    self.inverted = YES;
    
    //[self.leftButton setImage:[UIImage imageNamed:@"icn_upload"] forState:UIControlStateNormal];
	[self.leftButton setTitle:@"" forState:UIControlStateNormal];
    [self.leftButton setTintColor:[UIColor colorWithHex:@"#818181"]];
	[self.leftButton setImage:[UIImage imageNamed:@"ringmail_chat_attach"] forState:UIControlStateNormal];
	
    //[self.rightButton setTitle:NSLocalizedString(@"Send", nil) forState:UIControlStateNormal];
	[self.rightButton setTitle:@"" forState:UIControlStateNormal];
	[self.rightButton setBackgroundImage:[UIImage imageNamed:@"ringmail_chat_send"] forState:UIControlStateNormal];
	
    self.textInputbar.autoHideRightButton = YES;
    self.textInputbar.maxCharCount = 256;
    self.textInputbar.counterStyle = SLKCounterStyleSplit;
    self.textInputbar.counterPosition = SLKCounterPositionTop;
    
    [self.textInputbar.editorTitle setTextColor:[UIColor darkGrayColor]];
    [self.textInputbar.editorLeftButton setTintColor:[UIColor colorWithRed:0.0/255.0 green:122.0/255.0 blue:255.0/255.0 alpha:1.0]];
    [self.textInputbar.editorRightButton setTintColor:[UIColor colorWithRed:0.0/255.0 green:122.0/255.0 blue:255.0/255.0 alpha:1.0]];
    
#if DEBUG_CUSTOM_BOTTOM_VIEW
    // Example of view that can be added to the bottom of the text view
    
    UIView *bannerView = [UIView new];
    bannerView.translatesAutoresizingMaskIntoConstraints = NO;
    bannerView.backgroundColor = [UIColor blueColor];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(bannerView);
    
    [self.textInputbar.contentView addSubview:bannerView];
    [self.textInputbar.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[bannerView]|" options:0 metrics:nil views:views]];
    [self.textInputbar.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[bannerView(40)]|" options:0 metrics:nil views:views]];
#endif
    
#if !DEBUG_CUSTOM_TYPING_INDICATOR
    self.typingIndicatorView.canResignByTouch = YES;
#endif
    
    [self.autoCompletionView registerClass:[MessageTableViewCell class] forCellReuseIdentifier:AutoCompletionCellIdentifier];
    //[self registerPrefixesForAutoCompletion:@[@"@", @"#", @":", @"+:", @"/"]];
	
    /*[self.textView registerMarkdownFormattingSymbol:@"*" withTitle:@"Bold"];
    [self.textView registerMarkdownFormattingSymbol:@"_" withTitle:@"Italics"];
    [self.textView registerMarkdownFormattingSymbol:@"~" withTitle:@"Strike"];
    [self.textView registerMarkdownFormattingSymbol:@"`" withTitle:@"Code"];
    [self.textView registerMarkdownFormattingSymbol:@"```" withTitle:@"Preformatted"];
    [self.textView registerMarkdownFormattingSymbol:@">" withTitle:@"Quote"];*/
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}


#pragma mark - Action Methods

- (void)hideOrShowTextInputbar:(id)sender
{
    BOOL hide = !self.textInputbarHidden;
    
    UIImage *image = hide ? [UIImage imageNamed:@"icn_arrow_up"] : [UIImage imageNamed:@"icn_arrow_down"];
    UIBarButtonItem *buttonItem = (UIBarButtonItem *)sender;
    
    [self setTextInputbarHidden:hide animated:YES];
    
    [buttonItem setImage:image];

}

- (void)fillWithText:(id)sender
{
    if (self.textView.text.length == 0)
    {
        int sentences = (arc4random() % 4);
        if (sentences <= 1) sentences = 1;
        self.textView.text = [LoremIpsum sentencesWithNumber:sentences];
    }
    else {
        [self.textView slk_insertTextAtCaretRange:[NSString stringWithFormat:@" %@", [LoremIpsum word]]];
    }
}

- (void)simulateUserTyping:(id)sender
{
    if ([self canShowTypingIndicator]) {
        
#if DEBUG_CUSTOM_TYPING_INDICATOR
        __block TypingIndicatorView *view = (TypingIndicatorView *)self.typingIndicatorProxyView;
        
        CGFloat scale = [UIScreen mainScreen].scale;
        CGSize imgSize = CGSizeMake(kTypingIndicatorViewAvatarHeight*scale, kTypingIndicatorViewAvatarHeight*scale);
        
        // This will cause the typing indicator to show after a delay ¯\_(ツ)_/¯
        [LoremIpsum asyncPlaceholderImageWithSize:imgSize
                                       completion:^(UIImage *image) {
                                           UIImage *thumbnail = [UIImage imageWithCGImage:image.CGImage scale:scale orientation:UIImageOrientationUp];
                                           [view presentIndicatorWithName:[LoremIpsum name] image:thumbnail];
                                       }];
#else
        [self.typingIndicatorView insertUsername:[LoremIpsum name]];
#endif
    }
}

- (void)togglePIPWindow:(id)sender
{
    if (!_pipWindow) {
        [self showPIPWindow:sender];
    }
    else {
        [self hidePIPWindow:sender];
    }
}

- (void)showPIPWindow:(id)sender
{
    CGRect frame = CGRectMake(CGRectGetWidth(self.view.frame) - 60.0, 0.0, 50.0, 50.0);
    frame.origin.y = CGRectGetMinY(self.textInputbar.frame) - 60.0;
    
    _pipWindow = [[UIWindow alloc] initWithFrame:frame];
    _pipWindow.backgroundColor = [UIColor blackColor];
    _pipWindow.layer.cornerRadius = 10.0;
    _pipWindow.layer.masksToBounds = YES;
    _pipWindow.hidden = NO;
    _pipWindow.alpha = 0.0;
    
    [[UIApplication sharedApplication].keyWindow addSubview:_pipWindow];
    
    [UIView animateWithDuration:0.25
                     animations:^{
                         _pipWindow.alpha = 1.0;
                     }];
}

- (void)hidePIPWindow:(id)sender
{
    [UIView animateWithDuration:0.3
                     animations:^{
                         _pipWindow.alpha = 0.0;
                     }
                     completion:^(BOOL finished) {
                         _pipWindow.hidden = YES;
                         _pipWindow = nil;
                     }];
}

- (void)textInputbarDidMove:(NSNotification *)note
{
    if (!_pipWindow) {
        return;
    }
    
    CGRect frame = self.pipWindow.frame;
    frame.origin.y = [note.userInfo[@"origin"] CGPointValue].y - 60.0;
    
    self.pipWindow.frame = frame;
}


#pragma mark - Overriden Methods

- (BOOL)ignoreTextInputbarAdjustment
{
    return [super ignoreTextInputbarAdjustment];
}

- (BOOL)forceTextInputbarAdjustmentForResponder:(UIResponder *)responder
{
    if ([responder isKindOfClass:[UIAlertController class]]) {
        return YES;
    }
    
    // On iOS 9, returning YES helps keeping the input view visible when the keyboard if presented from another app when using multi-tasking on iPad.
    return SLK_IS_IPAD;
}

- (void)didChangeKeyboardStatus:(SLKKeyboardStatus)status
{
    // Notifies the view controller that the keyboard changed status.
    
    switch (status) {
        case SLKKeyboardStatusWillShow:     return NSLog(@"Will Show");
        case SLKKeyboardStatusDidShow:      return NSLog(@"Did Show");
        case SLKKeyboardStatusWillHide:     return NSLog(@"Will Hide");
        case SLKKeyboardStatusDidHide:      return NSLog(@"Did Hide");
    }
}

- (void)textWillUpdate
{
    // Notifies the view controller that the text will update.
    
    [super textWillUpdate];
}

- (void)textDidUpdate:(BOOL)animated
{
    // Notifies the view controller that the text did update.
    
    [super textDidUpdate:animated];
}

- (void)didPressLeftButton:(id)sender
{
    // Notifies the view controller when the left button's action has been triggered, manually.
    
    [super didPressLeftButton:sender];
    
    UIViewController *vc = [UIViewController new];
    vc.view.backgroundColor = [UIColor whiteColor];
    vc.title = @"Details";
    
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)didPressRightButton:(id)sender
{
    // Notifies the view controller when the right button's action has been triggered, manually or by using the keyboard return key.
    
    // This little trick validates any pending auto-correction or auto-spelling just after hitting the 'Send' button
    [self.textView refreshFirstResponder];
	
	// Send message!
	NSString *text = [self.textView.text copy];
	NSLog(@"Send Message: %@", text);
	
    RgChatManager* mgr = [[LinphoneManager instance] chatManager];
	NSNumber *threadID = [[LinphoneManager instance] chatSession];
	NSDictionary *sdata = [mgr dbGetSessionData:threadID];
	NSString *origTo = NILIFNULL(sdata[@"session_to"]);
    NSString *uuid = [mgr sendMessageTo:sdata[@"session_tag"] from:origTo body:text contact:NILIFNULL(sdata[@"contact_id"])];
	NSLog(@"Sent Message UUID: %@", uuid);
	
	NSDictionary *dict = @{
        @"session":threadID
    };
    [[NSNotificationCenter defaultCenter] postNotificationName:kRgTextSent object:self userInfo:dict];

    [super didPressRightButton:sender];
}


- (NSString *)keyForTextCaching
{
    return [[NSBundle mainBundle] bundleIdentifier];
}

- (void)didPasteMediaContent:(NSDictionary *)userInfo
{
    // Notifies the view controller when the user has pasted a media (image, video, etc) inside of the text view.
    [super didPasteMediaContent:userInfo];
    
    SLKPastableMediaType mediaType = [userInfo[SLKTextViewPastedItemMediaType] integerValue];
    NSString *contentType = userInfo[SLKTextViewPastedItemContentType];
    id data = userInfo[SLKTextViewPastedItemData];
    
    NSLog(@"%s : %@ (type = %ld) | data : %@",__FUNCTION__, contentType, (unsigned long)mediaType, data);
}

- (void)willRequestUndo
{
    // Notifies the view controller when a user did shake the device to undo the typed text
    
    [super willRequestUndo];
}

- (void)didCommitTextEditing:(id)sender
{
    // Notifies the view controller when tapped on the right "Accept" button for commiting the edited text
    self.editingMessage.text = [self.textView.text copy];
    
    //[self.tableView reloadData];
    
    [super didCommitTextEditing:sender];
}

- (void)didCancelTextEditing:(id)sender
{
    // Notifies the view controller when tapped on the left "Cancel" button
    
    [super didCancelTextEditing:sender];
}

- (BOOL)canPressRightButton
{
    return [super canPressRightButton];
}

- (BOOL)canShowTypingIndicator
{
#if DEBUG_CUSTOM_TYPING_INDICATOR
    return YES;
#else
    return [super canShowTypingIndicator];
#endif
}

/*- (BOOL)shouldProcessTextForAutoCompletion:(NSString *)text
{
    return [super shouldProcessTextForAutoCompletion:text];
}*/

/*- (BOOL)shouldDisableTypingSuggestionForAutoCompletion
{
    return [super shouldDisableTypingSuggestionForAutoCompletion];
}*/
    
- (void)didChangeAutoCompletionPrefix:(NSString *)prefix andWord:(NSString *)word
{
    NSArray *array = nil;
    
    self.searchResult = nil;
    
    if ([prefix isEqualToString:@"@"]) {
        if (word.length > 0) {
            array = [self.users filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self BEGINSWITH[c] %@", word]];
        }
        else {
            array = self.users;
        }
    }
    else if ([prefix isEqualToString:@"#"] && word.length > 0) {
        array = [self.channels filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self BEGINSWITH[c] %@", word]];
    }
    else if (([prefix isEqualToString:@":"] || [prefix isEqualToString:@"+:"]) && word.length > 1) {
        array = [self.emojis filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self BEGINSWITH[c] %@", word]];
    }
    else if ([prefix isEqualToString:@"/"] && self.foundPrefixRange.location == 0) {
        if (word.length > 0) {
            array = [self.commands filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self BEGINSWITH[c] %@", word]];
        }
        else {
            array = self.commands;
        }
    }
    
    if (array.count > 0) {
        array = [array sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    }
    
    self.searchResult = [[NSMutableArray alloc] initWithArray:array];
    
    BOOL show = (self.searchResult.count > 0);
    
    [self showAutoCompletionView:show];
}

- (CGFloat)heightForAutoCompletionView
{
    CGFloat cellHeight = [self.autoCompletionView.delegate tableView:self.autoCompletionView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    return cellHeight*self.searchResult.count;
}


#pragma mark - SLKTextViewDelegate Methods

- (BOOL)textView:(SLKTextView *)textView shouldOfferFormattingForSymbol:(NSString *)symbol
{
    if ([symbol isEqualToString:@">"]) {
        
        NSRange selection = textView.selectedRange;
        
        // The Quote formatting only applies new paragraphs
        if (selection.location == 0 && selection.length > 0) {
            return YES;
        }
        
        // or older paragraphs too
        NSString *prevString = [textView.text substringWithRange:NSMakeRange(selection.location-1, 1)];
        
        if ([[NSCharacterSet newlineCharacterSet] characterIsMember:[prevString characterAtIndex:0]]) {
            return YES;
        }
        
        return NO;
    }
    
    return [super textView:textView shouldOfferFormattingForSymbol:symbol];
}

- (BOOL)textView:(SLKTextView *)textView shouldInsertSuffixForFormattingWithSymbol:(NSString *)symbol prefixRange:(NSRange)prefixRange
{
    if ([symbol isEqualToString:@">"]) {
        return NO;
    }
    
    return [super textView:textView shouldInsertSuffixForFormattingWithSymbol:symbol prefixRange:prefixRange];
}

#pragma mark - UITextViewDelegate Methods

- (BOOL)textView:(SLKTextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    return [super textView:textView shouldChangeTextInRange:range replacementText:text];
}

#pragma mark - UITableViewDataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.searchResult.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self autoCompletionCellForRowAtIndexPath:indexPath];
}

- (MessageTableViewCell *)autoCompletionCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MessageTableViewCell *cell = (MessageTableViewCell *)[self.autoCompletionView dequeueReusableCellWithIdentifier:AutoCompletionCellIdentifier];
    cell.indexPath = indexPath;
    
    NSString *text = self.searchResult[indexPath.row];
    
    if ([self.foundPrefix isEqualToString:@"#"]) {
        text = [NSString stringWithFormat:@"# %@", text];
    }
    else if (([self.foundPrefix isEqualToString:@":"] || [self.foundPrefix isEqualToString:@"+:"])) {
        text = [NSString stringWithFormat:@":%@:", text];
    }
    
    cell.titleLabel.text = text;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kMessageTableViewCellMinimumHeight;
}

#pragma mark - UITableViewDelegate Methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([tableView isEqual:self.autoCompletionView]) {
        
        NSMutableString *item = [self.searchResult[indexPath.row] mutableCopy];
        
        if ([self.foundPrefix isEqualToString:@"@"] && self.foundPrefixRange.location == 0) {
            [item appendString:@":"];
        }
        else if (([self.foundPrefix isEqualToString:@":"] || [self.foundPrefix isEqualToString:@"+:"])) {
            [item appendString:@":"];
        }
        
        [item appendString:@" "];
        
        [self acceptAutoCompletionWithString:item keepPrefix:YES];
    }
}


#pragma mark - UIScrollViewDelegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    // Since SLKTextViewController uses UIScrollViewDelegate to update a few things, it is important that if you override this method, to call super.
    [super scrollViewDidScroll:scrollView];
}



#pragma mark - Lifeterm

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
