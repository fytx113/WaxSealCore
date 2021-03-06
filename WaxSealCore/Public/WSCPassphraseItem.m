/*=============================================================================┐
|             _  _  _       _                                                  |  
|            (_)(_)(_)     | |                            _                    |██
|             _  _  _ _____| | ____ ___  ____  _____    _| |_ ___              |██
|            | || || | ___ | |/ ___) _ \|    \| ___ |  (_   _) _ \             |██
|            | || || | ____| ( (__| |_| | | | | ____|    | || |_| |            |██
|             \_____/|_____)\_)____)___/|_|_|_|_____)     \__)___/             |██
|                                                                              |██
|     _  _  _              ______             _ _______                  _     |██
|    (_)(_)(_)            / _____)           | (_______)                | |    |██
|     _  _  _ _____ _   _( (____  _____ _____| |_       ___   ____ _____| |    |██
|    | || || (____ ( \ / )\____ \| ___ (____ | | |     / _ \ / ___) ___ |_|    |██
|    | || || / ___ |) X ( _____) ) ____/ ___ | | |____| |_| | |   | ____|_     |██
|     \_____/\_____(_/ \_|______/|_____)_____|\_)______)___/|_|   |_____)_|    |██
|                                                                              |██
|                                                                              |██
|                         Copyright (c) 2015 Tong Guo                          |██
|                                                                              |██
|                             ALL RIGHTS RESERVED.                             |██
|                                                                              |██
└==============================================================================┘██
  ████████████████████████████████████████████████████████████████████████████████
  ██████████████████████████████████████████████████████████████████████████████*/

#import "WSCPassphraseItem.h"
#import "WSCKeychainError.h"

#import "_WSCKeychainErrorPrivate.h"
#import "_WSCKeychainItemPrivate.h"
#import "_WSCPassphraseItemPrivate.h"
#import "_WSCPassphraseItemPrivate.h"

@implementation WSCPassphraseItem

@dynamic account;
@dynamic comment;
@dynamic kindDescription;
@dynamic passphrase;
@dynamic isInvisible;
@dynamic isNegative;

@dynamic URL;
@dynamic hostName;
@dynamic relativePath;
@dynamic authenticationType;
@dynamic protocol;
@dynamic port;

@dynamic serviceName;
@dynamic userDefinedData;

/* The `NSString` object that identifies the account of keychain item represented by receiver. */
- ( NSString* ) account
    {
    return [ self p_extractAttributeWithCheckingParameter: kSecAccountItemAttr ];
    }

- ( void ) setAccount: ( NSString* )_Account
    {
    [ self p_modifyAttribute: kSecAccountItemAttr withNewValue: _Account ];
    }

/* The `NSString` object that identifies the comment of keychain item represented by receiver. */
- ( NSString* ) comment
    {
    return [ self p_extractAttributeWithCheckingParameter: kSecCommentItemAttr ];
    }

- ( void ) setComment: ( NSString* )_Comment
    {
    [ self p_modifyAttribute: kSecCommentItemAttr withNewValue: _Comment ];
    }

/* The `NSString` object that identifies the kind description of keychain item represented by receiver. */
- ( NSString* ) kindDescription
    {
    return [ self p_extractAttributeWithCheckingParameter: kSecDescriptionItemAttr ];
    }

- ( void ) setKindDescription:( NSString* )_KindDescription
    {
    [ self p_modifyAttribute: kSecDescriptionItemAttr withNewValue: _KindDescription ];
    }

/* The `NSData` object that contains the passphrase data of the keychain item represented by receiver.
 */
