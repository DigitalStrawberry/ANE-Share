# ANE-Share

A simple native extension for sharing text and bitmap content on [Android](https://developer.android.com/training/sharing/send.html) and [iOS](https://developer.apple.com/documentation/uikit/uiactivityviewcontroller).

## Getting started

Download the ANE from the [releases](../../releases/) page and add it to your app's descriptor:

```xml
<extensions>
    <extensionID>com.digitalstrawberry.ane.share</extensionID>
</extensions>
```

If you are targeting Android, add the Android Support extension from [this repository](https://github.com/marpies/android-dependency-anes/releases) as well (unless you know it is included by some other extension):

```xml
<extensions>
    <extensionID>com.marpies.ane.androidsupport</extensionID>
</extensions>
```

Furthermore, modify `manifestAdditions` element so that it contains the following `provider` element:

```xml
<android>
    <manifestAdditions>
        <![CDATA[
        <manifest android:installLocation="auto">

            <application>

                <provider
                    android:name="android.support.v4.content.FileProvider"
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

#### November 28, 2017 (v1.0.3)

* Updated error handling

#### October 16, 2017 (v1.0.2)

* Added support for iOS 7

#### August 9, 2017 (v1.0.0)

* Public release
