#import "RNFirebaseFirestore.h"

#if __has_include(<FirebaseFirestore/FirebaseFirestore.h>)

#import <Firebase.h>
#import "RNFirebaseEvents.h"
#import "RNFirebaseFirestoreCollectionReference.h"
#import "RNFirebaseFirestoreDocumentReference.h"

@implementation RNFirebaseFirestore
RCT_EXPORT_MODULE();

- (id)init {
    self = [super init];
    if (self != nil) {

    }
    return self;
}

RCT_EXPORT_METHOD(collectionGet:(NSString *) appName
                           path:(NSString *) path
                        filters:(NSArray *) filters
                         orders:(NSArray *) orders
                        options:(NSDictionary *) options
                       resolver:(RCTPromiseResolveBlock) resolve
                       rejecter:(RCTPromiseRejectBlock) reject) {
    [[self getCollectionForAppPath:appName path:path filters:filters orders:orders options:options] get:resolve rejecter:reject];
}

RCT_EXPORT_METHOD(collectionOffSnapshot:(NSString *) appName
                                   path:(NSString *) path
                                filters:(NSArray *) filters
                                 orders:(NSArray *) orders
                                options:(NSDictionary *) options
                             listenerId:(nonnull NSString *) listenerId) {
    [RNFirebaseFirestoreCollectionReference offSnapshot:listenerId];
}

RCT_EXPORT_METHOD(collectionOnSnapshot:(NSString *) appName
                                  path:(NSString *) path
                               filters:(NSArray *) filters
                                orders:(NSArray *) orders
                               options:(NSDictionary *) options
                            listenerId:(nonnull NSString *) listenerId) {
    RNFirebaseFirestoreCollectionReference *ref = [self getCollectionForAppPath:appName path:path filters:filters orders:orders options:options];
    [ref onSnapshot:listenerId];
}

RCT_EXPORT_METHOD(documentBatch:(NSString *) appName
                         writes:(NSArray *) writes
                  commitOptions:(NSDictionary *) commitOptions
                       resolver:(RCTPromiseResolveBlock) resolve
                       rejecter:(RCTPromiseRejectBlock) reject) {
    FIRFirestore *firestore = [RNFirebaseFirestore getFirestoreForApp:appName];
    FIRWriteBatch *batch = [firestore batch];

    for (NSDictionary *write in writes) {
        NSString *type = write[@"type"];
        NSString *path = write[@"path"];
        NSDictionary *data = write[@"data"];

        FIRDocumentReference *ref = [firestore documentWithPath:path];

        if ([type isEqualToString:@"DELETE"]) {
            batch = [batch deleteDocument:ref];
        } else if ([type isEqualToString:@"SET"]) {
            NSDictionary *options = write[@"options"];
            if (options && options[@"merge"]) {
                batch = [batch setData:data forDocument:ref options:[FIRSetOptions merge]];
            } else {
                batch = [batch setData:data forDocument:ref];
            }
        } else if ([type isEqualToString:@"UPDATE"]) {
            batch = [batch updateData:data forDocument:ref];
        }
    }

    [batch commitWithCompletion:^(NSError * _Nullable error) {
        if (error) {
            [RNFirebaseFirestore promiseRejectException:reject error:error];
        } else {
            NSMutableArray *result = [[NSMutableArray alloc] init];
            for (NSDictionary *write in writes) {
                // Missing fields from web SDK
                // writeTime
                [result addObject:@{}];
            }
            resolve(result);
        }
    }];
}

RCT_EXPORT_METHOD(documentCollections:(NSString *) appName
                                 path:(NSString *) path
                             resolver:(RCTPromiseResolveBlock) resolve
                             rejecter:(RCTPromiseRejectBlock) reject) {
    [[self getDocumentForAppPath:appName path:path] get:resolve rejecter:reject];
}

RCT_EXPORT_METHOD(documentCreate:(NSString *) appName
                            path:(NSString *) path
                            data:(NSDictionary *) data
                        resolver:(RCTPromiseResolveBlock) resolve
                        rejecter:(RCTPromiseRejectBlock) reject) {
    [[self getDocumentForAppPath:appName path:path] create:data resolver:resolve rejecter:reject];
}

RCT_EXPORT_METHOD(documentDelete:(NSString *) appName
                            path:(NSString *) path
                         options:(NSDictionary *) options
                        resolver:(RCTPromiseResolveBlock) resolve
                        rejecter:(RCTPromiseRejectBlock) reject) {
    [[self getDocumentForAppPath:appName path:path] delete:options resolver:resolve rejecter:reject];
}