- ( NSData* ) passphrase
    {
    NSError* error = nil;
    OSStatus resultCode = errSecSuccess;

    // The receiver must not be invalid.
    _WSCDontBeABitch( &error, self, [ WSCPassphraseItem class ], s_guard );

    NSData* passphraseData = nil;
    if ( !error )
        {
        UInt32 lengthOfSecretData = 0;
        void* secretData = NULL;

        // Get the secret data
        resultCode = SecKeychainItemCopyAttributesAndData( self.secKeychainItem, NULL, NULL, NULL
                                                         , &lengthOfSecretData, &secretData );
        if ( resultCode == errSecSuccess )
            {
            passphraseData = [ NSData dataWithBytes: secretData length: lengthOfSecretData ];
            SecKeychainItemFreeAttributesAndData( NULL, secretData );
            }
        else
            {
            NSError* underlyingError = [ NSError errorWithDomain: NSOSStatusErrorDomain code: resultCode userInfo: nil ];
            error = [ NSError errorWithDomain: WaxSealCoreErrorDomain
                                         code: WSCKeychainItemPermissionDeniedError
                                     userInfo: @{ NSUnderlyingErrorKey : underlyingError } ];
            }
        }
    else
        error = [ NSError errorWithDomain: WaxSealCoreErrorDomain
                                     code: WSCKeychainItemIsInvalidError
                                 userInfo: nil ];

    if ( error )
        _WSCPrintNSErrorForLog( error );

    return passphraseData;
    }

- ( void ) setPassphrase: ( NSData* )_Passphrase
    {
    NSError* error = nil;
    OSStatus resultCode = errSecSuccess;

    // The receiver must not be invalid.
    _WSCDontBeABitch( &error
                    , self, [ WSCPassphraseItem class ]
                    , _Passphrase, [ NSData class ]
                    , s_guard
                    );
    if ( !error )
        {
        // Modify the passphrase of the passphrase item represeted by receiver.
        resultCode = SecKeychainItemModifyAttributesAndData( self.secKeychainItem, NULL
                                                           , ( UInt32 )_Passphrase.length, _Passphrase.bytes );
        if ( resultCode != errSecSuccess )
            error = [ NSError errorWithDomain: NSOSStatusErrorDomain code: resultCode userInfo: nil ];
        }
    else
        error = [ NSError errorWithDomain: WaxSealCoreErrorDomain
                                     code: WSCKeychainItemIsInvalidError
                                 userInfo: nil ];
    }

/* `BOOL` value that indivates whether this passphrase item is invisible (that is, should not be displayed).
 */
- ( BOOL ) isInvisible
    {
    return ( BOOL )[ self p_extractAttributeWithCheckingParameter: kSecInvisibleItemAttr ];
    }

- ( void ) setInvisible: ( BOOL )_IsInvisible
    {
    [ self p_modifyAttribute: kSecInvisibleItemAttr withNewValue: ( id )_IsInvisible ];
    }

/* `BOOL` value that indicates whether there is a valid password associated with this passphrase item.
 */
- ( BOOL ) isNegative
    {
    return ( BOOL )[ self p_extractAttributeWithCheckingParameter: kSecNegativeItemAttr ];
    }

- ( void ) setNegative: ( BOOL )_IsNegative
    {
    [ self p_modifyAttribute: kSecNegativeItemAttr withNewValue: ( id )_IsNegative ];
    }

/* The URL for the an Internet passphrase represented by receiver. */
- ( NSURL* ) URL
    {
    // The `URL` property is unique to the Internet passphrase item
    // So the receiver must be an Internet passphrase item.
    if ( [ self p_itemClass: nil ] != WSCKeychainItemClassInternetPassphraseItem )
        {
        NSError* error = [ NSError errorWithDomain: WaxSealCoreErrorDomain
                                              code: WSCKeychainItemAttributeIsUniqueToInternetPassphraseError
                                          userInfo: nil ];
        _WSCPrintNSErrorForLog( error );
        return nil;
        }

    NSMutableString* hostName = [ [ [ self p_extractAttributeWithCheckingParameter: kSecServerItemAttr ] mutableCopy ] autorelease ];
    NSMutableString* relativePath = [ [ [ self p_extractAttributeWithCheckingParameter: kSecPathItemAttr ] mutableCopy ] autorelease ];
    NSUInteger port = ( NSUInteger )[ self p_extractAttributeWithCheckingParameter: kSecPortItemAttr ];
    WSCInternetProtocolType protocol = ( WSCInternetProtocolType )[ self p_extractAttributeWithCheckingParameter: kSecProtocolItemAttr ];

    if ( port != 0 )
        [ hostName appendString: [ NSString stringWithFormat: @":%lu", port ] ];

    if ( ![ relativePath hasPrefix: @"/" ] /* For instance, "member/NSTongG" */ )
        // Intert a forwar slash, got the "/member/NSTongG"
        [ relativePath insertString: @"/" atIndex: 0 ];

    NSURL* absoluteURL = [ [ [ NSURL alloc ] initWithScheme: _WSCSchemeStringForProtocol( protocol )
                                                       host: hostName
                                                       path: relativePath ] autorelease ];
    return absoluteURL;
    }

