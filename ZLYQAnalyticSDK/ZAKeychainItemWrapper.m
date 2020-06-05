//
//  ZAKeychainItemWrapper.m
//  ZADataAPI
//
//  Created by ZYM on 2020/5/14.
//

#import "ZAKeychainItemWrapper.h"
#import <Security/Security.h>

@interface ZAKeychainItemWrapper (PrivateMethods)

- (NSMutableDictionary *)secItemFormatToDictionary:(NSDictionary *)dictionaryToConvert;
- (NSMutableDictionary *)dictionaryToSecItemFormat:(NSDictionary *)dictionaryToConvert;

// Updates the item in the keychain, or adds it if it doesn't exist.
- (void)writeToKeychain;

@end

@implementation ZAKeychainItemWrapper

@synthesize keychainItemData, genericPasswordQuery;

- (id)initWithIdentifier: (NSString *)identifier accessGroup:(NSString *) accessGroup;
{
    if (self = [super init])
    {
        
        genericPasswordQuery = [[NSMutableDictionary alloc] init];
        
		[genericPasswordQuery setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
        _identifier = identifier;
        [genericPasswordQuery setObject:identifier forKey:(__bridge id)kSecAttrGeneric];
		
		if (accessGroup != nil)
		{
#if TARGET_IPHONE_SIMULATOR
            
#else			
			[genericPasswordQuery setObject:accessGroup forKey:(__bridge id)kSecAttrAccessGroup];
#endif
		}
		
		// Use the proper search constants, return only the attributes of the first match.
        [genericPasswordQuery setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
        [genericPasswordQuery setObject:(id)kCFBooleanTrue forKey:(__bridge id)kSecReturnAttributes];
        
        NSDictionary *tempQuery = [NSDictionary dictionaryWithDictionary:genericPasswordQuery];
        
        CFTypeRef cfDictionary = NULL;
        if (SecItemCopyMatching((__bridge CFDictionaryRef)tempQuery, &cfDictionary) != noErr)
        {
            // Stick these default values into keychain item if nothing found.
            [self resetKeychainItem];
			
			// Add the generic attribute and the keychain access group.
			[keychainItemData setObject:identifier forKey:(__bridge id)kSecAttrGeneric];
			if (accessGroup != nil)
			{
#if TARGET_IPHONE_SIMULATOR
                
#else			
				[keychainItemData setObject:accessGroup forKey:(__bridge id)kSecAttrAccessGroup];
#endif
			}
		}
        else
        {
            // load the saved data from Keychain.
            NSMutableDictionary *outDictionary = (__bridge_transfer NSMutableDictionary *)cfDictionary;
            self.keychainItemData = [self secItemFormatToDictionary:outDictionary];
        }
    }
    
	return self;
}


- (void)setObject:(id)inObject forKey:(id)key 
{
    if (inObject == nil) return;
    id currentObject = [keychainItemData objectForKey:key];
    if (![currentObject isEqual:inObject])
    {
        [keychainItemData setObject:inObject forKey:key];
        [self writeToKeychain];
    }
}

- (id)objectForKey:(id)key
{
    return [keychainItemData objectForKey:key];
}

- (void)resetKeychainItem
{
	OSStatus junk = noErr;
    if (!keychainItemData) 
    {
        self.keychainItemData = [[NSMutableDictionary alloc] init];
    }
    else if (keychainItemData)
    {
        NSMutableDictionary *tempDictionary = [self dictionaryToSecItemFormat:keychainItemData];
		junk = SecItemDelete((__bridge CFDictionaryRef)tempDictionary);
        NSAssert( junk == noErr || junk == errSecItemNotFound, @"Problem deleting current dictionary." );
    }
    
    // Default attributes for keychain item.
    [keychainItemData setObject:@"" forKey:(__bridge id)kSecAttrAccount];
    [keychainItemData setObject:@"" forKey:(__bridge id)kSecAttrService];
    [keychainItemData setObject:@"" forKey:(__bridge id)kSecAttrLabel];
    [keychainItemData setObject:@"" forKey:(__bridge id)kSecAttrDescription];
    
	// Default data for keychain item.
    [keychainItemData setObject:[NSDictionary dictionary] forKey:(__bridge id)kSecValueData];
}

- (NSMutableDictionary *)dictionaryToSecItemFormat:(NSDictionary *)dictionaryToConvert
{
    
    
    NSMutableDictionary * returnDict = [NSMutableDictionary dictionaryWithDictionary:dictionaryToConvert];
	//[returnDict setObject:_identifier forKey:(id)kSecAttrGeneric];
	[returnDict setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
	
	// convert the dictionary to an info list for serialization
	// could contain multiple result sets to be handled
	NSDictionary * resultsInfo = [dictionaryToConvert objectForKey:(__bridge id)kSecValueData];
	
	NSString * error;
	NSData * xmlData = [NSPropertyListSerialization dataFromPropertyList:resultsInfo 
                                                                  format:NSPropertyListXMLFormat_v1_0 
                                                        errorDescription:&error];
	
	if (error != nil) 
    { 
		NSLog(@"dictionaryToSecItemFormat: Error! %@", error);
	}
	
    if (xmlData)
        [returnDict setObject:xmlData forKey:(__bridge id)kSecValueData];
	
	return returnDict;
}

- (NSMutableDictionary *)secItemFormatToDictionary:(NSDictionary *)dictionaryToConvert
{
    
    NSMutableDictionary * returnDict = [NSMutableDictionary dictionaryWithDictionary:dictionaryToConvert];
	
	// to get the password data from the keychain item, add the search key and class attr required to obtain the password
	[returnDict setObject:(id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
	[returnDict setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
	
	// call the keychain services to get the password
	OSStatus keychainErr = noErr;
	
    CFTypeRef cfXmlData = NULL;
	keychainErr = SecItemCopyMatching((__bridge CFDictionaryRef)returnDict, &cfXmlData);
	
	if (keychainErr == noErr)
    { 
		NSData * xmlData = (__bridge_transfer NSData *) cfXmlData;
		[returnDict removeObjectForKey:(__bridge id)kSecReturnData];
		
		NSString * errorDesc = nil;
		NSPropertyListFormat fmt;
		NSDictionary * resultsInfo = (NSDictionary *) [NSPropertyListSerialization propertyListFromData:xmlData
                                                                                       mutabilityOption:NSPropertyListMutableContainersAndLeaves
                                                                                                 format:&fmt
                                                                                       errorDescription: &errorDesc];
		
        if (resultsInfo)
            [returnDict setObject:resultsInfo forKey:(__bridge id)kSecValueData];
		
	} else { 
		NSLog(@"secItemFormatToDictionary: format error.");
	}
	
	return returnDict;
}

- (void)writeToKeychain
{
	OSStatus result; 
    CFTypeRef cfAttributes = NULL;
    if (SecItemCopyMatching((__bridge CFDictionaryRef)genericPasswordQuery, &cfAttributes) == noErr)
    {
        NSDictionary *attributes = (__bridge_transfer NSDictionary *) cfAttributes;
        
        // First we need the attributes from the Keychain.
        NSMutableDictionary *updateItem = [NSMutableDictionary dictionaryWithDictionary:attributes];
        // Second we need to add the appropriate search key/values. 
        [updateItem setObject:[genericPasswordQuery objectForKey:(__bridge id)kSecClass] forKey:(__bridge id)kSecClass];
        
        // Lastly, we need to set up the updated attribute list being careful to remove the class.
        NSMutableDictionary *tempCheck = [self dictionaryToSecItemFormat:keychainItemData];
        [tempCheck removeObjectForKey:(__bridge id)kSecClass];
		
#if TARGET_IPHONE_SIMULATOR
		[tempCheck removeObjectForKey:(__bridge id)kSecAttrAccessGroup];
#endif
        
        // An implicit assumption is that you can only update a single item at a time.
		
        result = SecItemUpdate((__bridge CFDictionaryRef)updateItem, (__bridge CFDictionaryRef)tempCheck);
		NSAssert( result == noErr || result == errSecDuplicateItem, @"Couldn't update the Keychain Item." );
    }
    else
    {
        
        result = SecItemAdd((__bridge CFDictionaryRef)[self dictionaryToSecItemFormat:keychainItemData], NULL);
		NSAssert( result == noErr || result == errSecDuplicateItem, @"Couldn't add the Keychain Item." );
    }
}

@end