RCT_EXPORT_METHOD(documentGet:(NSString *) appName
                         path:(NSString *) path
                     resolver:(RCTPromiseResolveBlock) resolve
                     rejecter:(RCTPromiseRejectBlock) reject) {
    [[self getDocumentForAppPath:appName path:path] get:resolve rejecter:reject];
}

RCT_EXPORT_METHOD(documentGetAll:(NSString *) appName
                       documents:(NSString *) documents
                        resolver:(RCTPromiseResolveBlock) resolve
                        rejecter:(RCTPromiseRejectBlock) reject) {
    // Not supported on iOS out of the box
}

RCT_EXPORT_METHOD(documentOffSnapshot:(NSString *) appName
                                 path:(NSString *) path
                           listenerId:(nonnull NSString *) listenerId) {
    [RNFirebaseFirestoreDocumentReference offSnapshot:listenerId];
}

RCT_EXPORT_METHOD(documentOnSnapshot:(NSString *) appName
                                path:(NSString *) path
                          listenerId:(nonnull NSString *) listenerId) {
    RNFirebaseFirestoreDocumentReference *ref = [self getDocumentForAppPath:appName path:path];
    [ref onSnapshot:listenerId];
}

RCT_EXPORT_METHOD(documentSet:(NSString *) appName
                         path:(NSString *) path
                         data:(NSDictionary *) data
                      options:(NSDictionary *) options
                     resolver:(RCTPromiseResolveBlock) resolve
                     rejecter:(RCTPromiseRejectBlock) reject) {
    [[self getDocumentForAppPath:appName path:path] set:data options:options resolver:resolve rejecter:reject];
}

RCT_EXPORT_METHOD(documentUpdate:(NSString *) appName
                            path:(NSString *) path
                            data:(NSDictionary *) data
                        resolver:(RCTPromiseResolveBlock) resolve
                        rejecter:(RCTPromiseRejectBlock) reject) {
    [[self getDocumentForAppPath:appName path:path] update:data resolver:resolve rejecter:reject];
}

/*
 * INTERNALS/UTILS
 */
+ (void)promiseRejectException:(RCTPromiseRejectBlock)reject error:(NSError *)error {
    NSDictionary *jsError = [RNFirebaseFirestore getJSError:error];
    reject([jsError valueForKey:@"code"], [jsError valueForKey:@"message"], error);
}

+ (FIRFirestore *)getFirestoreForApp:(NSString *)appName {
    FIRApp *app = [FIRApp appNamed:appName];
    return [FIRFirestore firestoreForApp:app];
}

- (RNFirebaseFirestoreCollectionReference *)getCollectionForAppPath:(NSString *)appName path:(NSString *)path filters:(NSArray *)filters orders:(NSArray *)orders options:(NSDictionary *)options {
    return [[RNFirebaseFirestoreCollectionReference alloc] initWithPathAndModifiers:self app:appName path:path filters:filters orders:orders options:options];
}

- (RNFirebaseFirestoreDocumentReference *)getDocumentForAppPath:(NSString *)appName path:(NSString *)path {
    return [[RNFirebaseFirestoreDocumentReference alloc] initWithPath:self app:appName path:path];
}

// TODO: Move to error util for use in other modules
+ (NSString *)getMessageWithService:(NSString *)message service:(NSString *)service fullCode:(NSString *)fullCode {
    return [NSString stringWithFormat:@"%@: %@ (%@).", service, message, [fullCode lowercaseString]];
}

+ (NSString *)getCodeWithService:(NSString *)service code:(NSString *)code {
    return [NSString stringWithFormat:@"%@/%@", [service lowercaseString], [code lowercaseString]];
}

+ (NSDictionary *)getJSError:(NSError *)nativeError {
    NSMutableDictionary *errorMap = [[NSMutableDictionary alloc] init];
    [errorMap setValue:@(nativeError.code) forKey:@"nativeErrorCode"];
    [errorMap setValue:[nativeError localizedDescription] forKey:@"nativeErrorMessage"];

    NSString *code;
    NSString *message;
    NSString *service = @"Firestore";

    // TODO: Proper error codes
    switch (nativeError.code) {
        default:
            code = [RNFirebaseFirestore getCodeWithService:service code:@"unknown"];
            message = [RNFirebaseFirestore getMessageWithService:@"An unknown error occurred." service:service fullCode:code];
            break;
    }

    [errorMap setValue:code forKey:@"code"];
    [errorMap setValue:message forKey:@"message"];

    return errorMap;
}

- (NSArray<NSString *> *)supportedEvents {
    return @[FIRESTORE_COLLECTION_SYNC_EVENT, FIRESTORE_DOCUMENT_SYNC_EVENT];
}

@end

#else
@implementation RNFirebaseFirestore
@end
#endif
