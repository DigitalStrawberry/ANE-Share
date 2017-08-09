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

package com.digitalstrawberry.ane.share.utils;

import android.graphics.*;
import com.adobe.fre.FREBitmapData;
import com.adobe.fre.FREInvalidObjectException;
import com.adobe.fre.FREWrongThreadException;

public class BitmapDataUtils {

	private static final float[] mBGRToRGBColorTransform =
			{
					0, 0, 1f, 0, 0,
					0, 1f, 0, 0, 0,
					1f, 0, 0, 0, 0,
					0, 0, 0, 1f, 0
			};
	private static final ColorMatrixColorFilter mColorFilter = new ColorMatrixColorFilter(
			new ColorMatrix( mBGRToRGBColorTransform )
	);

	/**
	 * Switch color channels
	 * http://stackoverflow.com/questions/17314467/bitmap-channels-order-different-in-android
	 */
	public static Bitmap getBitmap( FREBitmapData bitmapData ) throws FREWrongThreadException, FREInvalidObjectException {
		bitmapData.acquire();
		Bitmap bitmap = Bitmap.createBitmap( bitmapData.getWidth(), bitmapData.getHeight(), Bitmap.Config.ARGB_8888 );
		Canvas canvas = new Canvas( bitmap );
		Paint paint = new Paint();
		paint.setColorFilter( mColorFilter );
		bitmap.copyPixelsFromBuffer( bitmapData.getBits() );
		bitmapData.release();
		canvas.drawBitmap( bitmap, 0, 0, paint );
		return bitmap;
	}

}
