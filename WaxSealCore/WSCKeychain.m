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
#import "NSURL+WSCKeychainURL.h"
#import "WSCKeychainConstants.h"

#pragma mark Private Programmatic Interfaces for Creating Keychains
@implementation WSCKeychain ( WSCKeychainPrivateInitialization )

- ( instancetype ) p_initWithSecKeychainRef: ( SecKeychainRef )_SecKeychainRef
    {
    if ( self = [ super init ] )
        {
        NSString* path = WSCKeychainGetPathOfKeychain( _SecKeychainRef );

        /* Ensure that the _SecKeychainRef does reference an exist keychain file */
        if ( _SecKeychainRef && path )
            self->_secKeychain = ( SecKeychainRef )CFRetain( _SecKeychainRef );
        else
            return nil;
        }

    return self;
    }

@end // WSCKeychain + WSCKeychainPrivateInitialization

NSString* WSCKeychainGetPathOfKeychain( SecKeychainRef _Keychain )
    {
    if ( _Keychain )
        {
        OSStatus resultCode = errSecSuccess;

        /* On entry, this variable represents the length (in bytes) of the buffer specified by secPath.
         * and on return, this variable represents the string length of secPath, not including the null termination */
        UInt32 secPathLength = MAXPATHLEN;

        /* On entry, it's a pointer to buffer we have allocated 
         * and on return, the buffer contains POSIX path of the keychain as a null-terminated UTF-8 encoding string */
        char secPath[ MAXPATHLEN + 1 ] = { 0 };

        resultCode = SecKeychainGetPath( _Keychain, &secPathLength, secPath );
        if ( resultCode == errSecSuccess )
            {
            NSString* pathOfKeychain = [ [ [ NSString alloc ] initWithCString: secPath
                                                                     encoding: NSUTF8StringEncoding ] autorelease ];

            BOOL doesExist = NO;
            BOOL isDir = NO;
            doesExist = [ [ NSFileManager defaultManager ] fileExistsAtPath: pathOfKeychain isDirectory: &isDir ];

            if ( doesExist /* The _Keychain does reference an exist keychain file */
                    && !isDir /* This path isn't a directory */ )
                return pathOfKeychain;
            }
        else
            WSCPrintError( resultCode );
        }

    return nil;
    }

@implementation WSCKeychain

@synthesize secKeychain = _secKeychain;

@dynamic URL;
@dynamic isDefault;

#pragma mark Properties
- ( NSURL* ) URL
    {
    NSString* pathOfKeychain = WSCKeychainGetPathOfKeychain( self.secKeychain );

    if ( pathOfKeychain )
        {
        NSURL* URLForKeychain = [ NSURL URLWithString: [ @"file://" stringByAppendingString: pathOfKeychain ] ];

        NSError* error = nil;
        if ( [ URLForKeychain isFileURL ] && [ URLForKeychain checkResourceIsReachableAndReturnError: &error ] )
            return URLForKeychain;
        }

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
    return [ [ [ self alloc ] p_initWithSecKeychainRef: _SecKeychainRef ] autorelease ];
    }

/* Opens and returns a WSCKeychain object representing the login.keychain for current user. 
 */
+ ( instancetype ) login
    {
    NSError* error = nil;

    WSCKeychain* loginKeychain = [ WSCKeychain keychainWithContentsOfURL: [ NSURL sharedURLForLoginKeychain ]
                                                                   error: &error ];
    if ( error )
        /* Log for easy to debug */
        NSLog( @"%@", error );

    return loginKeychain;
    }

+ ( instancetype ) system
    {
    NSError* error = nil;

    WSCKeychain* systemKeychain = [ WSCKeychain keychainWithContentsOfURL: [ NSURL sharedURLForSystemKeychain ]
                                                                    error: &error ];
    if ( error )
        /* Log for easy to debug */
        NSLog( @"%@", error );

    return systemKeychain;
    }

/* Opens a keychain from the location specified by a given URL.
 */
