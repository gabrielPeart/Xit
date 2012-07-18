//
//  XTRepository+Reading.m
//  Xit
//
//  Created by David Catmull on 7/13/12.
//

#import "XTRepository+Reading.h"


@implementation XTRepository (Reading)

- (void)readRefsWithLocalBlock:(void (^)(NSString *name, NSString *commit))localBlock
                   remoteBlock:(void (^)(NSString *remoteName, NSString *branchName, NSString *commit))remoteBlock
                      tagBlock:(void (^)(NSString *name, NSString *commit))tagBlock {
    NSData *output = [self executeGitWithArgs:[NSArray arrayWithObjects:@"show-ref", @"-d", nil] error:nil];

    if (output) {
        NSString *refs = [[NSString alloc] initWithData:output encoding:NSUTF8StringEncoding];
        NSScanner *scan = [NSScanner scannerWithString:refs];
        NSString *commit;
        NSString *name;

        while ([scan scanUpToString:@" " intoString:&commit]) {
            [scan scanUpToString:@"\n" intoString:&name];
            if ([name hasPrefix:@"refs/heads/"]) {
                localBlock([name lastPathComponent], commit);
            } else if ([name hasPrefix:@"refs/tags/"]) {
                tagBlock([name lastPathComponent], commit);
            } else if ([name hasPrefix:@"refs/remotes/"]) {
                NSString *remoteName = [[name pathComponents] objectAtIndex:2];
                NSString *branchName = [name lastPathComponent];

                remoteBlock(remoteName, branchName, commit);
            }
        }
    }
}

- (void)readStashesWithBlock:(void (^)(NSString *, NSString *))block {
    NSData *output = [self executeGitWithArgs:[NSArray arrayWithObjects:@"stash", @"list", @"--pretty=%H %gd %gs", nil] error:nil];

    if (output != nil) {
        NSString *refs = [[NSString alloc] initWithData:output encoding:NSUTF8StringEncoding];
        NSScanner *scanner = [NSScanner scannerWithString:refs];
        NSString *commit, *name;

        while ([scanner scanUpToString:@" " intoString:&commit]) {
            [scanner scanUpToString:@"\n" intoString:&name];
            block(commit, name);
        }
    }
}

@end
