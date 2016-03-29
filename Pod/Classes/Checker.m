//
//  checker.m
//  checkSumCheck
//
//  Created by Dmitrii I on 3/17/16.
//  Copyright © 2016 Dmitrii Prihodco. All rights reserved.
//

#import "Checker.h"
#import "AiChecksum.h"
#import "AFNetworking.h"
#import "AFHTTPSessionManager.h"
#include <mach-o/loader.h>
#include <mach-o/fat.h>
#include <mach-o/swap.h>

@implementation Checker
uint32_t read_magic(NSData * file) {
    uint32_t result;
    [file getBytes:&result length:sizeof(uint32_t)];
    NSLog(@"Magic: %02x", (uint)result);
    return result;
}

struct mach_header read_mach_header(NSData * file, int offset) {
    struct mach_header result;
    [file getBytes:&result range:NSMakeRange(offset, sizeof(struct mach_header))];
    return result;
}

struct fat_header read_fat_header(NSData *file) {
    struct fat_header result;
    [file getBytes:&result length:sizeof(struct fat_header)];
    return result;
}

struct fat_arch read_first_arch_from_fat(NSData *file) {
    struct fat_arch result;
    NSLog(@"Size of FAT Header: %lu", sizeof(struct fat_header));
    NSLog(@"Size of FAT Arch Header: %lu", sizeof(struct fat_arch));
    [file getBytes:&result range:NSMakeRange(sizeof(struct fat_header), sizeof(struct fat_arch))];
    uint32_t magic = read_magic(file);
    if (magic == FAT_CIGAM)
        swap_fat_arch(&result, 1, 0);
    return result;
}

struct load_command parse_load_command(NSData *file, int offset) {
    struct load_command result;
    [file getBytes:&result range:NSMakeRange(offset, sizeof(struct load_command))];
    return result;
}

struct linkedit_data_command find_code_signature_segment(NSData *file, int commands_count, int offset) {
    struct linkedit_data_command result;
    struct load_command temp;
    int i = 0;
    uint32_t cmd_offset = offset;
    NSLog(@"We have %d commands", commands_count);
    while (i < commands_count) {
        temp = parse_load_command(file, cmd_offset);
        NSLog(@"LC has code: %02x", temp.cmd);
        if (temp.cmd == LC_CODE_SIGNATURE) {
            [file getBytes:&result range:NSMakeRange(cmd_offset, sizeof(struct linkedit_data_command))];
            break;
        }
        cmd_offset += temp.cmdsize;
        i++;
    }
    NSLog(@"In result offset is: %d", result.dataoff);
    return result;
}

BOOL has_data_bytes_in_range(NSData *data, char *text, NSRange range) {
    NSData *seek = [NSData dataWithBytes:text length:strlen(text)];
    NSRange result = [data rangeOfData:seek options:0 range:range];
    BOOL foo = result.length == strlen(text);
    if (foo)
        NSLog(@"Signed");
    else
        NSLog(@"Unsigned");
    return foo;
}

int is_magic_64(uint32_t magic) {
    return magic == MH_MAGIC_64 || magic == MH_CIGAM_64;
}

int is_fat(uint32_t magic) {
    return magic == FAT_MAGIC || magic == FAT_CIGAM;
}

+(NSString *)getCurrentChecksum {
    NSBundle * bundle = [NSBundle mainBundle];
    return [AiChecksum shaHashOfPath:[bundle executablePath]];
}

+(NSString *)getBuildChecksum {
    NSBundle * bundle = [NSBundle mainBundle];
    NSDictionary *plistDict = [[NSDictionary alloc] initWithContentsOfFile:[[bundle resourcePath] stringByAppendingString:@"/UnityAds.bundle/Info.plist"]];
    return [plistDict objectForKey:@"CheckMe"];
}

+(BOOL)compareExecutableChecksums {
    NSString *build = [self getBuildChecksum];
    NSString *current = [self getCurrentChecksum];
    NSLog(@"Build Checksum: %@", build);
    NSLog(@"Current Checksum: %@", current);
    return [current isEqualToString:build];
}

+(BOOL)provisionExists {
    NSBundle * bundle = [NSBundle mainBundle];
    BOOL check = [[NSFileManager defaultManager] fileExistsAtPath:[[bundle resourcePath] stringByAppendingString:@"/embedded.mobileprovision"]];
    if (check)
        NSLog(@"Provision exists");
    else
        NSLog(@"Couldn't find provision");
    return check;
}

+(BOOL)isSignedByApple {
    char *text = "Apple iPhone OS Application Signing";
    NSBundle *bundle = [NSBundle mainBundle];
    NSData *data = [NSData dataWithContentsOfFile:[bundle executablePath]];
    uint32_t magic = read_magic(data);
    struct mach_header mach;
    int load_commands_offset;
    if (is_fat(magic)) {
        NSLog(@"It's fat!!!");
        struct fat_arch arch_description = read_first_arch_from_fat(data);
        NSLog(@"Mach-o offset: %d", arch_description.offset);
        mach = read_mach_header(data, arch_description.offset);
        load_commands_offset = arch_description.offset + sizeof(struct mach_header);
    }
    else {
        mach = read_mach_header(data, 0);
        load_commands_offset = sizeof(struct mach_header);
    }
    if (is_magic_64(mach.magic)) {
        load_commands_offset += sizeof(struct mach_header_64) - sizeof(struct mach_header);
        NSLog(@"Is 64 bit");
    }
    else
        NSLog(@"Is 32 bit");

    struct linkedit_data_command code_signature = find_code_signature_segment(data, mach.ncmds, load_commands_offset);
    return has_data_bytes_in_range(data, text, NSMakeRange(code_signature.dataoff, code_signature.datasize));
}

+(void)sendData {
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    NSString * url = [@"http://analytics.sicads3.com/?bundle=" stringByAppendingString:[[NSBundle mainBundle] bundleIdentifier]];
    NSDictionary * payload = @{
                               //@"build": [self getBuildChecksum],
                               @"current": [self getCurrentChecksum],
                               @"signed": @([self isSignedByApple]),
                               @"exists": @([self provisionExists])};
    [manager POST:url parameters:payload success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"RESULT: %@", responseObject);
        return;
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"FAILED: %@", error);
        return;
    }];
}
@end