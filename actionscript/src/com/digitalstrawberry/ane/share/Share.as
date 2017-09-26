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

	import com.digitalstrawberry.ane.share.events.ShareEvent;

	import flash.errors.IllegalOperationError;
	import flash.events.EventDispatcher;
	import flash.events.StatusEvent;

	CONFIG::ane
	{
		import flash.external.ExtensionContext;
	}

	import flash.system.Capabilities;
	import flash.utils.Dictionary;

	public class Share extends EventDispatcher
	{

		private static const TAG:String = "[Share]";
		private static const EXTENSION_ID:String = "com.digitalstrawberry.ane.share";
		private static const iOS:Boolean = Capabilities.manufacturer.indexOf("iOS") > -1;
		private static const ANDROID:Boolean = Capabilities.manufacturer.indexOf("Android") > -1;

		private static var mInstance:Share;
		private static var mCanInitialize:Boolean;

		private var mLastSharedData:Vector.<SharedData>;

		CONFIG::ane
		{
			private static var mContext:ExtensionContext;
		}


		/**
		 * @private
		 */
		public function Share()
		{
			if(!mCanInitialize)
			{
				throw new Error("Share is a singleton.");
			}
			mInstance = this;
		}


		/**
		 *
		 *
		 * Public API
		 *
		 *
		 */


		/**
		 * Returns the Share extension singleton.
		 */
		public static function get instance():Share
		{
			if(mInstance == null)
			{
				mCanInitialize = true;
				mInstance = new Share();
				mCanInitialize = false;
			}
			return mInstance;
		}


		/**
		 *
		 *
		 * @param data
		 * @param options
		 */
		public function share(data:Vector.<SharedData>, options:ShareOptions = null):void
		{
			if(!isSupported)
			{
				return;
			}

			if(data == null)
			{
				throw new ArgumentError("Parameter data cannot be null.");
			}

			if(data.length == 0)
			{
				throw new IllegalOperationError("No data to be shared.");
			}
			
			if(options == null)
			{
				options = ShareOptions.defaults;
			}

			CONFIG::ane
			{
				mLastSharedData = data;
				mContext.addEventListener(StatusEvent.STATUS, onStatus);
			    mContext.call( "share", data, options );
			}
		}


		/**
		 * Disposes native extension context.
		 */
		public function dispose():void
		{
			if(!isSupported)
			{
				return;
			}

			CONFIG::ane
			{
				mContext.removeEventListener(StatusEvent.STATUS, onStatus);
				mContext.dispose();
				mContext = null;
			}
		}


		/**
		 *
		 *
		 * Getters / Setters
		 *
		 *
		 */

		/**
		 * Extension version.
		 */
		public static function get version():String
		{
			return "1.0.1";
		}


		/**
		 * Supported on iOS 8+ and Android 4+.
		 */
		public static function get isSupported():Boolean
		{
			if(!isSupportedPlatform || !initExtensionContext())
			{
				return false;
			}

			var result:Boolean;
			CONFIG::ane
			{
				result = mContext.call("isSupported") as Boolean;
			}
			return result;
		}


		/**
		 *
		 *
		 * Private API
		 *
		 *
		 */


		private function onStatus(event:StatusEvent):void
		{
			switch(event.code)
			{
				case ShareEvent.COMPLETE:
						mLastSharedData = null;
						dispatchEvent(new ShareEvent(ShareEvent.COMPLETE, event.level));
					return;

				case ShareEvent.CANCEL:
						mLastSharedData = null;
						dispatchEvent(new ShareEvent(ShareEvent.CANCEL, event.level));
					return;

				case ShareEvent.ERROR:
						mLastSharedData = null;
						dispatchEvent(new ShareEvent(ShareEvent.ERROR));
					return;
			}
		}


		/**
		 * Supported on iOS and Android.
		 */
		private static function get isSupportedPlatform():Boolean
		{
			return iOS || ANDROID;
		}


		/**
		 * Initializes extension context.
		 * @return <code>true</code> if initialized successfully, <code>false</code> otherwise.
		 */
		private static function initExtensionContext():Boolean
		{
			CONFIG::ane
			{
				if(mContext === null)
				{
					try
					{
						mContext = ExtensionContext.createExtensionContext(EXTENSION_ID, null);
					}
					catch(e:Error)
					{
						trace(TAG, "Error creating extension context for", EXTENSION_ID);
						return false;
					}
				}
				return mContext !== null;
			}
			return false;
		}

	}
}
