//
//  IntentHandler.m
//  RingMailIntentsExtension
//
//  Created by Mark Baxter on 10/6/16.
//
//

#import "IntentHandler.h"

// As an example, this class is set up to handle Message intents.
// You will want to replace this or add other intents as appropriate.
// The intents you wish to handle must be declared in the extension's Info.plist.

// You can test your example integration by saying things to Siri like:
// "Send a message using <myApp>"
// "<myApp> John saying hello"
// "Search for messages in <myApp>"

@interface IntentHandler () <INStartAudioCallIntentHandling, INSendMessageIntentHandling, INSearchForMessagesIntentHandling, INSetMessageAttributeIntentHandling>

@end

@implementation IntentHandler


- (id)handlerForIntent:(INIntent *)intent {
    
    return self;
}

#pragma mark - INSendMessageIntentHandling

- (void)resolveRecipientsForSendMessage:(INSendMessageIntent *)intent withCompletion:(void (^)(NSArray<INPersonResolutionResult *> *resolutionResults))completion {
    NSArray<INPerson *> *recipients = intent.recipients;

    if (recipients.count == 0) {
        completion(@[[INPersonResolutionResult needsValue]]);
        return;
    }
    NSMutableArray<INPersonResolutionResult *> *resolutionResults = [NSMutableArray array];
    
    for (INPerson *recipient in recipients) {
        
        IntentContactManager *contactManager = [[IntentContactManager alloc] init];
        
        if ([contactManager findContact:recipient])
            NSLog(@"Found Recepient Name:  %@",recipient.displayName);

        NSArray<INPerson *> *matchingContacts = @[recipient];
        
        if (matchingContacts.count > 1)
            [resolutionResults addObject:[INPersonResolutionResult disambiguationWithPeopleToDisambiguate:matchingContacts]];
        else if (matchingContacts.count == 1)
            [resolutionResults addObject:[INPersonResolutionResult successWithResolvedPerson:recipient]];
        else
            [resolutionResults addObject:[INPersonResolutionResult unsupported]];
        
    }
    completion(resolutionResults);
}

- (void)resolveContentForSendMessage:(INSendMessageIntent *)intent withCompletion:(void (^)(INStringResolutionResult *resolutionResult))completion {
    NSString *text = intent.content;
    if (text && ![text isEqualToString:@""]) {
        completion([INStringResolutionResult successWithResolvedString:text]);
    } else {
        completion([INStringResolutionResult needsValue]);
    }
}

- (void)confirmSendMessage:(INSendMessageIntent *)intent completion:(void (^)(INSendMessageIntentResponse *response))completion {
    
    NSUserActivity *userActivity = [[NSUserActivity alloc] initWithActivityType:NSStringFromClass([INSendMessageIntent class])];
    INSendMessageIntentResponse *response = [[INSendMessageIntentResponse alloc] initWithCode:INSendMessageIntentResponseCodeReady userActivity:userActivity];
    completion(response);
}

- (void)handleSendMessage:(INSendMessageIntent *)intent completion:(void (^)(INSendMessageIntentResponse *response))completion {
    
    NSString *activityType = @"com.ringmail.phone-dev.handlemsg";
    NSUserActivity *activity = [[NSUserActivity alloc] initWithActivityType:activityType];
    activity.title = @"title";
    activity.userInfo = @{@"location": @"TEST"};
    activity.eligibleForSearch = YES;
    activity.eligibleForPublicIndexing = YES;
    INSendMessageIntentResponse *response = [[INSendMessageIntentResponse alloc] initWithCode:INSendMessageIntentResponseCodeInProgress userActivity:activity];
    completion(response);
}


- (void)handleSearchForMessages:(INSearchForMessagesIntent *)intent completion:(void (^)(INSearchForMessagesIntentResponse *response))completion {
    
    NSUserActivity *userActivity = [[NSUserActivity alloc] initWithActivityType:NSStringFromClass([INSearchForMessagesIntent class])];
    INSearchForMessagesIntentResponse *response = [[INSearchForMessagesIntentResponse alloc] initWithCode:INSearchForMessagesIntentResponseCodeSuccess userActivity:userActivity];
    response.messages = @[[[INMessage alloc]
                           initWithIdentifier:@"identifier"
                           content:@"I am so excited about SiriKit!"
                           dateSent:[NSDate date]
                           sender:[[INPerson alloc] initWithPersonHandle:[[INPersonHandle alloc] initWithValue:@"sarah@example.com" type:INPersonHandleTypeEmailAddress] nameComponents:nil displayName:@"Sarah" image:nil contactIdentifier:nil customIdentifier:nil]
                           recipients:@[[[INPerson alloc] initWithPersonHandle:[[INPersonHandle alloc] initWithValue:@"+1-415-555-5555" type:INPersonHandleTypePhoneNumber] nameComponents:nil displayName:@"John" image:nil contactIdentifier:nil customIdentifier:nil]]
                           ]];
    completion(response);
}

