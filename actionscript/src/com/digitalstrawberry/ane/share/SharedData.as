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

package com.digitalstrawberry.ane.share
{
	import flash.display.BitmapData;

	public class SharedData
	{
		private var mData:* = null;
		private var mShareWithFacebook:Boolean = true;

		/**
		 * Creates new data to be shared.
		 *
		 * @param data The actual data to be shared. Must be either a String or BitmapData.
		 */
		public function SharedData(data:*)
		{
			if(!(data is String || data is BitmapData))
			{
				throw new ArgumentError("Parameter data must be either a String or BitmapData.");
			}

			mData = data;
		}


		/**
		 * Returns the actual data to be shared.
		 */
		public function get data():*
		{
			return mData;
		}
		

		/**
		 * Determines whether the data will be provided when sharing via Facebook on iOS.
		 *
		 * @default true
		 */
		public function get shareWithFacebook():Boolean
		{
			return mShareWithFacebook;
		}


		/**
		 * @private
		 */
		public function set shareWithFacebook(value:Boolean):void
		{
			mShareWithFacebook = value;
		}
	}
	
}