+ ( instancetype ) keychainWithContentsOfURL: ( NSURL* )_URLOfKeychain
                                       error: ( NSError** )_Error
    {
    if ( [ _URLOfKeychain checkResourceIsReachableAndReturnError: _Error ]  /* If the given URL is reachable... */ )
        {
        BOOL isDir = NO;
        BOOL doesExist = [ [ NSFileManager defaultManager ] fileExistsAtPath: _URLOfKeychain.path isDirectory: &isDir ];

        if ( !isDir /* ... and the given path is NOT a directory */
                && doesExist /* ... and this file does exist. */ )
            {
            OSStatus resultCode = errSecSuccess;

            SecKeychainRef secKeychain = NULL;
            resultCode = SecKeychainOpen( _URLOfKeychain.path.UTF8String, &secKeychain );

            if ( resultCode == errSecSuccess )
                {
                WSCKeychain* keychain = [ WSCKeychain keychainWithSecKeychainRef: secKeychain ];
                CFRelease( secKeychain );

                return keychain;
                }
            else
                {
                WSCPrintError( resultCode );
                WSCFillErrorParam( resultCode, _Error );
                }
            }
        else
            {
            /* If the given path is a directory or the given path is NOT a directory but there is no such file */
            *_Error = [ NSError errorWithDomain: isDir ? WSCKeychainErrorDomain : NSCocoaErrorDomain
                                           code: isDir ? WSCKeychainCannotBeDirectory : NSFileNoSuchFileError
                                       userInfo: isDir ? @{ NSLocalizedDescriptionKey : NSLocalizedString( @"Cannot be a directory", nil ) }
                                                       : nil ];
            }
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
        /* If the keychain file referenced by currentDefaultSecKeychain is invalid or doesn't exist
         * (perhaps it has been deleted, renamed or moved), this method will return nil
         */
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

            /* If we receiver is login.keychain */
            if ( [ self isEqualToKeychain: loginKeychain ] )
                {
                /* TODO: Create a temporary keychain, make it default, then delete it */
                NSURL* URLForTempKeychain = [ [ NSURL URLForTemporaryDirectory ] URLByAppendingPathComponent: [ NSString stringWithFormat: @"%lu", NSStringFromSelector( _cmd ).hash ] ];
                WSCKeychain* tempKeychain = [ WSCKeychain keychainWithURL: URLForTempKeychain
                                                                 password: [ NSString stringWithFormat: @"%lu", NSStringFromSelector( _cmd ).hash ]
                                                           doesPromptUser: NO
                                                            initialAccess: nil
                                                           becomesDefault: NO
                                                                    error: nil ];
                SecKeychainSetDefault( tempKeychain.secKeychain );
                [ [ NSFileManager defaultManager ] removeItemAtURL: URLForTempKeychain error: nil ];
                }
            else
                {
                /* if login.keychain is already exists, and receiver is not login.keychain
                 * cancel default state of receiver, make login.keychain default */
                resultCode = SecKeychainSetDefault( loginKeychain.secKeychain );
                }

            } /* ... if receiver is not already default, do nothing. */
        }
    }

/* Returns a Boolean value that indicates whether the receiver is currently valid. */
- ( BOOL ) isValid
    {
    return self.URL ? YES : NO;
    }

/* Returns a Boolean value that indicates 
 * whether a given keychain is equal to receiver using an URL comparision. 
 */
- ( BOOL ) isEqualToKeychain: ( WSCKeychain* )_AnotherKeychain
    {
    if ( self == _AnotherKeychain )
        return YES;

    return ( self.hash == _AnotherKeychain.hash )
                && [ self.URL isEqualTo: _AnotherKeychain.URL ];
    }

#pragma mark Overrides
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

- ( BOOL ) isEqual: ( id )_Object
    {
    if ( self == _Object )
        return YES;

    if ( [ _Object isKindOfClass: [ WSCKeychain class ] ] )
        return [ self isEqualToKeychain: ( WSCKeychain* )_Object ];

    return [ super isEqual: _Object ];
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