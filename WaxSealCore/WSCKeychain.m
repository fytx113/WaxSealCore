///:
/*****************************************************************************
 **                                                                         **
 **                               .======.                                  **
 **                               | INRI |                                  **
 **                               |      |                                  **
 **                               |      |                                  **
 **                      .========'      '========.                         **
 **                      |   _      xxxx      _   |                         **
 **                      |  /_;-.__ / _\  _.-;_\  |                         **
 **                      |     `-._`'`_/'`.-'     |                         **
 **                      '========.`\   /`========'                         **
 **                               | |  / |                                  **
 **                               |/-.(  |                                  **
 **                               |\_._\ |                                  **
 **                               | \ \`;|                                  **
 **                               |  > |/|                                  **
 **                               | / // |                                  **
 **                               | |//  |                                  **
 **                               | \(\  |                                  **
 **                               |  ``  |                                  **
 **                               |      |                                  **
 **                               |      |                                  **
 **                               |      |                                  **
 **                               |      |                                  **
 **                   \\    _  _\\| \//  |//_   _ \// _                     **
 **                  ^ `^`^ ^`` `^ ^` ``^^`  `^^` `^ `^                     **
 **                                                                         **
 **                       Copyright (c) 2014 Tong G.                        **
 **                          ALL RIGHTS RESERVED.                           **
 **                                                                         **
 ****************************************************************************/

#import "WSCKeychain.h"

#pragma mark Private Programmatic Interfaces for Creating Keychains
@implementation WSCKeychain ( WSCKeychainPrivateInitialization )

- ( instancetype ) initWithSecKeychainRef: ( SecKeychainRef )_SecKeychainRef
    {
    if ( self = [ super init ] )
        {
        if ( _SecKeychainRef )
            self->_secKeychain = ( SecKeychainRef )CFRetain( _SecKeychainRef );
        else
            return nil;
        }

    return self;
    }

@end // WSCKeychain + WSCKeychainPrivateInitialization

@implementation WSCKeychain

@synthesize secKeychain = _secKeychain;

@dynamic URL;
@dynamic isDefault;

#pragma mark Properties
- ( NSURL* ) URL
    {
    OSStatus resultCode = errSecSuccess;

    /* On entry, this variable represents the length (in bytes) of the buffer specified by secPath.
     * and on return, this variable represents the string length of secPath, not including the null termination */
    UInt32 secPathLength = MAXPATHLEN;

    /* On entry, it's a pointer to buffer we have allocated 
     * and on return, the buffer contains POSIX path of the keychain as a null-terminated UTF-8 encoding string */
    char secPath[ MAXPATHLEN + 1 ] = { 0 };

    resultCode = SecKeychainGetPath( self->_secKeychain, &secPathLength, secPath );

    if ( resultCode == errSecSuccess )
        {
        NSString* pathStringForKeychain = [ [ [ NSString alloc ] initWithCString: secPath
                                                                        encoding: NSUTF8StringEncoding ] autorelease ];

        NSURL* URLForKeychain = [ NSURL URLWithString: [ @"file://" stringByAppendingString: pathStringForKeychain ] ];

        NSError* error = nil;
        if ( [ URLForKeychain isFileURL ] && [ URLForKeychain checkResourceIsReachableAndReturnError: &error ] )
            return URLForKeychain;
        }
    else
        WSCPrintError( resultCode );

    return nil;
    }

- ( BOOL ) isDefault
    {
    /* Determine whether receiver is default by comparing with the URL of current default */
    return [ [ WSCKeychain currentDefaultKeychain ].URL isEqualTo: self.URL ];
    }
//
//- ( void ) setIsDefault: ( BOOL )_IsDefault
//    {
//    [ self setDefault: nil ];
//    }

#pragma mark Public Programmatic Interfaces for Creating Keychains

/* Creates and returns a WSCKeychain object using the given URL, password, 
 * interaction prompt and inital access rights. 
 */
+ ( instancetype ) keychainWithURL: ( NSURL* )_URL
                          password: ( NSString* )_Password
                    doesPromptUser: ( BOOL )_DoesPromptUser
                     initialAccess: ( WSCAccess* )_InitalAccess
                    becomesDefault: ( BOOL )_WillBecomeDefault
                             error: ( NSError** )_Error
    {
    OSStatus resultCode = errSecSuccess;

    SecKeychainRef newSecKeychain = NULL;
    resultCode = SecKeychainCreate( [ _URL path ].UTF8String
                                  , ( UInt32 )[ _Password length ], _Password.UTF8String
                                  , ( Boolean )_DoesPromptUser
                                  , nil
                                  , &newSecKeychain
                                  );

    if ( resultCode == errSecSuccess )
        {
        WSCKeychain* newKeychain = [ WSCKeychain keychainWithSecKeychainRef: newSecKeychain ];
        CFRelease( newSecKeychain );

////        if ( _WillBecomeDefault )
//            // TODO: Set the new keychain as default

        return newKeychain;
        }
    else
        {
        WSCPrintError( resultCode );
        if ( _Error )
            {
            CFStringRef cfErrorDesc = SecCopyErrorMessageString( resultCode, NULL );
            *_Error = [ NSError errorWithDomain: NSOSStatusErrorDomain
                                           code: resultCode
                                       userInfo: @{ NSLocalizedDescriptionKey : NSLocalizedString( ( __bridge NSString* )cfErrorDesc, nil ) }
                                       ];
            CFRelease( cfErrorDesc );
            }

        return nil;
        }
    }

