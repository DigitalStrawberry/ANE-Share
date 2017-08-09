/*
 * The MIT License (MIT)
 *
 * Copyright (c) 2017 Digital Strawberry LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

#import <AIRExtHelpers/MPFREObjectUtils.h>
#import <AIRExtHelpers/MPBitmapDataUtils.h>
#import "Share.h"
#import "ShareItem.h"
#import "ShareEvent.h"
#import "Functions/IsSupportedFunction.h"
#import "Functions/ShareFunction.h"

static Share* AIRShareExtSharedInstance = nil;
FREContext ShareExtContext = nil;

@implementation Share

# pragma mark - Static API

+ (id) sharedInstance
{
    if( AIRShareExtSharedInstance == nil )
    {
        AIRShareExtSharedInstance = [[Share alloc] init];
    }
    return AIRShareExtSharedInstance;
}

# pragma mark - Public API

- (void) share:(FREObject) freSharedItems options:(FREObject) freOptions
{
    UIViewController* rootView = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
    
    NSArray* sharedItems = [self getSharedItems:freSharedItems];
    
    if( sharedItems.count == 0 )
    {
        NSLog(@"There is no data to be shared!");
        return;
    }
    
    UIActivityViewController *activityViewControntroller = [[UIActivityViewController alloc] initWithActivityItems:sharedItems applicationActivities:nil];
    
    if( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ) {
        CGRect popOverRect = [self getRectFromOptions:freOptions];
        activityViewControntroller.popoverPresentationController.sourceView = [rootView view];
        activityViewControntroller.popoverPresentationController.sourceRect = popOverRect;
        UIPopoverArrowDirection direction = [self getArrowDirectionFromOptions:freOptions];
        if( direction == UIPopoverArrowDirectionUnknown )
        {
            direction = 0; // No arrow
        }
        activityViewControntroller.popoverPresentationController.permittedArrowDirections = direction;
    }
    
    [activityViewControntroller setCompletionHandler:^(NSString* activity, BOOL done) {
        // Fixes bug with non-dismissable view when user taps outside before the corresponding activity's view appears
        [rootView dismissViewControllerAnimated:NO completion:nil];
        
        activity = (activity == nil) ? @"" : activity;
        const NSString* event = done ? kEVENT_SHARE_COMPLETE : kEVENT_SHARE_CANCEL;
        [self dispatchEvent:event withMessage:activity];
    }];
    
    [rootView presentViewController:activityViewControntroller animated:YES completion:nil];
}

- (BOOL) isSupported
{
    return SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0") && ([UIActivityViewController class] != nil);
}


- (void) dispatchEvent:(const NSString*) eventName
{
    [self dispatchEvent:eventName withMessage:@""];
}

- (void) dispatchEvent:(const NSString*) eventName withMessage:(NSString*) message
{
    NSString* messageText = message ? message : @"";
    FREDispatchStatusEventAsync( ShareExtContext, (const uint8_t*) [eventName UTF8String], (const uint8_t*) [messageText UTF8String] );
}


# pragma mark - Private API


- (NSArray*) getSharedItems:(FREObject) freSharedItems
{
    NSMutableArray* result = [NSMutableArray array];
    
    uint32_t arrayLength;
    FREGetArrayLength(freSharedItems, &arrayLength);
    
    for (uint32_t i = 0; i < arrayLength; i++)
    {
        FREObject itemRaw = NULL; // SharedData object in AS3
        if( FREGetArrayElementAt(freSharedItems, i, &itemRaw) != FRE_OK )
        {
            NSLog(@"Error retrieving Vector.<SharedData> element at index %u", i);
            continue;
        }
        
        // Check whether this data should be shared with Facebook
        FREObject freSharedWithFB = NULL;
        if( ![self getObjectProperty:itemRaw propertyName:@"shareWithFacebook" propertyValue:&freSharedWithFB] )
        {
            NSLog(@"Error reading 'shareWithFacebook' property from SharedData object");
            continue;
        }
        
        // Get the actual data (either a String or BitmapData)
        FREObject freData = NULL;
        if( ![self getObjectProperty:itemRaw propertyName:@"data" propertyValue:&freData] )
        {
            NSLog(@"Error reading 'data' property from SharedData object");
            continue;
        }
        
        id data = [self getSharedData:freData];
        if( data == nil )
        {
            NSLog(@"Error reading 'data' property from SharedData object");
            continue;
        }
        
        // Add the item to the result list
        ShareItem* item = [[ShareItem alloc] initWithPlaceholderItem:data];
        item.itemData = data;
        item.shareWithFacebook = [MPFREObjectUtils getBOOL:freSharedWithFB];
        [result addObject:item];
    }
    
    return result;
}

- (UIPopoverArrowDirection) getArrowDirectionFromOptions:(FREObject) options
{
    FREObject freDirection = NULL;
    if( ![self getObjectProperty:options propertyName:@"arrowDirection" propertyValue:&freDirection] )
    {
        NSLog(@"Error getting 'arrowDirection' property from ShareOptions, fall back to ARROW_ANY.");
        return UIPopoverArrowDirectionAny;
    }
    
    int direction = [MPFREObjectUtils getInt:freDirection];
    
    switch( direction ) {
        case 0:
            return UIPopoverArrowDirectionUnknown;
            
        case 1:
            return UIPopoverArrowDirectionUp;
        
        case 2:
            return UIPopoverArrowDirectionDown;
            
        case 4:
            return UIPopoverArrowDirectionLeft;
            
        case 8:
            return UIPopoverArrowDirectionRight;
    }
    
    return UIPopoverArrowDirectionAny;
}

- (CGRect) getRectFromOptions:(FREObject) options
{
    CGRect screen = [UIScreen mainScreen].bounds;
    
    FREObject frePositionRect = NULL;
    if( ![self getObjectProperty:options propertyName:@"position" propertyValue:&frePositionRect] )
    {
        NSLog(@"Error getting 'position' property from ShareOptions.");
        return screen;
    }
    
    FREObject freRectX = NULL;
    if( ![self getObjectProperty:frePositionRect propertyName:@"x" propertyValue:&freRectX] )
    {
        NSLog(@"Error getting 'x' property from Rectangle.");
        return screen;
    }
    
    FREObject freRectY = NULL;
    if( ![self getObjectProperty:frePositionRect propertyName:@"y" propertyValue:&freRectY] )
    {
        NSLog(@"Error getting 'y' property from Rectangle.");
        return screen;
    }
    
    FREObject freRectWidth = NULL;
    if( ![self getObjectProperty:frePositionRect propertyName:@"width" propertyValue:&freRectWidth] )
    {
        NSLog(@"Error getting 'width' property from Rectangle.");
        return screen;
    }
    
    FREObject freRectHeight = NULL;
    if( ![self getObjectProperty:frePositionRect propertyName:@"height" propertyValue:&freRectHeight] )
    {
        NSLog(@"Error getting 'height' property from Rectangle.");
        return screen;
    }
    
    CGFloat scale = [UIScreen mainScreen].scale;
    CGFloat rectX = [MPFREObjectUtils getDouble:freRectX] / scale;
    CGFloat rectY = [MPFREObjectUtils getDouble:freRectY] / scale;
    CGFloat rectWidth = [MPFREObjectUtils getDouble:freRectWidth];
    CGFloat rectHeight = [MPFREObjectUtils getDouble:freRectHeight];
    
    return CGRectMake(rectX, rectY, rectWidth, rectHeight);
}

- (nullable id) getSharedData:(FREObject) freData
{
    FREObjectType freDataType;
    if( FREGetObjectType(freData, &freDataType) != FRE_OK )
    {
        NSLog(@"Error retrieving data type of the shared data");
        return nil;
    }
    
    if( freDataType == FRE_TYPE_STRING )
    {
        return [MPFREObjectUtils getNSString:freData];
    }
    
    if( freDataType == FRE_TYPE_BITMAPDATA )
    {
        FREBitmapData2 bmpData;
        FREAcquireBitmapData2(freData, &bmpData);
        UIImage* image = [MPBitmapDataUtils getUIImageFromFREBitmapData:bmpData];
        FREReleaseBitmapData(freData);
        return image;
    }
    
    NSLog(@"Invalid type of shared data: %i", freDataType);
    return nil;
}

- (BOOL) getObjectProperty:(FREObject) object propertyName:(NSString*) propertyName propertyValue:(FREObject*) propertyValue
{
    return FREGetObjectProperty(object, (const uint8_t*) [propertyName UTF8String], propertyValue, NULL) == FRE_OK;
}

@end

/**
 *
 *
 * Context initialization
 *
 *
 **/

FRENamedFunction airShareExtFunctions[] =
{
    { (const uint8_t*) "isSupported", 0, ntsh_isSupported },
    { (const uint8_t*) "share",       0, ntsh_share }
};

void AIRShareContextInitializer( void* extData, const uint8_t* ctxType, FREContext ctx, uint32_t* numFunctionsToSet, const FRENamedFunction** functionsToSet )
{
    *numFunctionsToSet = sizeof( airShareExtFunctions ) / sizeof( FRENamedFunction );
    
    *functionsToSet = airShareExtFunctions;
    
    ShareExtContext = ctx;
}

void AIRShareContextFinalizer( FREContext ctx ) { }

void AIRShareInitializer( void** extDataToSet, FREContextInitializer* ctxInitializerToSet, FREContextFinalizer* ctxFinalizerToSet )
{
    *extDataToSet = NULL;
    *ctxInitializerToSet = &AIRShareContextInitializer;
    *ctxFinalizerToSet = &AIRShareContextFinalizer;
}

void AIRShareFinalizer( void* extData ) { }







