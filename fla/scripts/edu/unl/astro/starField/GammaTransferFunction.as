package edu.unl.astro.starField
{
   import flash.events.Event;
   import flash.events.EventDispatcher;
   
   public class GammaTransferFunction extends EventDispatcher implements ITransferFunction
   {
      
      protected var _highlightSaturatedPixels:Boolean = false;
      
      protected var _peakValue:uint;
      
      protected var _inverted:Boolean = false;
      
      protected var _invertedTable:Array;
      
      protected var _normalTable:Array;
      
      protected var _highlightColor:uint = 16711680;
      
      protected var _gamma:Number = 1.8;
      
      protected var _lookupTable:Array;
      
      public function GammaTransferFunction()
      {
         super();
      }
      
      public function get inverted() : Boolean
      {
         return _inverted;
      }
      
      protected function updateHighlightingOfSaturatedPixels() : void
      {
         if(_highlightSaturatedPixels)
         {
            _invertedTable[_peakValue] = _highlightColor;
            _normalTable[_peakValue] = _highlightColor;
         }
         else
         {
            _invertedTable[_peakValue] = 0;
            _normalTable[_peakValue] = 16777215;
         }
         dispatchEvent(new Event(StarField.TRANSFER_FUNCTION_CHANGED));
      }
      
      public function get peakValue() : uint
      {
         return _peakValue;
      }
      
      public function get highlightColor() : uint
      {
         return _highlightColor;
      }
      
      public function refresh() : void
      {
         var _loc1_:int = 0;
         var _loc2_:int = 0;
         var _loc3_:Number = NaN;
         var _loc4_:int = 0;
         _loc2_ = _peakValue + 1;
         _loc3_ = 255 / _peakValue;
         _normalTable = [];
         _invertedTable = [];
         _loc4_ = 0;
         while(_loc4_ < _loc2_)
         {
            _loc1_ = 255 * Math.pow(_loc4_ / _peakValue,1 / _gamma);
            _normalTable[_loc4_] = uint(_loc1_ << 16 | _loc1_ << 8 | _loc1_);
            _loc1_ = 255 - _loc1_;
            _invertedTable[_loc4_] = uint(_loc1_ << 16 | _loc1_ << 8 | _loc1_);
            _loc4_++;
         }
         _lookupTable = _inverted ? _invertedTable : _normalTable;
         updateHighlightingOfSaturatedPixels();
      }
      
      public function get highlightSaturatedPixels() : Boolean
      {
         return _highlightSaturatedPixels;
      }
      
      public function set highlightColor(param1:uint) : void
      {
         _highlightColor = param1;
         updateHighlightingOfSaturatedPixels();
      }
      
      public function set highlightSaturatedPixels(param1:Boolean) : void
      {
         _highlightSaturatedPixels = param1;
         updateHighlightingOfSaturatedPixels();
      }
      
      public function set peakValue(param1:uint) : void
      {
         if(isNaN(param1) || !isFinite(param1) || param1 <= 0 || _peakValue == param1)
         {
            return;
         }
         _peakValue = param1;
         refresh();
      }
      
      public function get gamma() : Number
      {
         return _gamma;
      }
      
      public function getColor(param1:uint) : uint
      {
         return _lookupTable[param1];
      }
      
      public function set gamma(param1:Number) : *
      {
         if(isNaN(param1) || !isFinite(param1) || param1 <= 0)
         {
            return;
         }
         _gamma = param1;
         refresh();
      }
      
      public function set inverted(param1:Boolean) : void
      {
         _inverted = param1;
         _lookupTable = _inverted ? _invertedTable : _normalTable;
         dispatchEvent(new Event(StarField.TRANSFER_FUNCTION_CHANGED));
      }
   }
}

