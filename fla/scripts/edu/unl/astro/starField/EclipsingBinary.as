package edu.unl.astro.starField
{
   public final class EclipsingBinary extends Star
   {
      
      public static const SOLAR_MASS:Number = 1.98892e+30;
      
      public static const SOLAR_RADIUS:Number = 695500000;
      
      public static const PRESETS:Object = {
         "TW_Cas":{
            "argument":0,
            "inclination":74.7,
            "eccentricity":0,
            "separation":8.17,
            "mass1":2.5,
            "radius1":2,
            "temperature1":10500,
            "mass2":1.1,
            "radius2":2.6,
            "temperature2":5400
         },
         "AG_Phi":{
            "argument":0,
            "inclination":87.624,
            "eccentricity":0,
            "separation":4.22,
            "mass1":1.53,
            "radius1":1.7,
            "temperature1":7500,
            "mass2":0.24,
            "radius2":1,
            "temperature2":5400
         },
         "V477_Cyg":{
            "argument":162.8,
            "inclination":85.66,
            "eccentricity":0.33,
            "separation":10.87,
            "mass1":1.9,
            "radius1":1.7,
            "temperature1":8730,
            "mass2":1.4,
            "radius2":1.5,
            "temperature2":6530
         },
         "CW_CMa":{
            "argument":0,
            "inclination":83.3,
            "eccentricity":0,
            "separation":11.92,
            "mass1":2.6,
            "radius1":2.1,
            "temperature1":10800,
            "mass2":2.5,
            "radius2":1.9,
            "temperature2":10300
         },
         "EK_Cep":{
            "argument":49.8,
            "inclination":89.16,
            "eccentricity":0.11,
            "separation":16.58,
            "mass1":2,
            "radius1":1.6,
            "temperature1":9000,
            "mass2":1.1,
            "radius2":1.3,
            "temperature2":5690
         },
         "V526_Sgr":{
            "argument":254.8,
            "inclination":87.3,
            "eccentricity":0.22,
            "separation":10.43,
            "mass1":2.4,
            "radius1":1.9,
            "temperature1":10100,
            "mass2":1.8,
            "radius2":1.6,
            "temperature2":8450
         },
         "T_LMi":{
            "argument":0,
            "inclination":86.3,
            "eccentricity":0,
            "separation":11.97,
            "mass1":2.3,
            "radius1":1.9,
            "temperature1":9860,
            "mass2":0.23,
            "radius2":2.4,
            "temperature2":5060
         }
      };
      
      private var _peakMagnitude:Number = 0;
      
      private var _argument:Number = 162.8 * (Math.PI / 180);
      
      private var _temperature2:Number = 6530;
      
      private var _inclination:Number = 85.66 * (Math.PI / 180);
      
      private var _temperature1:Number = 8730;
      
      private var _phaseOffset:Number = 0;
      
      private var _R12:Number;
      
      private var _R22:Number;
      
      private var _distanceModulus:Number;
      
      private var _H1:Number;
      
      private var _H2:Number;
      
      private var _minVisMag:Number;
      
      private var _radius1:Number = 1.7 * EclipsingBinary.SOLAR_RADIUS;
      
      private var _radius2:Number = 1.5 * EclipsingBinary.SOLAR_RADIUS;
      
      private var _Z0:Number;
      
      private var _Z1:Number;
      
      private var _Z2:Number;
      
      private var _Z3:Number;
      
      private var _mass1:Number = 1.9 * EclipsingBinary.SOLAR_MASS;
      
      private var _mass2:Number = 1.4 * EclipsingBinary.SOLAR_MASS;
      
      private var _maxVisFlux:Number;
      
      private var _J1:Number;
      
      private var _eccentricity:Number = 0.33;
      
      private var _J3:Number;
      
      private var _J2:Number;
      
      private var _J4:Number;
      
      private var _period:Number;
      
      private var _separation:Number = 10.87 * EclipsingBinary.SOLAR_RADIUS;
      
      private var _C1:Number;
      
      public function EclipsingBinary(... rest)
      {
         super();
         if(rest.length > 0)
         {
            loadSettingsFromObjectsList(rest);
         }
      }
      
      override public function get magnitude() : Number
      {
         var _loc1_:Number = NaN;
         var _loc2_:Number = NaN;
         var _loc3_:Number = NaN;
         var _loc4_:int = 0;
         var _loc5_:Number = NaN;
         var _loc6_:Number = NaN;
         var _loc7_:Number = NaN;
         var _loc8_:Number = NaN;
         var _loc9_:Number = NaN;
         var _loc10_:Number = NaN;
         var _loc11_:Number = NaN;
         var _loc12_:Number = NaN;
         var _loc13_:Number = NaN;
         var _loc14_:Boolean = false;
         var _loc15_:Number = NaN;
         var _loc16_:Number = NaN;
         _loc1_ = 2 * Math.PI * (epoch - _phaseOffset) / _period;
         _loc2_ = 0;
         _loc3_ = _loc1_;
         _loc4_ = 0;
         do
         {
            _loc2_ = _loc3_;
            _loc3_ = _loc2_ + (_loc1_ + _eccentricity * Math.sin(_loc2_) - _loc2_) / (1 - _eccentricity * Math.cos(_loc2_));
            _loc4_++;
         }
         while(Math.abs(_loc3_ - _loc2_) > 0.001 && _loc4_ < 100);
         if(_loc4_ >= 100)
         {
            throw new Error("iteration limit reached in EclipsingBinary, maybe eccentricity is too high");
         }
         _loc5_ = 2 * Math.atan(_C1 * Math.tan(_loc3_ / 2));
         _loc6_ = Math.cos(_loc5_);
         _loc7_ = Math.cos(_loc5_ + _argument);
         _loc8_ = Math.sqrt((_J1 * _loc7_ * _loc7_ + _J2) / (1 + _J3 * _loc6_ + _J4 * _loc6_ * _loc6_));
         if(_loc8_ == 0)
         {
            _loc8_ = 1e-8;
         }
         _loc9_ = _Z0 * _loc8_ + _Z1 / _loc8_;
         _loc10_ = _Z2 * _loc8_ + _Z3 / _loc8_;
         if(_loc9_ < -1)
         {
            _loc9_ = -1;
         }
         else if(_loc9_ > 1)
         {
            _loc9_ = 1;
         }
         if(_loc10_ < -1)
         {
            _loc10_ = -1;
         }
         else if(_loc10_ > 1)
         {
            _loc10_ = 1;
         }
         _loc11_ = Math.acos(_loc9_);
         _loc12_ = Math.acos(_loc10_);
         _loc13_ = _R22 * (_loc11_ - _loc9_ * Math.sin(_loc11_)) + _R12 * (_loc12_ - _loc10_ * Math.sin(_loc12_));
         _loc14_ = ((_loc5_ + _argument) % (2 * Math.PI) + 2 * Math.PI) % (2 * Math.PI) < Math.PI;
         _loc15_ = _loc14_ ? _maxVisFlux - _H1 * _loc13_ : _maxVisFlux - _H2 * _loc13_;
         _loc16_ = -18.9669559998301 - 2.5 / Math.LN10 * Math.log(_loc15_);
         return _distanceModulus + _loc16_;
      }
      
      override public function set magnitude(param1:Number) : void
      {
         throw new Error("magnitude is read-only for an instance of EclipsingBinary");
      }
      
      private function getBolometricCorrection(param1:Number) : Number
      {
         var _loc2_:Number = NaN;
         var _loc3_:Object = null;
         _loc2_ = Math.log(param1) / Math.LN10;
         if(_loc2_ > 3.9)
         {
            _loc3_ = {
               "a":-100139.4991,
               "b":116264.1842,
               "c":-53931.97541,
               "d":12495.04227,
               "e":-1445.868048,
               "f":66.84924471
            };
         }
         else if(_loc2_ < 3.7)
         {
            _loc3_ = {
               "a":-13884.14899,
               "b":8595.127427,
               "c":-488.3425525,
               "d":-627.0092238,
               "e":137.4608131,
               "f":-7.549572042
            };
         }
         else
         {
            _loc3_ = {
               "a":1439.981506,
               "b":-151.9002581,
               "c":-995.1089203,
               "d":582.5176671,
               "e":-123.3293641,
               "f":9.160761128
            };
         }
         return _loc3_.a + _loc2_ * (_loc3_.b + _loc2_ * (_loc3_.c + _loc2_ * (_loc3_.d + _loc2_ * (_loc3_.e + _loc3_.f * _loc2_))));
      }
      
      public function get temperature1() : Number
      {
         return _temperature1;
      }
      
      public function get temperature2() : Number
      {
         return _temperature2;
      }
      
      public function get separation() : Number
      {
         return _separation / EclipsingBinary.SOLAR_RADIUS;
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
               if(_loc2_.argument is Number)
               {
                  argument = _loc2_.argument;
               }
               if(_loc2_.inclination is Number)
               {
                  inclination = _loc2_.inclination;
               }
               if(_loc2_.eccentricity is Number)
               {
                  eccentricity = _loc2_.eccentricity;
               }
               if(_loc2_.separation is Number)
               {
                  separation = _loc2_.separation;
               }
               if(_loc2_.phaseOffset is Number)
               {
                  phaseOffset = _loc2_.phaseOffset;
               }
               if(_loc2_.peakMagnitude is Number)
               {
                  peakMagnitude = _loc2_.peakMagnitude;
               }
               if(_loc2_.mass1 is Number)
               {
                  mass1 = _loc2_.mass1;
               }
               if(_loc2_.mass2 is Number)
               {
                  mass2 = _loc2_.mass2;
               }
               if(_loc2_.radius1 is Number)
               {
                  radius1 = _loc2_.radius1;
               }
               if(_loc2_.radius2 is Number)
               {
                  radius2 = _loc2_.radius2;
               }
               if(_loc2_.temperature1 is Number)
               {
                  temperature1 = _loc2_.temperature1;
               }
               if(_loc2_.temperature2 is Number)
               {
                  temperature2 = _loc2_.temperature2;
               }
            }
            _loc3_++;
         }
         _callUpdate = true;
         update();
      }
      
      public function set argument(param1:Number) : void
      {
         if(isNaN(param1) || !isFinite(param1))
         {
            return;
         }
         _argument = param1 * (Math.PI / 180);
         if(_callUpdate)
         {
            update();
         }
      }
      
      public function set mass2(param1:Number) : void
      {
         if(!isFinite(param1) || isNaN(param1) || param1 <= 0)
         {
            return;
         }
         _mass2 = param1 * EclipsingBinary.SOLAR_MASS;
         if(_callUpdate)
         {
            update();
         }
      }
      
      public function set separation(param1:Number) : void
      {
         if(isNaN(param1) || !isFinite(param1) || param1 <= 0)
         {
            return;
         }
         _separation = param1 * EclipsingBinary.SOLAR_RADIUS;
         if(_callUpdate)
         {
            update();
         }
      }
      
      public function set temperature2(param1:Number) : void
      {
         if(!isFinite(param1) || isNaN(param1) || param1 <= 0)
         {
            return;
         }
         _temperature2 = param1;
         if(_callUpdate)
         {
            update();
         }
      }
      
      private function calculateConstants() : void
      {
         var _loc1_:* = undefined;
         var _loc2_:Number = NaN;
         var _loc3_:Number = NaN;
         var _loc4_:Number = NaN;
         _C1 = Math.sqrt((1 + _eccentricity) / (1 - _eccentricity));
         _loc1_ = Math.cos(_inclination);
         _loc2_ = _separation * (1 - _eccentricity * _eccentricity);
         _J1 = _loc2_ * _loc2_ * (1 - _loc1_ * _loc1_);
         _J2 = _loc2_ * _loc2_ * _loc1_ * _loc1_;
         _J3 = 2 * _eccentricity;
         _J4 = _eccentricity * _eccentricity;
         _R12 = _radius1 * _radius1;
         _R22 = _radius2 * _radius2;
         _Z0 = 1 / (2 * _radius2);
         _Z1 = (_R22 - _R12) * _Z0;
         _Z2 = 1 / (2 * _radius1);
         _Z3 = (_R12 - _R22) * _Z2;
         _loc3_ = getBolometricCorrection(_temperature1);
         _loc4_ = getBolometricCorrection(_temperature2);
         _H1 = 1.89553328524593e-43 * Math.pow(_temperature1,4) * Math.pow(10,_loc3_ / 2.5);
         _H2 = 1.89553328524593e-43 * Math.pow(_temperature2,4) * Math.pow(10,_loc4_ / 2.5);
         _maxVisFlux = (_R12 * _H1 + _R22 * _H2) * Math.PI;
         _minVisMag = -18.9669559998301 - 2.5 / Math.LN10 * Math.log(_maxVisFlux);
         _period = Math.sqrt(4 * Math.PI * Math.PI * _separation * _separation * _separation / (6.673e-11 * (_mass1 + _mass2))) / (24 * 60 * 60);
         _distanceModulus = _peakMagnitude - _minVisMag;
      }
      
      public function set mass1(param1:Number) : void
      {
         if(!isFinite(param1) || isNaN(param1) || param1 <= 0)
         {
            return;
         }
         _mass1 = param1 * EclipsingBinary.SOLAR_MASS;
         if(_callUpdate)
         {
            update();
         }
      }
      
      public function set temperature1(param1:Number) : void
      {
         if(!isFinite(param1) || isNaN(param1) || param1 <= 0)
         {
            return;
         }
         _temperature1 = param1;
         if(_callUpdate)
         {
            update();
         }
      }
      
      public function get argument() : Number
      {
         return _argument * (180 / Math.PI);
      }
      
      public function get period() : Number
      {
         return _period;
      }
      
      public function get distanceModulus() : Number
      {
         return _distanceModulus;
      }
      
      public function get mass2() : Number
      {
         return _mass2 / EclipsingBinary.SOLAR_MASS;
      }
      
      override protected function update() : void
      {
         calculateConstants();
         super.update();
      }
      
      public function set inclination(param1:Number) : void
      {
         if(isNaN(param1) || !isFinite(param1))
         {
            return;
         }
         _inclination = param1 * (Math.PI / 180);
         if(_callUpdate)
         {
            update();
         }
      }
      
      public function set radius1(param1:Number) : void
      {
         if(!isFinite(param1) || isNaN(param1) || param1 <= 0)
         {
            return;
         }
         _radius1 = param1 * EclipsingBinary.SOLAR_RADIUS;
         if(_callUpdate)
         {
            update();
         }
      }
      
      public function set radius2(param1:Number) : void
      {
         if(!isFinite(param1) || isNaN(param1) || param1 <= 0)
         {
            return;
         }
         _radius2 = param1 * EclipsingBinary.SOLAR_RADIUS;
         if(_callUpdate)
         {
            update();
         }
      }
      
      public function get mass1() : Number
      {
         return _mass1 / EclipsingBinary.SOLAR_MASS;
      }
      
      public function set eccentricity(param1:Number) : void
      {
         if(isNaN(param1) || !isFinite(param1) || param1 < 0 || param1 >= 1)
         {
            return;
         }
         _eccentricity = param1;
         if(_callUpdate)
         {
            update();
         }
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
      
      public function get radius1() : Number
      {
         return _radius1 / EclipsingBinary.SOLAR_RADIUS;
      }
      
      public function get inclination() : Number
      {
         return _inclination * (180 / Math.PI);
      }
      
      public function get radius2() : Number
      {
         return _radius2 / EclipsingBinary.SOLAR_RADIUS;
      }
      
      public function get eccentricity() : Number
      {
         return _eccentricity;
      }
      
      public function set peakMagnitude(param1:Number) : void
      {
         if(!isFinite(param1) || isNaN(param1))
         {
            return;
         }
         _peakMagnitude = param1;
         if(_callUpdate)
         {
            update();
         }
      }
      
      public function get phaseOffset() : Number
      {
         return _phaseOffset;
      }
      
      public function get peakMagnitude() : Number
      {
         return _peakMagnitude;
      }
   }
}

