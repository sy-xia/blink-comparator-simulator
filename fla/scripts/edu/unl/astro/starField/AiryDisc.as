package edu.unl.astro.starField
{
   import flash.events.Event;
   import flash.events.EventDispatcher;
   
   public class AiryDisc extends EventDispatcher implements IPSF
   {
      
      protected var _data:Array;
      
      protected var _size:uint;
      
      protected var _radius:uint;
      
      protected var _center:int;
      
      public function AiryDisc(param1:uint = 6)
      {
         super();
         radius = param1;
      }
      
      public function get y() : int
      {
         return _center;
      }
      
      public function get radius() : uint
      {
         return _radius;
      }
      
      public function reset() : void
      {
         var _loc1_:int = 0;
         var _loc2_:int = 0;
         var _loc3_:Number = NaN;
         var _loc4_:Number = NaN;
         var _loc5_:Number = NaN;
         var _loc6_:Number = NaN;
         var _loc7_:Number = NaN;
         var _loc8_:Number = NaN;
         _data = [];
         _loc8_ = 3.831705970256774 / _radius;
         _loc1_ = 0;
         while(_loc1_ < _size)
         {
            _data[_loc1_] = [];
            _loc1_++;
         }
         _loc1_ = 0;
         while(_loc1_ < _radius)
         {
            _loc5_ = _loc8_ * _loc1_;
            _loc2_ = 0;
            while(_loc2_ <= _loc1_)
            {
               _loc6_ = _loc8_ * _loc2_;
               _loc3_ = _loc5_ * _loc5_ + _loc6_ * _loc6_;
               if(_loc3_ >= 14.681970642501405)
               {
                  _loc7_ = 0;
               }
               else
               {
                  _loc4_ = getJ1(Math.sqrt(_loc3_));
                  _loc7_ = 4 * _loc4_ * _loc4_ / _loc3_;
               }
               _data[_center + _loc1_][_center - _loc2_] = _loc7_;
               _data[_center + _loc2_][_center - _loc1_] = _loc7_;
               _data[_center - _loc2_][_center - _loc1_] = _loc7_;
               _data[_center - _loc1_][_center - _loc2_] = _loc7_;
               _data[_center - _loc1_][_center + _loc2_] = _loc7_;
               _data[_center - _loc2_][_center + _loc1_] = _loc7_;
               _data[_center + _loc2_][_center + _loc1_] = _loc7_;
               _data[_center + _loc1_][_center + _loc2_] = _loc7_;
               _loc2_++;
            }
            _loc1_++;
         }
         _data[_center][_center] = 1;
         dispatchEvent(new Event(StarField.PSF_CHANGED));
      }
      
      public function get width() : uint
      {
         return _size;
      }
      
      public function set epoch(param1:Number) : void
      {
      }
      
      public function set radius(param1:uint) : void
      {
         if(param1 < 2)
         {
            return;
         }
         _radius = param1;
         _center = _radius - 1;
         _size = 2 * _radius - 1;
         reset();
      }
      
      public function get height() : uint
      {
         return _size;
      }
      
      public function get data() : Array
      {
         return _data;
      }
      
      public function get x() : int
      {
         return _center;
      }
      
      protected function getJ1(param1:Number) : Number
      {
         var _loc2_:Number = NaN;
         var _loc3_:Number = NaN;
         var _loc4_:Number = NaN;
         var _loc5_:Number = NaN;
         var _loc6_:Number = NaN;
         var _loc7_:Number = NaN;
         var _loc8_:Number = NaN;
         _loc6_ = Math.abs(param1);
         if(_loc6_ < 8)
         {
            _loc2_ = param1 * param1;
            _loc3_ = param1 * (72362614232 + _loc2_ * (-7895059235 + _loc2_ * (242396853.1 + _loc2_ * (-2972611.439 + _loc2_ * (15704.4826 + _loc2_ * -30.16036606)))));
            _loc4_ = 144725228442 + _loc2_ * (2300535178 + _loc2_ * (18583304.74 + _loc2_ * (99447.43394 + _loc2_ * (376.9991397 + _loc2_ * 1))));
            _loc5_ = _loc3_ / _loc4_;
         }
         else
         {
            _loc7_ = 8 / _loc6_;
            _loc2_ = _loc7_ * _loc7_;
            _loc8_ = _loc6_ - 2.356194491;
            _loc3_ = 1 + _loc2_ * (0.00183105 + _loc2_ * (-0.00003516396496 + _loc2_ * (0.000002457520174 + _loc2_ * -2.40337019e-7)));
            _loc4_ = 0.04687499995 + _loc2_ * (-0.0002002690873 + _loc2_ * (0.000008449199096 + _loc2_ * (-8.8228987e-7 + _loc2_ * 1.05787412e-7)));
            _loc5_ = Math.sqrt(0.636619772 / _loc6_) * (Math.cos(_loc8_) * _loc3_ - _loc7_ * Math.sin(_loc8_) * _loc4_);
            if(param1 < 0)
            {
               _loc5_ = -_loc5_;
            }
         }
         return _loc5_;
      }
   }
}