/* The `NSString` object that identifies the Internet server’s domain name or IP address of keychain item represented by receiver.
 */
- ( NSString* ) hostName
    {
    return [ self p_extractAttributeWithCheckingParameter: kSecServerItemAttr ];
    }

- ( void ) setHostName: ( NSString* )_ServerName
    {
    [ self p_modifyAttribute: kSecServerItemAttr withNewValue: _ServerName ];
    }

/* The `NSString` object that identifies the path of a URL conforming to RFC 1808 
 * of an Internet passphrase item represented by receiver.
 */
- ( NSString* ) relativePath
    {
    return [ self p_extractAttributeWithCheckingParameter: kSecPathItemAttr ];
    }

- ( void ) setRelativePath: ( NSString* )_RelativeURLPath
    {
    [ self p_modifyAttribute: kSecPathItemAttr withNewValue: _RelativeURLPath ];
    }

/* The value of type WSCInternetAuthenticationType that identifies the authentication type of an internet passphrase item represented by receiver.
 */
- ( WSCInternetAuthenticationType ) authenticationType
    {
    return ( WSCInternetAuthenticationType )[ self p_extractAttributeWithCheckingParameter: kSecAuthenticationTypeItemAttr ];
    }

- ( void ) setAuthenticationType: ( WSCInternetAuthenticationType )_AuthType
    {
    [ self p_modifyAttribute: kSecAuthenticationTypeItemAttr withNewValue: ( id )_AuthType ];
    }

/* The value of type WSCInternetProtocolType that identifies the Internet protocol of an internet passphrase item represented by receiver.
 */
- ( WSCInternetProtocolType ) protocol
    {
    return ( WSCInternetProtocolType )[ self p_extractAttributeWithCheckingParameter: kSecProtocolItemAttr ];
    }

- ( void ) setProtocol: ( WSCInternetProtocolType )_Protocol
    {
    [ self p_modifyAttribute: kSecProtocolItemAttr withNewValue: ( id )_Protocol ];
    }

/* The value that identifies the Internet port of an internet passphrase item represented by receiver.
 */
- ( NSUInteger ) port
    {
    return ( NSUInteger )[ self p_extractAttributeWithCheckingParameter: kSecPortItemAttr ];
    }

- ( void ) setPort: ( NSUInteger )_PortNumber
    {
    [ self p_modifyAttribute: kSecPortItemAttr withNewValue: ( id )_PortNumber ];
    }

/* The `NSString` object that identifies the service name of an application passphrase item represented by receiver. 
 */
- ( NSString* ) serviceName
    {
    return [ self p_extractAttributeWithCheckingParameter: kSecServiceItemAttr ];
    }

- ( void ) setServiceName: ( NSString* )_ServiceName
    {
    [ self p_modifyAttribute: kSecServiceItemAttr withNewValue: _ServiceName ];
    }

/* The `NSData` object that contains a user-defined attribute.
 */
- ( NSData* ) userDefinedData
    {
    return [ self p_extractAttributeWithCheckingParameter: kSecGenericItemAttr ];
    }

- ( void ) setUserDefinedData: ( NSData* )_NewData
    {
    [ self p_modifyAttribute: kSecGenericItemAttr withNewValue: _NewData ];
    }

#pragma mark Overrides
/* Overrides the implementation in WSCKeychainItem class.
 * `BOOL` value that indicates whether the receiver is currently valid. (read-only)
 */
