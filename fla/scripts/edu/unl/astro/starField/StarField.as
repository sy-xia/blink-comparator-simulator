package edu.unl.astro.starField
{
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import flash.utils.ByteArray;
   import flash.utils.getTimer;
   
   public class StarField extends Sprite
   {
      
      public static const TRANSFER_FUNCTION_CHANGED:String = "transferFunctionChanged";
      
      public static const STAR_CHANGED:String = "starChanged";
      
      public static const PSF_CHANGED:String = "psfChanged";
      
      public static const FIELD_CHANGED:String = "fieldChanged";
      
      private var _psf:IPSF;
      
      private var _bitDepth:uint;
      
      private var _starsList:Array;
      
      private var _chunkTable:Array;
      
      private var _locked:Boolean = false;
      
      private var _callGenerateNoisePixels:Boolean = false;
      
      private var _fieldData:Array;
      
      private var _transferFunction:ITransferFunction;
      
      private var _shuffleSeed:uint = 1;
      
      private var _peakValue:Number;
      
      private var _numChunks:int;
      
      private var _noiseData:Array;
      
      private var _callGenerateNoise:Boolean = false;
      
      private var _height:Number;
      
      private var _noiseMean:Number;
      
      private var _epoch:Number = 0;
      
      private var _fieldBMD:BitmapData;
      
      private var _fieldRect:Rectangle;
      
      private var _saturationMagnitude:Number;
      
      private var totalUpdateTime:int = 0;
      
      private var _chunkSize:int;
      
      private var _fieldBM:Bitmap;
      
      public var outOfBoundsColor:uint = 16763904;
      
      private var _noisePixels:ByteArray;
      
      private var _fieldPixels:ByteArray;
      
      private var _callShuffleNoise:Boolean = false;
      
      private var _width:Number;
      
      private var _noiseSigma:Number;
      
      private var totalUpdates:int = 0;
      
      public function StarField()
      {
         var _loc1_:Number = NaN;
         _epoch = 0;
         _shuffleSeed = 1;
         _locked = false;
         outOfBoundsColor = 16763904;
         totalUpdates = 0;
         totalUpdateTime = 0;
         _callGenerateNoise = false;
         _callGenerateNoisePixels = false;
         _callShuffleNoise = false;
         super();
         _starsList = new Array();
         _fieldData = new Array();
         _noiseData = new Array();
         _noisePixels = new ByteArray();
         _fieldPixels = new ByteArray();
         trace("\n");
         _loc1_ = getTimer();
         lock();
         dimensions = {
            "width":450,
            "height":350
         };
         bitDepth = 16;
         saturationMagnitude = 3;
         noiseMean = 0;
         noiseSigma = 1000;
         unlock();
         trace("constructor: " + (getTimer() - _loc1_) + "\n");
      }
      
      public function set noiseMean(param1:Number) : void
      {
         _noiseMean = param1;
         _callGenerateNoise = true;
         _callGenerateNoisePixels = true;
         _callShuffleNoise = true;
         update();
      }
      
      public function set epoch(param1:Number) : void
      {
         if(!isFinite(param1) || isNaN(param1))
         {
            return;
         }
         _epoch = param1;
         _shuffleSeed = 1 + 2147483646 * Math.random();
         _callShuffleNoise = true;
         update();
      }
      
      public function getStatistics(param1:IPixelMask) : Object
      {
         var _loc2_:int = 0;
         var _loc3_:int = 0;
         var _loc4_:int = 0;
         var _loc5_:int = 0;
         var _loc6_:int = 0;
         var _loc7_:int = 0;
         var _loc8_:int = 0;
         var _loc9_:Number = NaN;
         var _loc10_:Boolean = false;
         var _loc11_:uint = 0;
         var _loc12_:uint = 0;
         var _loc13_:Object = null;
         _loc10_ = false;
         _loc11_ = 0;
         _loc12_ = 0;
         _loc2_ = 0;
         while(_loc2_ < param1.width)
         {
            _loc4_ = param1.left + _loc2_;
            if(_loc4_ < 0)
            {
               _loc10_ = true;
            }
            else
            {
               if(_loc4_ >= _width)
               {
                  _loc10_ = true;
                  break;
               }
               _loc3_ = 0;
               while(_loc3_ < param1.height)
               {
                  _loc5_ = param1.top + _loc3_;
                  if(_loc5_ < 0)
                  {
                     _loc10_ = true;
                  }
                  else
                  {
                     if(_loc5_ >= _height)
                     {
                        _loc10_ = true;
                        break;
                     }
                     if(param1.data[_loc2_][_loc3_])
                     {
                        _loc6_ = _loc4_ + _loc5_ * _width;
                        _loc7_ = _loc6_ / _chunkSize;
                        _loc8_ = _loc6_ - _loc7_ * _chunkSize;
                        _loc9_ = Number(_fieldData[int(_loc8_ + _chunkSize * _chunkTable[_loc7_])]);
                        if(_loc9_ < 0)
                        {
                           _loc9_ = 0;
                        }
                        else if(_loc9_ > _peakValue)
                        {
                           _loc9_ = _peakValue;
                        }
                        _loc11_ += uint(_loc9_);
                        _loc12_++;
                     }
                  }
                  _loc3_++;
               }
            }
            _loc2_++;
         }
         _loc13_ = {};
         _loc13_.totalCounts = _loc11_;
         _loc13_.totalPixels = _loc12_;
         _loc13_.clipped = _loc10_;
         _loc13_.average = _loc13_.totalCounts / _loc13_.totalPixels;
         return _loc13_;
      }
      
      public function set locked(param1:Boolean) : void
      {
         if(param1)
         {
            lock();
         }
         else
         {
            unlock();
         }
      }
      
      public function get noiseSigma() : Number
      {
         return _noiseSigma;
      }
      
      public function get locked() : Boolean
      {
         return _locked;
      }
      
      public function lock() : void
      {
         if(_fieldBM != null)
         {
            _fieldBM.visible = false;
         }
         _locked = true;
      }
      
      public function get transferFunction() : ITransferFunction
      {
         return _transferFunction;
      }
      
      public function unlock() : void
      {
         if(_fieldBM != null)
         {
            _fieldBM.visible = true;
         }
         _locked = false;
         update();
      }
      
      public function set noiseSeed(param1:uint) : void
      {
         if(!isFinite(param1) || isNaN(param1) || param1 < 1 || param1 > 2147483646)
         {
            return;
         }
         _shuffleSeed = param1;
         _callShuffleNoise = true;
         update();
      }
      
      public function getPixelColors(param1:Rectangle) : Array
      {
         var _loc2_:Array = null;
         var _loc3_:int = 0;
         var _loc4_:int = 0;
         var _loc5_:int = 0;
         var _loc6_:int = 0;
         var _loc7_:int = 0;
         var _loc8_:int = 0;
         var _loc9_:Number = NaN;
         var _loc10_:Array = null;
         _loc2_ = [];
         _loc4_ = param1.left;
         while(_loc4_ < param1.right)
         {
            _loc10_ = [];
            if(_loc4_ < 0 || _loc4_ >= _width)
            {
               _loc3_ = 0;
               while(_loc3_ < param1.height)
               {
                  _loc10_[_loc3_] = outOfBoundsColor;
                  _loc3_++;
               }
            }
            else
            {
               _loc5_ = param1.top;
               while(_loc5_ < param1.bottom)
               {
                  if(_loc5_ < 0 || _loc5_ >= _height)
                  {
                     _loc10_.push(outOfBoundsColor);
                  }
                  else
                  {
                     _loc6_ = _loc4_ + _loc5_ * _width;
                     _loc7_ = _loc6_ / _chunkSize;
                     _loc8_ = _loc6_ - _loc7_ * _chunkSize;
                     _loc9_ = Number(_fieldData[int(_loc8_ + _chunkSize * _chunkTable[_loc7_])]);
                     if(_loc9_ < 0)
                     {
                        _loc9_ = 0;
                     }
                     else if(_loc9_ > _peakValue)
                     {
                        _loc9_ = _peakValue;
                     }
                     _loc10_.push(_transferFunction.getColor(int(_loc9_)));
                  }
                  _loc5_++;
               }
            }
            _loc2_.push(_loc10_);
            _loc4_++;
         }
         return _loc2_;
      }
      
      public function set noiseSigma(param1:Number) : void
      {
         _noiseSigma = param1;
         _callGenerateNoise = true;
         _callGenerateNoisePixels = true;
         _callShuffleNoise = true;
         update();
      }
      
      public function get saturationMagnitude() : Number
      {
         return _saturationMagnitude;
      }
      
      public function setEpochAndNoiseSeed(param1:Number, param2:uint) : void
      {
         if(!isFinite(param1) || isNaN(param1))
         {
            return;
         }
         if(!isFinite(param2) || isNaN(param2) || param2 < 1 || param2 > 2147483646)
         {
            return;
         }
         _epoch = param1;
         _shuffleSeed = param2;
         _callShuffleNoise = true;
         update();
      }
      
      private function update2(... rest) : void
      {
         _callGenerateNoisePixels = true;
         _callShuffleNoise = true;
         update();
      }
      
      public function set bitDepth(param1:uint) : void
      {
         if(param1 > 16 || param1 < 2)
         {
            return;
         }
         _bitDepth = param1;
         _peakValue = Math.pow(2,_bitDepth) - 1;
         if(_transferFunction != null)
         {
            _transferFunction.peakValue = _peakValue;
         }
      }
      
      public function getPixelInfo(param1:Point) : Object
      {
         var _loc2_:int = 0;
         var _loc3_:int = 0;
         var _loc4_:int = 0;
         var _loc5_:Number = NaN;
         if(param1.x < 0 || param1.x >= _width || param1.y < 0 || param1.y >= _height)
         {
            return {
               "counts":int(-1),
               "color":outOfBoundsColor
            };
         }
         _loc2_ = param1.x + param1.y * _width;
         _loc3_ = _loc2_ / _chunkSize;
         _loc4_ = _loc2_ - _loc3_ * _chunkSize;
         _loc5_ = Number(_fieldData[int(_loc4_ + _chunkSize * _chunkTable[_loc3_])]);
         if(_loc5_ < 0)
         {
            _loc5_ = 0;
         }
         else if(_loc5_ > _peakValue)
         {
            _loc5_ = _peakValue;
         }
         return {
            "counts":int(_loc5_),
            "color":_transferFunction.getColor(int(_loc5_))
         };
      }
      
      private function shuffleNoise() : void
      {
         var _loc1_:Number = NaN;
         var _loc2_:int = 0;
         var _loc3_:int = 0;
         var _loc4_:int = 0;
         var _loc5_:uint = 0;
         var _loc6_:int = 0;
         _loc1_ = getTimer();
         _loc5_ = _shuffleSeed;
         _loc2_ = 0;
         while(_loc2_ < _numChunks)
         {
            _chunkTable[_loc2_] = _loc2_;
            _loc2_++;
         }
         _loc2_ = 0;
         while(_loc2_ < _numChunks - 1)
         {
            _loc3_ = _loc2_ + int((_numChunks - _loc2_) * (_loc5_ / 2147483647));
            _loc5_ = _loc5_ * 16807 % 2147483647;
            _loc4_ = int(_chunkTable[_loc3_]);
            _chunkTable[_loc3_] = _chunkTable[_loc2_];
            _chunkTable[_loc2_] = _loc4_;
            _loc2_++;
         }
         _fieldPixels.position = 0;
         _loc6_ = 4 * _chunkSize;
         _loc2_ = 0;
         while(_loc2_ < _numChunks)
         {
            _noisePixels.position = _loc6_ * _chunkTable[_loc2_];
            _noisePixels.readBytes(_fieldPixels,_loc2_ * _loc6_,_loc6_);
            _loc2_++;
         }
         _callShuffleNoise = false;
         trace("shuffleNoise: " + (getTimer() - _loc1_));
      }
      
      private function generateNoisePixels() : void
      {
         var _loc1_:Number = NaN;
         var _loc2_:int = 0;
         var _loc3_:int = 0;
         var _loc4_:int = 0;
         if(_transferFunction == null)
         {
            return;
         }
         _loc1_ = getTimer();
         _loc4_ = _numChunks * _chunkSize;
         _noisePixels.position = 0;
         _loc2_ = 0;
         while(_loc2_ < _loc4_)
         {
            _loc3_ = int(_noiseData[_loc2_]);
            if(_loc3_ < 0)
            {
               _loc3_ = 0;
            }
            else if(_loc3_ > _peakValue)
            {
               _loc3_ = _peakValue;
            }
            _noisePixels.writeUnsignedInt(_transferFunction.getColor(uint(_loc3_)));
            _loc2_++;
         }
         _callGenerateNoisePixels = false;
         trace("generateNoisePixels: " + (getTimer() - _loc1_));
      }
      
      public function get noiseSeed() : uint
      {
         return _shuffleSeed;
      }
      
      private function generateNoise() : void
      {
         var _loc1_:Number = NaN;
         var _loc2_:Number = NaN;
         var _loc3_:Number = NaN;
         var _loc4_:Number = NaN;
         var _loc5_:int = 0;
         var _loc6_:int = 0;
         var _loc7_:uint = 0;
         _loc1_ = getTimer();
         _loc6_ = _numChunks * _chunkSize;
         _loc7_ = 1;
         _loc5_ = 0;
         while(_loc5_ < _loc6_)
         {
            do
            {
               _loc3_ = 2 * (_loc7_ / 2147483647) - 1;
               _loc7_ = _loc7_ * 16807 % 2147483647;
               _loc4_ = 2 * (_loc7_ / 2147483647) - 1;
               _loc7_ = _loc7_ * 16807 % 2147483647;
               _loc2_ = _loc3_ * _loc3_ + _loc4_ * _loc4_;
            }
            while(_loc2_ >= 1);
            _loc2_ = Math.sqrt(-2 * Math.log(_loc2_) / _loc2_);
            _noiseData[_loc5_] = _noiseMean + _noiseSigma * _loc3_ * _loc2_;
            var _loc8_:int;
            _noiseData[_loc8_ = ++_loc5_] = _noiseMean + _noiseSigma * _loc4_ * _loc2_;
            _loc5_++;
         }
         _callGenerateNoise = false;
         trace("generateNoise: " + (getTimer() - _loc1_));
      }
      
      public function get epoch() : Number
      {
         return _epoch;
      }
      
      public function get psf() : IPSF
      {
         return _psf;
      }
      
      public function get bitDepth() : uint
      {
         return _bitDepth;
      }
      
      private function update(... rest) : void
      {
         var _loc2_:Number = NaN;
         var _loc3_:IStar = null;
         var _loc4_:Array = null;
         var _loc5_:int = 0;
         var _loc6_:int = 0;
         var _loc7_:Number = NaN;
         var _loc8_:int = 0;
         var _loc9_:int = 0;
         var _loc10_:int = 0;
         var _loc11_:int = 0;
         var _loc12_:int = 0;
         var _loc13_:Number = NaN;
         var _loc14_:Number = NaN;
         var _loc15_:int = 0;
         var _loc16_:Number = NaN;
         var _loc17_:int = 0;
         var _loc18_:int = 0;
         if(_locked || _transferFunction == null || _psf == null)
         {
            return;
         }
         if(_callGenerateNoise)
         {
            generateNoise();
         }
         if(_callGenerateNoisePixels)
         {
            generateNoisePixels();
         }
         _loc2_ = getTimer();
         shuffleNoise();
         trace("preliminaries: " + (getTimer() - _loc2_));
         _loc2_ = getTimer();
         _fieldData = _noiseData.concat();
         _loc15_ = 0;
         while(_loc15_ < _starsList.length)
         {
            _loc3_ = _starsList[_loc15_];
            _loc3_.epoch = _epoch;
            _loc7_ = _peakValue * Math.pow(10,(_saturationMagnitude - _loc3_.magnitude) / 2.5);
            _loc5_ = _loc3_.x - _psf.x;
            _loc6_ = _loc3_.y - _psf.y;
            _loc17_ = 0;
            while(_loc17_ < _psf.width)
            {
               _loc8_ = _loc5_ + _loc17_;
               if(_loc8_ >= 0)
               {
                  if(_loc8_ >= _width)
                  {
                     break;
                  }
                  _loc4_ = _psf.data[_loc17_];
                  _loc18_ = 0;
                  while(_loc18_ < _psf.height)
                  {
                     _loc9_ = _loc6_ + _loc18_;
                     _loc13_ = Number(_loc4_[_loc18_]);
                     if(!(_loc13_ <= 0 || _loc9_ < 0))
                     {
                        if(_loc9_ >= _height)
                        {
                           break;
                        }
                        _loc10_ = _loc8_ + _loc9_ * _width;
                        _loc11_ = _loc10_ / _chunkSize;
                        _loc12_ = _loc10_ - _loc11_ * _chunkSize;
                        _loc14_ = Number(_fieldData[int(_loc12_ + _chunkSize * _chunkTable[_loc11_])] = _fieldData[int(_loc12_ + _chunkSize * _chunkTable[_loc11_])] + _loc7_ * _loc13_);
                        if(_loc14_ < 0)
                        {
                           _loc14_ = 0;
                        }
                        else if(_loc14_ > _peakValue)
                        {
                           _loc14_ = _peakValue;
                        }
                        _fieldPixels.position = 4 * _loc10_;
                        _fieldPixels.writeUnsignedInt(_transferFunction.getColor(uint(_loc14_)));
                     }
                     _loc18_++;
                  }
               }
               _loc17_++;
            }
            _loc15_++;
         }
         _fieldPixels.position = 0;
         _fieldBMD.setPixels(_fieldRect,_fieldPixels);
         _loc16_ = getTimer() - _loc2_;
         totalUpdateTime += _loc16_;
         ++totalUpdates;
         trace("update: " + _loc16_);
         trace("average: " + totalUpdateTime / totalUpdates);
         dispatchEvent(new Event(StarField.FIELD_CHANGED));
      }
      
      public function set transferFunction(param1:ITransferFunction) : void
      {
         if(_transferFunction != null)
         {
            _transferFunction.removeEventListener(StarField.TRANSFER_FUNCTION_CHANGED,update2);
         }
         _transferFunction = param1;
         _transferFunction.peakValue = _peakValue;
         _transferFunction.addEventListener(StarField.TRANSFER_FUNCTION_CHANGED,update2);
         update2();
      }
      
      public function get peakValue() : uint
      {
         return _peakValue;
      }
      
      public function set dimensions(param1:Object) : void
      {
         if(!(param1.width is Number) || !(param1.height is Number) || !isFinite(param1.width) || isNaN(param1.width) || !isFinite(param1.height) || isNaN(param1.height) || param1.width == 0 || param1.width > 2000 || param1.height == 0 || param1.height > 2000)
         {
            return;
         }
         _width = uint(param1.width);
         _height = uint(param1.height);
         if(_fieldBM != null)
         {
            removeChild(_fieldBM);
         }
         _fieldBMD = new BitmapData(_width,_height,false,16711680);
         _fieldBM = new Bitmap(_fieldBMD);
         addChild(_fieldBM);
         _fieldRect = new Rectangle(0,0,_width,_height);
         _numChunks = 0.7 * _width;
         _chunkSize = Math.ceil(_width * _height / _numChunks);
         if(_chunkSize % 2 == 1)
         {
            _chunkSize += 1;
         }
         _chunkTable = new Array(_numChunks);
         _callGenerateNoise = true;
         _callGenerateNoisePixels = true;
         _callShuffleNoise = true;
         update();
      }
      
      public function get dimensions() : Object
      {
         return {
            "width":_width,
            "height":_height
         };
      }
      
      public function addStar(param1:IStar) : void
      {
         param1.addEventListener(StarField.STAR_CHANGED,update);
         _starsList.push(param1);
         update();
      }
      
      public function set psf(param1:IPSF) : void
      {
         if(_psf != null)
         {
            _psf.removeEventListener(StarField.PSF_CHANGED,update);
         }
         _psf = param1;
         _psf.addEventListener(StarField.PSF_CHANGED,update);
         update();
      }
      
      public function set saturationMagnitude(param1:Number) : void
      {
         if(!isFinite(param1) || isNaN(param1))
         {
            return;
         }
         _saturationMagnitude = param1;
         update();
      }
      
      public function removeAllStars() : void
      {
         var _loc1_:int = 0;
         _loc1_ = 0;
         while(_loc1_ < _starsList.length)
         {
            _starsList[_loc1_].removeEventListener(StarField.STAR_CHANGED,update);
            _loc1_++;
         }
         _starsList = [];
         update();
      }
      
      public function removeStar(param1:IStar) : Boolean
      {
         var _loc2_:int = 0;
         _loc2_ = 0;
         while(_loc2_ < _starsList.length)
         {
            if(param1 == _starsList[_loc2_])
            {
               param1.removeEventListener(StarField.STAR_CHANGED,update);
               _starsList.splice(_loc2_,1);
               update();
               return true;
            }
            _loc2_++;
         }
         return false;
      }
      
      public function get noiseMean() : Number
      {
         return _noiseMean;
      }
   }
}

