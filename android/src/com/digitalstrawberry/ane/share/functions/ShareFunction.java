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

package com.digitalstrawberry.ane.share.functions;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.graphics.Bitmap;
import android.net.Uri;
import androidx.core.content.FileProvider;
import com.adobe.air.AndroidActivityWrapper;
import com.adobe.air.IANEShareActivityResultCallback;
import com.adobe.fre.*;
import com.digitalstrawberry.ane.share.events.ShareEvent;
import com.digitalstrawberry.ane.share.utils.AIR;
import com.digitalstrawberry.ane.share.utils.BitmapDataUtils;
import com.digitalstrawberry.ane.share.utils.FREObjectUtils;

import java.io.*;
import java.util.ArrayList;

public class ShareFunction extends BaseFunction implements IANEShareActivityResultCallback
{
    private static final String SHARE_DIR = "shared_files";
    private static final String IMAGE_NAME = "image";
    private static final String IMAGE_EXT = ".jpeg";

    private static final int SHARE_REQUEST_CODE = 7489;

    @Override
    public FREObject call(FREContext context, FREObject[] args)
    {
        super.call(context, args);

        FREArray freSharedItems = (FREArray) args[0];
        String mimeType = null;

        try
        {
            mimeType = getMimeType(args[1]);
        } catch (Exception ignored)
        {
        }

        try
        {
            Intent shareIntent = new Intent();
            if(addSharedItems(freSharedItems, mimeType, shareIntent))
            {
                AndroidActivityWrapper.GetAndroidActivityWrapper().addActivityResultListener( this );
                AIR.getContext().getActivity().startActivityForResult(
                        Intent.createChooser( shareIntent, "Share" ),
                        SHARE_REQUEST_CODE
                );
            }
        } catch (Exception e)
        {
            e.printStackTrace();
            AIR.dispatchEvent(ShareEvent.SHARE_ERROR, e.getLocalizedMessage());
        }

        return null;
    }

    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent data)
    {
        if(requestCode == SHARE_REQUEST_CODE)
        {
            AndroidActivityWrapper.GetAndroidActivityWrapper().removeActivityResultListener( this );

            // Dispatch event, it may be 'cancel' even if the operation succeeded
            String event = (resultCode == Activity.RESULT_OK) ? ShareEvent.SHARE_COMPLETE : ShareEvent.SHARE_CANCEL;
            AIR.dispatchEvent(event);
        }
    }


    private boolean addSharedItems(FREArray freSharedItems, String mimeType, Intent shareIntent) throws FREWrongThreadException, FREInvalidObjectException, FRETypeMismatchException, FREASErrorException, FRENoSuchNameException, IOException
    {
        long numItems = freSharedItems.getLength();
        int numImages = 0;

        ArrayList<Uri> sharedImages = new ArrayList<Uri>();
        ArrayList<Uri> localFileUrls = new ArrayList<Uri>();
        String sharedMessage = "";

        for (long i = 0; i < numItems; i++)
        {
            FREObject freItem = freSharedItems.getObjectAt(i);
            FREObject data = freItem.getProperty("data");
            boolean isLocalFileUrl = FREObjectUtils.getBoolean(freItem.getProperty("isLocalFileUrl"));

            // Text
            if (!(data instanceof FREBitmapData))
            {
                String sharedDataString = FREObjectUtils.getString(data);;

                // Treat it as a local file url
                if (isLocalFileUrl)
                {
                    Context ctx = AIR.getContext().getActivity().getApplicationContext();
                    File cachePath = new File(ctx.getCacheDir(), SHARE_DIR);
                    cachePath.mkdirs();
                    File sourceFile = new File(sharedDataString);
                    File cacheFile = new File(cachePath, sourceFile.getName());

                    try
                    {
                        copyFile(sourceFile, cacheFile);

                        Uri uri = FileProvider.getUriForFile(ctx, ctx.getPackageName() + ".fileprovider", cacheFile);
                        ctx.grantUriPermission(ctx.getPackageName(), uri, Intent.FLAG_GRANT_READ_URI_PERMISSION);
                        localFileUrls.add(uri);
                    }
                    catch(IOException ignored)
                    {

                    }
                }
                else
                {
                    // A generic text message
                    if (!sharedMessage.equals(""))
                    {
                        sharedMessage += "\n";
                    }
                    sharedMessage += sharedDataString;
                }

            }
            // Image
            else
            {
                Uri bitmapUri = getUriForBitmap((FREBitmapData) data, ++numImages);
                if (bitmapUri != null)
                {
                    sharedImages.add(bitmapUri);
                }
            }
        }

        if (numItems > 1 || sharedImages.size() > 1 || localFileUrls.size() > 1)
        {
            shareIntent.setAction(Intent.ACTION_SEND_MULTIPLE);
        }
        else
        {
            shareIntent.setAction(Intent.ACTION_SEND);
        }

        // Add temporary permission for other apps to read the saved image
        if (sharedImages.size() > 0 || localFileUrls.size() > 0)
        {
            shareIntent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
        }

        boolean addedItems = false;

        // String content
        if (!sharedMessage.equals(""))
        {
            shareIntent.putExtra(Intent.EXTRA_TEXT, sharedMessage);
            addedItems = true;
        }

        // Uri(s)
        ArrayList<Uri> sharedUris = new ArrayList<Uri>();
        sharedUris.addAll(localFileUrls);
        sharedUris.addAll(sharedImages);
        if (sharedUris.size() == 1 && sharedMessage.equals(""))
        {
            shareIntent.putExtra(Intent.EXTRA_STREAM, sharedUris.get(0));
            addedItems = true;
        }
        else if (sharedUris.size() > 0)
        {
            shareIntent.putParcelableArrayListExtra(Intent.EXTRA_STREAM, sharedUris);
            addedItems = true;
        }

        // Explicit MIME type
        if(mimeType != null)
        {
            shareIntent.setType(mimeType);
        }
        // Mixed types
        else if (localFileUrls.size() > 0 || (sharedImages.size() > 0 && !sharedMessage.equals("")))
        {
            shareIntent.setType("*/*");
        }
        // Image only
        else if (sharedImages.size() > 0)
        {
            shareIntent.setType("image/jpeg");
        }
        // Text only
        else
        {
            shareIntent.setType("text/plain");
        }

        return addedItems;
    }

    private Uri getUriForBitmap(FREBitmapData bitmapData, int imageIndex) throws IOException, FREWrongThreadException, FREInvalidObjectException
    {
        Bitmap bmp = BitmapDataUtils.getBitmap(bitmapData);

        // Failed to generate Bitmap
        if (bmp == null)
        {
            return null;
        }

        Context ctx = AIR.getContext().getActivity().getApplicationContext();
        File cachePath = new File(ctx.getCacheDir(), SHARE_DIR);
        cachePath.mkdirs();
        File imageFile = new File(cachePath, IMAGE_NAME + imageIndex + IMAGE_EXT);
        FileOutputStream stream = new FileOutputStream(imageFile);
        bmp.compress(Bitmap.CompressFormat.JPEG, 100, stream);
        stream.close();

        return FileProvider.getUriForFile(ctx, ctx.getPackageName() + ".fileprovider", imageFile);
    }

    private void copyFile(File src, File dst) throws IOException {
        InputStream in = new FileInputStream(src);
        try {
            OutputStream out = new FileOutputStream(dst);
            try {
                // Transfer bytes from in to out
                byte[] buf = new byte[1024];
                int len;
                while ((len = in.read(buf)) > 0) {
                    out.write(buf, 0, len);
                }
            } finally {
                out.close();
            }
        } finally {
            in.close();
        }
    }

    private String getMimeType(FREObject freOptions) throws FREASErrorException, FREInvalidObjectException, FREWrongThreadException, FRENoSuchNameException, FRETypeMismatchException
    {
        if(freOptions == null) {
            return null;
        }

        return freOptions.getProperty("mimeType").getAsString();
    }

}