- (void)handleSetMessageAttribute:(INSetMessageAttributeIntent *)intent completion:(void (^)(INSetMessageAttributeIntentResponse *response))completion {
    NSUserActivity *userActivity = [[NSUserActivity alloc] initWithActivityType:NSStringFromClass([INSetMessageAttributeIntent class])];
    INSetMessageAttributeIntentResponse *response = [[INSetMessageAttributeIntentResponse alloc] initWithCode:INSetMessageAttributeIntentResponseCodeSuccess userActivity:userActivity];
    completion(response);
}


#pragma mark - Audio Call

- (void)resolveContactsForStartAudioCall:(INStartAudioCallIntent *)intent withCompletion:(void (^)(NSArray<INPersonResolutionResult *> *resolutionResults))completion{
    
    NSMutableArray *resolutionResults = [NSMutableArray array];
    NSArray *recipients = intent.contacts;
    
    IntentContactManager *contactManager = [[IntentContactManager alloc] init];
    
    for (INPerson *recipient in recipients) {
        if ([contactManager findContact:recipient]) {
            if (contactManager->foundContacts.count == 1) {
                
                CNContact *recContact = contactManager->foundContacts[0];
                NSString *recpEmail;
                
                for (CNLabeledValue *label in recContact.emailAddresses) {
                    if ([label.value length] > 0)
                        recpEmail = [label.value copy];
                }
                
                INPerson *confirmedRecipient = [[INPerson alloc] initWithPersonHandle:[[INPersonHandle alloc] initWithValue:recpEmail type:INPersonHandleTypeEmailAddress]  nameComponents:nil displayName:recContact.givenName image:nil contactIdentifier:nil customIdentifier:nil];
    
                [resolutionResults addObject:[INPersonResolutionResult successWithResolvedPerson:confirmedRecipient]];
            }
            else if (contactManager->foundContacts.count > 1) {
                NSArray<INPerson *> *matchingContacts = @[recipient];
                [resolutionResults addObject:[INPersonResolutionResult disambiguationWithPeopleToDisambiguate:matchingContacts]];
            }
        }
        else
            [resolutionResults addObject:[INPersonResolutionResult unsupported]];
    }
    
    completion(resolutionResults);
}

- (void)confirmStartAudioCall:(INStartAudioCallIntent *)intent completion:(void (^)(INStartAudioCallIntentResponse *response))completion{
    
    NSUserActivity *userActivity = [[NSUserActivity alloc] initWithActivityType:NSStringFromClass([INStartAudioCallIntent class])];
    INStartAudioCallIntentResponse *response = [[INStartAudioCallIntentResponse alloc] initWithCode:INStartAudioCallIntentResponseCodeReady userActivity:userActivity];
    
    completion(response);
}

- (void)handleStartAudioCall:(INStartAudioCallIntent *)intent completion:(void (^)(INStartAudioCallIntentResponse *response))completion{

    NSString *activityType = @"com.ringmail.phone-dev.handlecall";
    NSUserActivity *activity = [[NSUserActivity alloc] initWithActivityType:activityType];
    
    INPerson *recipient = intent.contacts[0];
    NSString *callAddress = recipient.personHandle.value;

    NSMutableDictionary *mutableDict = [[NSMutableDictionary alloc] init];
    [mutableDict setObject:callAddress forKey:@"callAddress"];
    NSDictionary *dict = [mutableDict copy];

    activity.userInfo = dict;

    INStartAudioCallIntentResponse *response = [[INStartAudioCallIntentResponse alloc] initWithCode:INStartAudioCallIntentResponseCodeContinueInApp userActivity:activity];
    completion(response);
}

@end
