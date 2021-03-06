# ANE-Share

A simple native extension for sharing text and bitmap content on [Android](https://developer.android.com/training/sharing/send.html) and [iOS](https://developer.apple.com/documentation/uikit/uiactivityviewcontroller).

## Getting started

Download the ANE from the [releases](../../releases/) page and add it to your app's descriptor:

```xml
<extensions>
    <extensionID>com.digitalstrawberry.ane.share</extensionID>
</extensions>
```

If you are targeting Android, add the AndroidX Core extension from [Distriqt](https://github.com/distriqt/ANE-AndroidSupport) as well:

```xml
<extensions>
    <extensionID>androidx.core</extensionID>
</extensions>
```

> Credits to [Distriqt](https://github.com/distriqt) for providing this and other extensions.

Furthermore, modify `manifestAdditions` element so that it contains the following `provider` element:

```xml
<android>
    <manifestAdditions>
        <![CDATA[
        <manifest android:installLocation="auto">

            <application>

                <provider
                    android:name="androidx.core.content.FileProvider"
                    android:authorities="{APP_PACKAGE_NAME}.fileprovider"
                    android:grantUriPermissions="true"
                    android:exported="false">
                    <meta-data
                        android:name="android.support.FILE_PROVIDER_PATHS"
                        android:resource="@xml/digitalstrawberry_share_paths" />
                </provider>

            </application>

        </manifest>
        ]]>
    </manifestAdditions>
</android>
```

Make sure to replace the `{APP_PACKAGE_NAME}` token with your application id (value of the `id` element in your AIR app descriptor). Remember the id is prefixed with `air.` by default.

Add the following key-value pairs to your `InfoAdditions` to avoid crashes on iOS 10+ when saving an image to photos library or assigning it to a contact:

```xml
<iPhone>
    <InfoAdditions><![CDATA[

        <key>NSPhotoLibraryUsageDescription</key>
        <string>Access to photo library is required to save images.</string>

        <key>NSContactsUsageDescription</key>
        <string>Access to contacts is required to assign images.</string>

        <key>NSPhotoLibraryAddUsageDescription</key>
        <string>Access to photo library is required to save images.</string>

    ]]></InfoAdditions>
</iPhone>
```

## API Overview

To share some data, create a `Vector` of `SharedData` objects and pass it in to the `share` method:

```as3
[Embed(source="/../assets/image.png")]
private static var SHARED_IMAGE:Class;

...

var bitmap:Bitmap = new SHARED_IMAGE();

var sharedLink:SharedData = new SharedData("https://github.com");
var sharedImage:SharedData = new SharedData(bitmap.bitmapData);

var sharedItems:Vector.<SharedData> = new <SharedData>[sharedLink, sharedImage];

Share.instance.share(sharedItems);
```

On iPads, the sharing UI is presented in a [popover](https://developer.apple.com/ios/human-interface-guidelines/ui-views/popovers/). You can customize the popover position, size and the direction of the arrow by providing `ShareOptions` object. In the example below, the popover will display in default size (rectangle width and height is set to 0) with the arrow pointing up towards the center of the screen:

```as3
var shareOptions:ShareOptions = new ShareOptions();
shareOptions.position = new Rectangle(stage.stageWidth * 0.5, stage.stageHeight * 0.5);
shareOptions.arrowDirection = ShareOptions.ARROW_UP;

...

Share.instance.share(sharedItems, shareOptions);
```

**Note it is completely up to the selected application whether it accepts the data you want to share or not.** For example, the Facebook application on iOS may ignore your image if you share it together with a link.

The extension allows you to prioritize some content over the other when sharing to Facebook. You can set the `shareWithFacebook` property to `false` to ensure the selected data will not be shared with Facebook on iOS. In the example below, we make sure the image is not discarded when sharing to Facebook on iOS:

```as3
var sharedLink:SharedData = new SharedData("https://github.com");
sharedLink.shareWithFacebook = false; // Ignore link when sharing to Facebook on iOS
var sharedImage:SharedData = new SharedData(bitmap.bitmapData);

var sharedItems:Vector.<SharedData> = new <SharedData>[sharedLink, sharedImage];

Share.instance.share(sharedItems);
```

When sharing URLs to local files you should set the `isLocalFileUrl` property to `true`. This tells the system to treat the value as a local file URL and not a generic `String`. This way the file can be added as an attachment when sharing via email and more appropriate sharing options can be shown to the user:

```as3
var sharedVideo:SharedData = new SharedData("/path/to/local/file.mp4");
sharedVideo.isLocalFileUrl = true;

...
```

You can add event listeners to be notified when sharing is finished. Note that Android applications do not necessarily respond correctly, therefore it is very common to receive the `CANCEL` event even when sharing is completed successfully on Android:

```as3
Share.instance.addEventListener(ShareEvent.COMPLETE, onSharingFinished);
Share.instance.addEventListener(ShareEvent.CANCEL, onSharingFinished);
Share.instance.addEventListener(ShareEvent.ERROR, onSharingFinished);

private function onSharingFinished(event:ShareEvent):void
{
    ...
}
```

### Changelog

#### October 20, 2020 (v1.1.0)

* Added support for AndroidX
* Added `Android-x64` target

#### January 14, 2020 (v1.0.8)

* Added support for Android 64bit

#### March 25, 2019 (v1.0.7)

* Added support for custom MIME type (Android only)

#### March 18, 2019 (v1.0.6)

* Updated file sharing for Android API 24+

#### March 23, 2018 (v1.0.5)

* Added support for sharing local file URLs

#### January 2, 2018 (v1.0.4)

* Updated sharing dialog (Android)

#### November 28, 2017 (v1.0.3)

* Updated error handling

#### October 16, 2017 (v1.0.2)

* Added support for iOS 7

#### August 9, 2017 (v1.0.0)

* Public release
