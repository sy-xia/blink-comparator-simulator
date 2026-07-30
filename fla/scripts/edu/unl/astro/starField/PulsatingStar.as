package edu.unl.astro.starField
{
   public final class PulsatingStar extends Star
   {
      
      public static const COSINE:* = "cos";
      
      public static const SINE:* = "sin";
      
      public static const PRESETS:Object = {
         "del_Cep":{
            "period":5.366341,
            "functionUsed":PulsatingStar.COSINE,
            "actualCenterMagnitude":3.988,
            "fourierTermsList":[{
               "A":0.3496,
               "phi":2.491
            },{
               "A":0.1385,
               "phi":3.084
            },{
               "A":0.05499,
               "phi":3.811
            },{
               "A":0.02277,
               "phi":4.083
            },{
               "A":0.009765,
               "phi":4.709
            }]
         },
         "RT_Mus":{
            "period":3.08617,
            "functionUsed":PulsatingStar.COSINE,
            "actualCenterMagnitude":9.03,
            "fourierTermsList":[{
               "A":0.331,
               "phi":0.0277
            },{
               "A":0.131,
               "phi":4.13
            },{
               "A":0.0503,
               "phi":2.24
            },{
               "A":0.0416,
               "phi":6.16
            }]
         },
         "AS_Per":{
            "period":4.972516,
            "functionUsed":PulsatingStar.COSINE,
            "actualCenterMagnitude":9.76,
            "fourierTermsList":[{
               "A":0.3583,
               "phi":2.468
            },{
               "A":0.1443,
               "phi":3.084
            },{
               "A":0.05731,
               "phi":3.65
            },{
               "A":0.02603,
               "phi":3.695
            },{
               "A":0.0211,
               "phi":4.625
            }]
         },
         "S_Nor":{
            "period":9.75411,
            "functionUsed":PulsatingStar.COSINE,
            "actualCenterMagnitude":6.4354,
            "fourierTermsList":[{
               "A":0.2874,
               "phi":3.1842
            },{
               "A":0.0191,
               "phi":4.6142
            },{
               "A":0.0296,
               "phi":2.7042
            },{
               "A":0.0144,
               "phi":3.3482
            },{
               "A":0.018,
               "phi":3.0182
            },{
               "A":0.0159,
               "phi":3.4322
            }]
         },
         "PZ_Aql":{
            "period":8.7513,
            "functionUsed":PulsatingStar.COSINE,
            "actualCenterMagnitude":11.7,
            "fourierTermsList":[{
               "A":0.365,
               "phi":4.66
            },{
               "A":0.0459,
               "phi":1.75
            },{
               "A":0.0208,
               "phi":2.76
            },{
               "A":0.0188,
               "phi":5.98
            }]
         },
         "MT_Tel":{
            "period":0.316897,
            "functionUsed":PulsatingStar.COSINE,
            "actualCenterMagnitude":9.01,
            "fourierTermsList":[{
               "A":0.26,
               "phi":1.93
            },{
               "A":0.0735,
               "phi":1.89
            },{
               "A":0.0166,
               "phi":1.85
            },{
               "A":0.01,
               "phi":1.95
            },{
               "A":0.0056,
               "phi":1.35
            },{
               "A":0.00489,
               "phi":1.48
            },{
               "A":0.00453,
               "phi":1.62
            },{
               "A":0.00151,
               "phi":1.11
            }]
         },
         "RR_Leo":{
            "period":0.4523933,
            "functionUsed":PulsatingStar.COSINE,
            "actualCenterMagnitude":10.83,
            "fourierTermsList":[{
               "A":0.455,
               "phi":0.691
            },{
               "A":0.228,
               "phi":5.16
            },{
               "A":0.161,
               "phi":3.69
            },{
               "A":0.0991,
               "phi":2.33
            },{
               "A":0.0779,
               "phi":1.02
            },{
               "A":0.0491,
               "phi":5.81
            },{
               "A":0.0327,
               "phi":4.45
            },{
               "A":0.0314,
               "phi":2.97
            }]
         },
         "VX_Her":{
            "period":0.45537282,
            "functionUsed":PulsatingStar.COSINE,
            "actualCenterMagnitude":10.78,
            "fourierTermsList":[{
               "A":0.458,
               "phi":4.51
            },{
               "A":0.212,
               "phi":0.261
            },{
               "A":0.164,
               "phi":2.56
            },{
               "A":0.106,
               "phi":4.96
            },{
               "A":0.0733,
               "phi":1.07
            },{
               "A":0.0592,
               "phi":3.57
            },{
               "A":0.0362,
               "phi":6.07
            },{
               "A":0.027,
               "phi":2.2
            }]
         }
      };
      
      private var _functionUsed:String = PulsatingStar.COSINE;
      
      private var _fourierTermsList:Array = [];
      
      private var _phaseOffset:Number = 0;
      
      private var _period:Number = 3;
      
      private var _centerMagnitude:Number = 0;
      
      public function PulsatingStar(... rest)
      {
         super();
         if(rest.length > 0)
         {
            loadSettingsFromObjectsList(rest);
         }
      }
      
      public function set period(param1:Number) : void
      {
         if(!isFinite(param1) || isNaN(param1) || param1 <= 0)
         {
            return;
         }
         _period = param1;
         if(_callUpdate)
         {
            update();
         }
      }
      
      override public function get magnitude() : Number
      {
         var _loc1_:Function = null;
         var _loc2_:Number = NaN;
         var _loc3_:Number = NaN;
         var _loc4_:int = 0;
         _loc1_ = Math[_functionUsed];
         _loc2_ = _centerMagnitude;
         _loc3_ = 2 * Math.PI * (epoch - _phaseOffset) / _period;
         _loc4_ = 0;
         while(_loc4_ < _fourierTermsList.length)
         {
            _loc2_ += _fourierTermsList[_loc4_].A * _loc1_((_loc4_ + 1) * _loc3_ + _fourierTermsList[_loc4_].phi);
            _loc4_++;
         }
         return _loc2_;
      }
      
      override public function set magnitude(param1:Number) : void
      {
         throw new Error("magnitude is read-only for an instance of PulsatingStar");
      }
      
      public function get functionUsed() : String
      {
         return _functionUsed;
      }
      
      public function get centerMagnitude() : Number
      {
         return _centerMagnitude;
      }
      
      public function get fourierTermsList() : Array
      {
         var _loc1_:Array = null;
         var _loc2_:int = 0;
         _loc1_ = [];
         _loc2_ = 0;
         while(_loc2_ < _fourierTermsList.length)
         {
            _loc1_[_loc2_] = {
               "A":_fourierTermsList[_loc2_].A,
               "phi":_fourierTermsList[_loc2_].phi
            };
            _loc2_++;
         }
         return _loc1_;
      }
      
      public function get period() : Number
      {
         return _period;
      }
      
      public function set phaseOffset(param1:Number) : void
      {
         if(!isFinite(param1) || isNaN(param1))
         {
            return;
         }
         _phaseOffset = param1;
         if(_callUpdate)
         {
            update();
         }
      }
      
      override protected function loadSettingsFromObjectsList(param1:*) : void
      {
         var _loc2_:Object = null;
         var _loc3_:int = 0;
         _callUpdate = false;
         _loc3_ = 0;
         while(_loc3_ < param1.length)
         {
            if(param1[_loc3_] is Object)
            {
               _loc2_ = param1[_loc3_];
               if(_loc2_.x is Number)
               {
                  x = _loc2_.x;
               }
               if(_loc2_.y is Number)
               {
                  y = _loc2_.y;
               }
               if(_loc2_.phaseOffset is Number)
               {
                  phaseOffset = _loc2_.phaseOffset;
               }
               if(_loc2_.period is Number)
               {
                  period = _loc2_.period;
               }
               if(_loc2_.functionUsed is String)
               {
                  functionUsed = _loc2_.functionUsed;
               }
               if(_loc2_.centerMagnitude is Number)
               {
                  centerMagnitude = _loc2_.centerMagnitude;
               }
               if(_loc2_.fourierTermsList is Array)
               {
                  fourierTermsList = _loc2_.fourierTermsList;
               }
            }
            _loc3_++;
         }
         _callUpdate = true;
         update();
      }
      
      public function set functionUsed(param1:String) : void
      {
         if(param1 != PulsatingStar.COSINE && param1 != PulsatingStar.SINE)
         {
            return;
         }
         _functionUsed = param1;
         if(_callUpdate)
         {
            update();
         }
      }
      
      public function get phaseOffset() : Number
      {
         return _phaseOffset;
      }
      
      public function set fourierTermsList(param1:Array) : void
      {
         var _loc2_:Object = null;
         var _loc3_:Array = null;
         var _loc4_:int = 0;
         _loc3_ = [];
         _loc4_ = 0;
         while(_loc4_ < param1.length)
         {
            _loc2_ = {};
            _loc2_.A = param1[_loc4_].A;
            _loc2_.phi = param1[_loc4_].phi;
            if(!(_loc2_.A is Number) || isNaN(_loc2_.A) || !isFinite(_loc2_.A) || !(_loc2_.phi is Number) || isNaN(_loc2_.phi) || !isFinite(_loc2_.phi))
            {
               break;
            }
            _loc3_[_loc4_] = _loc2_;
            _loc4_++;
         }
         _fourierTermsList = _loc3_;
         if(_callUpdate)
         {
            update();
         }
      }
      
      public function set centerMagnitude(param1:Number) : void
      {
         if(!isFinite(param1) || isNaN(param1))
         {
            return;
         }
         _centerMagnitude = param1;
         if(_callUpdate)
         {
            update();
         }
      }
   }
}