/* Creates and returns a WSCKeychain object using the 
 * given reference to the instance of *SecKeychain* opaque type. 
 */
+ ( instancetype ) keychainWithSecKeychainRef: ( SecKeychainRef )_SecKeychainRef
    {
    return [ [ [ self alloc ] initWithSecKeychainRef: _SecKeychainRef ] autorelease ];
    }

/* Opens and returns a WSCKeychain object representing the login.keychain for current user. 
 */
+ ( instancetype ) login
    {
    OSStatus resultCode = errSecSuccess;
    NSError* error = nil;

    NSURL* URLForLogin = [ NSURL URLWithString:
        [ NSString stringWithFormat: @"file://%@/Library/Keychains/login.keychain", NSHomeDirectory() ] ];

    SecKeychainRef secLoginKeychain = NULL;
    WSCKeychain* loginKeychain = nil;

    /* If the login.keychain is already exists
     * otherwise, we have no necessary to create one, return nil is OK.
     */
    if ( [ URLForLogin checkResourceIsReachableAndReturnError: &error ] )
        {
        resultCode = SecKeychainOpen( URLForLogin.path.UTF8String, &secLoginKeychain );

        if ( resultCode == errSecSuccess )
            {
            loginKeychain = [ WSCKeychain keychainWithSecKeychainRef: secLoginKeychain ];
            CFRelease( secLoginKeychain );

            return loginKeychain;
            }
        else
            WSCPrintError( resultCode );
        }

    return nil;
    }

#pragma mark Public Programmatic Interfaces for Managing Keychains

/* Retrieves a WSCKeychain object represented the current default keychain. */
+ ( instancetype ) currentDefaultKeychain
    {
    return [ self currentDefaultKeychain: nil ];
    }

+ ( instancetype ) currentDefaultKeychain: ( NSError** )_Error
    {
    OSStatus resultCode = errSecSuccess;

    SecKeychainRef currentDefaultSecKeychain = NULL;
    resultCode = SecKeychainCopyDefault( &currentDefaultSecKeychain );

    if ( resultCode == errSecSuccess )
        {
        WSCKeychain* currentDefaultKeychain = [ WSCKeychain keychainWithSecKeychainRef: currentDefaultSecKeychain ];
        CFRelease( currentDefaultSecKeychain );

        return currentDefaultKeychain;
        }
    else
        {
        if ( _Error )
            {
            CFStringRef cfErrorDesc = SecCopyErrorMessageString( resultCode, NULL );
            *_Error = [ NSError errorWithDomain: NSOSStatusErrorDomain
                                           code: resultCode
                                       userInfo: @{ NSLocalizedDescriptionKey : NSLocalizedString( ( __bridge NSString* )cfErrorDesc, nil ) }
                                       ];
            CFRelease( cfErrorDesc );
            }

        return nil;
        }
    }

/* Sets current keychain as default keychain. */
- ( void ) setDefault: ( BOOL )_IsDefault
                error: ( NSError** )_Error
    {
    OSStatus resultCode = errSecSuccess;

    if ( _IsDefault )
        {
        if ( !self.isDefault /* If receiver is not already default... */ )
            {
            resultCode = SecKeychainSetDefault( self->_secKeychain );

            if ( resultCode != errSecSuccess )
                WSCFillErrorParam( resultCode, _Error );
            } /* ... if receiver is already default, do nothing. */
        }
    else
        {
        if ( self.isDefault /* If receiver is already default... */ )
            {
            /* Cancel the default state for receiver */
            WSCKeychain* loginKeychain = [ WSCKeychain login ]; // TODO:

            if ( loginKeychain )
                /* if login.keychain is already exists,
                 * cancel default state of receiver, make login.keychain default */
                resultCode = SecKeychainSetDefault( loginKeychain.secKeychain );

            } /* ... if receiver is not already default, do nothing. */
        }
    }

- ( void ) dealloc
    {
    if ( self->_secKeychain )
        CFRelease( self->_secKeychain );

    [ super dealloc ];
    }

- ( NSUInteger ) hash
    {
    return [ self URL ].hash;
    }

@end // WSCKeychain class

//////////////////////////////////////////////////////////////////////////////

/*****************************************************************************
 **                                                                         **
 **                                                                         **
 **      █████▒█    ██  ▄████▄   ██ ▄█▀       ██████╗ ██╗   ██╗ ██████╗     **
 **    ▓██   ▒ ██  ▓██▒▒██▀ ▀█   ██▄█▒        ██╔══██╗██║   ██║██╔════╝     **
 **    ▒████ ░▓██  ▒██░▒▓█    ▄ ▓███▄░        ██████╔╝██║   ██║██║  ███╗    **
 **    ░▓█▒  ░▓▓█  ░██░▒▓▓▄ ▄██▒▓██ █▄        ██╔══██╗██║   ██║██║   ██║    **
 **    ░▒█░   ▒▒█████▓ ▒ ▓███▀ ░▒██▒ █▄       ██████╔╝╚██████╔╝╚██████╔╝    **
 **     ▒ ░   ░▒▓▒ ▒ ▒ ░ ░▒ ▒  ░▒ ▒▒ ▓▒       ╚═════╝  ╚═════╝  ╚═════╝     **
 **     ░     ░░▒░ ░ ░   ░  ▒   ░ ░▒ ▒░                                     **
 **     ░ ░    ░░░ ░ ░ ░        ░ ░░ ░                                      **
 **              ░     ░ ░      ░  ░                                        **
 **                    ░                                                    **
 **                                                                         **
 ****************************************************************************/