- ( BOOL ) isValid
    {
    NSError* error = nil;
    BOOL isReceiverValid = NO;

    if ( [ super isValid ] )
        {
        NSDictionary* searchCriteriaDict = nil;
        WSCKeychainItemClass classOfReceiver = [ self p_itemClass: nil ];

        // Get the search criteria for the Internet or application passphrase item.
        // we need only one keychain item satisfying the given search criteria
        // to proof the keychain item represented by receiver is still valid.
        if ( classOfReceiver == WSCKeychainItemClassInternetPassphraseItem )
            searchCriteriaDict = [ self p_wrapInternetPasswordItemSearchCriteria ];

        else if ( classOfReceiver == WSCKeychainItemClassApplicationPassphraseItem )
            searchCriteriaDict = [ self p_wrapApplicationPasswordItemSearchCriteria ];

        // If there is not any search criteria,
        // we can consider that the keychain item represented by receiver is already invalid,
        // we should skip the searching;
        // otherwise, begin to search.
        if ( searchCriteriaDict.count != 0 )
            isReceiverValid = [ [ self p_keychainWithoutCheckingValidity: &error ]
                findFirstKeychainItemSatisfyingSearchCriteria: searchCriteriaDict
                                                    itemClass: [ self p_itemClass: nil ]
                                                        error: &error ]  ? YES : NO;
        }

    if ( error )
        _WSCPrintNSErrorForLog( error );

    return isReceiverValid;
    }

@end // WSCPassphraseItem class

#pragma mark WSCPassphraseItem + WSCPasswordPrivateUtilities
@implementation WSCPassphraseItem ( WSCPasswordPrivateUtilities )

NSArray static* s_generalPassphraseItemSearchKeys;
NSArray static* s_applicationPassphraseItemSearchKeys;
NSArray static* s_internetPassphraseItemSearchKeys;

+ ( NSArray* ) p_generalPassphraseItemSearchKeys
    {
    dispatch_once_t static onceToken;

    dispatch_once( &onceToken
                 , ( dispatch_block_t )^( void )
                    {
                    s_generalPassphraseItemSearchKeys =
                        [ [ @[ WSCKeychainItemAttributeCreationDate
                             , WSCKeychainItemAttributeModificationDate
                             , WSCKeychainItemAttributeAccount
                             , WSCKeychainItemAttributeComment
                             , WSCKeychainItemAttributeKindDescription
                             , WSCKeychainItemAttributeNegative
                             , WSCKeychainItemAttributeInvisible
                             ] arrayByAddingObjectsFromArray: [ WSCKeychainItem p_generalSearchKeys ] ] retain ];
                    } );

    return s_generalPassphraseItemSearchKeys;
    }

+ ( NSArray* ) p_applicationPassphraseSearchKeys
    {
    dispatch_once_t static onceToken;

    dispatch_once( &onceToken
                 , ( dispatch_block_t )^( void )
                    {
                    s_applicationPassphraseItemSearchKeys =
                        [ [ @[ WSCKeychainItemAttributeServiceName
                             , WSCKeychainItemAttributeUserDefinedDataAttribute
                             ] arrayByAddingObjectsFromArray: [ WSCPassphraseItem p_generalPassphraseItemSearchKeys ] ] retain ];
                    } );

    return s_applicationPassphraseItemSearchKeys;
    }

+ ( NSArray* ) p_internetPassphraseSearchKeys
    {
    dispatch_once_t static onceToken;

    dispatch_once( &onceToken
                 , ( dispatch_block_t )^( void )
                    {
                    s_internetPassphraseItemSearchKeys =
                        [ [ @[ WSCKeychainItemAttributeHostName
                             , WSCKeychainItemAttributeAuthenticationType
                             , WSCKeychainItemAttributePort
                             , WSCKeychainItemAttributeRelativePath
                             , WSCKeychainItemAttributeProtocol
                             ] arrayByAddingObjectsFromArray: [ WSCPassphraseItem p_generalPassphraseItemSearchKeys ] ] retain ];
                    } );

    return s_internetPassphraseItemSearchKeys;
    }

- ( void ) p_addSearchCriteriaWithCStringData: ( NSMutableDictionary* )_SearchCriteriaDict
                                     itemAttr: ( SecItemAttr )_ItemAttr
    {
    NSString* cocoaStringData = ( NSString* )[ self p_extractAttribute: _ItemAttr error: nil ];

    if ( cocoaStringData && cocoaStringData.length )
        _SearchCriteriaDict[ _WSCStringFromFourCharCode( _ItemAttr ) ] = cocoaStringData;
    }

