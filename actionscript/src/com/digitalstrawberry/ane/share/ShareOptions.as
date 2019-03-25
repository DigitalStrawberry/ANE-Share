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
	import flash.geom.Rectangle;
	
	public class ShareOptions
	{
		public static const ARROW_NONE:int = 0;
		public static const ARROW_UP:int = 1;
		public static const ARROW_DOWN:int = 2;
		public static const ARROW_LEFT:int = 4;
		public static const ARROW_RIGHT:int = 8;
		public static const ARROW_ANY:int = ARROW_UP | ARROW_DOWN | ARROW_LEFT | ARROW_RIGHT;

		private var mPosition:Rectangle;
		private var mArrowDirection:int = ARROW_ANY;
		private var mMimeType:String = null;

		
		public function ShareOptions()
		{
			mPosition = new Rectangle();
		}


		/**
		 * @private
		 */
		internal static function get defaults():ShareOptions
		{
			return new ShareOptions();
		}


		/**
		 *
		 *
		 * Getters / Setters
		 *
		 *
		 */


		public function get position():Rectangle
		{
			return mPosition;
		}


		public function set position(value:Rectangle):void
		{
			mPosition = value;
		}


		public function get arrowDirection():int
		{
			return mArrowDirection;
		}


		public function set arrowDirection(value:int):void
		{
			mArrowDirection = value;
		}
		
		
		/**
		 * Sets an explicit MIME data type (Android only).
		 */
		public function get mimeType():String
		{
			return mMimeType;
		}
		
		
		/**
		 * @private
		 */
		public function set mimeType(value:String):void
		{
			mMimeType = value;
		}
	}
	
}
