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
    
//    NSLog(@"{ intent: %@, identifier: %@, recipients: %@, groupName: %@, content: %@, serviceName: %@, description: %@ }",intent, intent.identifier, intent.recipients, intent.groupName, intent.content, intent.serviceName, intent.description);

//  "RingMail-Dev send message to Mike"

//    { intent: <INSendMessageIntent: 0x100215fc0>, identifier: 8faea7f3f7d76459de922887eb9460cc095850f1, recipients: ("<INPerson: 0x10035e7a0>"), groupName: (null), content: Testing, serviceName: (null), description: <INSendMessageIntent: 0x100215fc0> }

//  "RingMail-Dev send message to #dyl"

//    { intent: <INSendMessageIntent: 0x1002174d0>, identifier: e770483215b9454f4c09801220cdc44cc0c5990c, recipients: ("<INPerson: 0x100226670>"), groupName: (null), content: (null),serviceName: (null), description: <INSendMessageIntent: 0x1002174d0> }
    
    NSArray<INPerson *> *recipients = intent.recipients;

    if (recipients.count == 0) {
        completion(@[[INPersonResolutionResult needsValue]]);
        return;
    }
    NSMutableArray<INPersonResolutionResult *> *resolutionResults = [NSMutableArray array];
    
    for (INPerson *recipient in recipients) {
        
//        NSLog(@"{ recipient.identifier: %@, recipient.spokenPhrase: %@, recipient.pronunciationHint: %@, recipient.personHandle.value: %@, recipient.personHandle.type: %ld, recipient.aliases: %@, recipient.description: %@, recipient.displayName: %@, recipient.contactIdentifier: %@, recipient.customIdentifier: %@, recipient.nameComponents.givenName: %@, recipient.nameComponents.familyName: %@, recipient.nameComponents.nickname: %@, recipient.image: %@ }", recipient.identifier, recipient.spokenPhrase, recipient.pronunciationHint, recipient.personHandle.value, (long)recipient.personHandle.type, recipient.aliases, recipient.description, recipient.displayName, recipient.contactIdentifier, recipient.customIdentifier, recipient.nameComponents.givenName, recipient.nameComponents.familyName, recipient.nameComponents.nickname, recipient.image);

//  "RingMail-Dev send message to Mike"
        
//    { recipient.identifier: (null), recipient.spokenPhrase: Mike, recipient.pronunciationHint: Mike, recipient.personHandle.value: (null), recipient.personHandle.type: 0, recipient.aliases: (null), recipient.description: <INPerson: 0x10035e7a0>, recipient.displayName: Mike Frager, recipient.contactIdentifier: (null), recipient.customIdentifier: (null), recipient.nameComponents.givenName: Mike, recipient.nameComponents.familyName: Frager, recipient.nameComponents.nickname: (null), recipient.image: (null) }
        
//  "RingMail-Dev send message to #dyl"
        
//        { recipient.identifier: (null), recipient.spokenPhrase: #TheWild, recipient.pronunciationHint: #TheWild, recipient.personHandle.value: (null), recipient.personHandle.type: 0, recipient.aliases: (null), recipient.description: <INPerson: 0x100226670>, recipient.displayName: #TheWild, recipient.contactIdentifier: (null), recipient.customIdentifier: (null), recipient.nameComponents.givenName: (null), recipient.nameComponents.familyName: (null), recipient.nameComponents.nickname: (null), recipient.image: (null) }
        
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
    
    if (recipients.count > 1) {
         for (INPerson *recipient in recipients)
             [resolutionResults addObject:[INPersonResolutionResult disambiguationWithPeopleToDisambiguate:recipients]];
    }
    else if (recipients.count == 1)
    {
        IntentContactManager *contactManager = [[IntentContactManager alloc] init];
        
        if ([contactManager findABContactID:recipients[0]]) {
            if (contactManager->foundContactsID.count == 1) {
                
                NSString *contactID = contactID = contactManager->foundContactsID[0];

                INPerson *confirmedRecipient = [[INPerson alloc] initWithPersonHandle:[[INPersonHandle alloc] initWithValue:contactID type:INPersonHandleTypeEmailAddress] nameComponents:nil displayName:contactID image:nil contactIdentifier:contactID customIdentifier:contactID];

                [resolutionResults addObject:[INPersonResolutionResult successWithResolvedPerson:confirmedRecipient]];

            }
            else if (contactManager->foundContactsID.count > 1)
                 [resolutionResults addObject:[INPersonResolutionResult unsupported]];
        }
    }
    else
        [resolutionResults addObject:[INPersonResolutionResult unsupported]];

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
    NSString *callContactID = recipient.personHandle.value;

    NSMutableDictionary *mutableDict = [[NSMutableDictionary alloc] init];
    [mutableDict setObject:callContactID forKey:@"callContactID"];
    NSDictionary *dict = [mutableDict copy];

    activity.userInfo = dict;

    INStartAudioCallIntentResponse *response = [[INStartAudioCallIntentResponse alloc] initWithCode:INStartAudioCallIntentResponseCodeContinueInApp userActivity:activity];
    completion(response);
}

@end
