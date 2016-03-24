//
//  AiChecksum.h
//  com
//
//  Created by Dmitrii I on 3/8/16.
//  Copyright © 2016 Dmitrii I. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <CommonCrypto/CommonDigest.h>

@interface AiChecksum : NSObject

/**
 * Get the md5 hash of a file
 *
 * @returns		NSString
 * @since		20140120
 * @author		costmo
 * @param		path		Full path to the file
 */
+(NSString *)md5HashOfPath:(NSString *)path;

/**
 * Get the sha1 hash of a file
 *
 * @returns		NSString
 * @since		20140120
 * @author		costmo
 * @param		path		Full path to the file
 */
+(NSString *)shaHashOfPath:(NSString *)path;
@end