package edu.unl.astro.starField
{
   import flash.events.Event;
   import flash.events.EventDispatcher;
   
   public class LinearTransferFunction extends EventDispatcher implements ITransferFunction
   {
      
      private var _peakValue:uint;
      
      private var _inverted:Boolean = false;
      
      private var _invertedTable:Array;
      
      private var _normalTable:Array;
      
      private var _lookupTable:Array;
      
      public function LinearTransferFunction()
      {
         super();
      }
      
      public function get inverted() : Boolean
      {
         return _inverted;
      }
      
      public function get peakValue() : uint
      {
         return _peakValue;
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
            _loc1_ = _loc3_ * _loc4_;
            _normalTable[_loc4_] = uint(_loc1_ << 16 | _loc1_ << 8 | _loc1_);
            _loc1_ = 255 - _loc1_;
            _invertedTable[_loc4_] = uint(_loc1_ << 16 | _loc1_ << 8 | _loc1_);
            _loc4_++;
         }
         _lookupTable = _inverted ? _invertedTable : _normalTable;
         dispatchEvent(new Event(StarField.TRANSFER_FUNCTION_CHANGED));
      }
      
      public function set peakValue(param1:uint) : void
      {
         if(isNaN(param1) || !isFinite(param1) || param1 <= 0)
         {
            return;
         }
         _peakValue = param1;
         refresh();
      }
      
      public function getColor(param1:uint) : uint
      {
         return _lookupTable[param1];
      }
      
      public function set inverted(param1:Boolean) : void
      {
         _inverted = param1;
         _lookupTable = _inverted ? _invertedTable : _normalTable;
         dispatchEvent(new Event(StarField.TRANSFER_FUNCTION_CHANGED));
      }
   }
}