- ( void ) p_addSearchCriteriaWithUInt32Data: ( NSMutableDictionary* )_SearchCriteriaDict
                                    itemAttr: ( SecItemAttr )_ItemAttr
    {
    UInt32 UInt32Data = ( UInt32 )[ self p_extractAttribute: _ItemAttr error: nil ];

    if ( UInt32Data != 0 )
        {
        NSNumber* cocoaUInt32Data = @( UInt32Data );
        _SearchCriteriaDict[ _WSCStringFromFourCharCode( _ItemAttr ) ] = cocoaUInt32Data;
        }
    }

- ( void ) p_addSearchCriteriaWithFourCharCodeData: ( NSMutableDictionary* )_SearchCriteriaDict
                                          itemAttr: ( SecItemAttr )_ItemAttr
    {
    FourCharCode fourCharCodeData = ( FourCharCode )[ self p_extractAttribute: _ItemAttr error: nil ];

    if ( fourCharCodeData != '\0\0\0\0' )
        {
        NSValue* cocoaValueData = WSCFourCharCodeValue( fourCharCodeData );
        _SearchCriteriaDict[ _WSCStringFromFourCharCode( _ItemAttr ) ] = cocoaValueData;
        }
    }

- ( NSMutableDictionary* ) p_wrapCommonPasswordItemSearchCriteria
    {
    NSMutableDictionary* searchCriteriaDict = [ NSMutableDictionary dictionaryWithCapacity: 3 ];

    [ self p_addSearchCriteriaWithCStringData: searchCriteriaDict itemAttr: kSecLabelItemAttr ];
    [ self p_addSearchCriteriaWithCStringData: searchCriteriaDict itemAttr: kSecAccountItemAttr ];
    [ self p_addSearchCriteriaWithCStringData: searchCriteriaDict itemAttr: kSecDescriptionItemAttr ];
    [ self p_addSearchCriteriaWithCStringData: searchCriteriaDict itemAttr: kSecCommentItemAttr ];

    return searchCriteriaDict;
    }

- ( NSMutableDictionary* ) p_wrapApplicationPasswordItemSearchCriteria
    {
    NSMutableDictionary* searchCriteriaDict = [ self p_wrapCommonPasswordItemSearchCriteria ];
    [ self p_addSearchCriteriaWithCStringData: searchCriteriaDict itemAttr: kSecServiceItemAttr ];

    return searchCriteriaDict;
    }

- ( NSMutableDictionary* ) p_wrapInternetPasswordItemSearchCriteria
    {
    NSMutableDictionary* searchCriteriaDict = [ self p_wrapCommonPasswordItemSearchCriteria ];
    [ self p_addSearchCriteriaWithCStringData: searchCriteriaDict itemAttr: kSecServerItemAttr ];
    [ self p_addSearchCriteriaWithUInt32Data: searchCriteriaDict itemAttr: kSecPortItemAttr ];
    [ self p_addSearchCriteriaWithFourCharCodeData: searchCriteriaDict itemAttr: kSecProtocolItemAttr ];

    return searchCriteriaDict;
    }

@end // WSCPassphraseItem + WSCPasswordPrivateUtilities

/*================================================================================┐
|                              The MIT License (MIT)                              |
|                                                                                 |
|                           Copyright (c) 2015 Tong Guo                           |
|                                                                                 |
|  Permission is hereby granted, free of charge, to any person obtaining a copy   |
|  of this software and associated documentation files (the "Software"), to deal  |
|  in the Software without restriction, including without limitation the rights   |
|    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell    |
|      copies of the Software, and to permit persons to whom the Software is      |
|            furnished to do so, subject to the following conditions:             |
|                                                                                 |
| The above copyright notice and this permission notice shall be included in all  |
|                 copies or substantial portions of the Software.                 |
|                                                                                 |
|   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR    |
|    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,     |
|   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE   |
|     AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER      |
|  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,  |
|  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE  |
|                                    SOFTWARE.                                    |
└================================================================================*/