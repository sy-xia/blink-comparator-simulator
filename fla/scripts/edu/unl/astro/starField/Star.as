package edu.unl.astro.starField
{
   import flash.events.Event;
   import flash.events.EventDispatcher;
   
   public class Star extends EventDispatcher implements IStar
   {
      
      protected var _magnitude:Number = 0;
      
      protected var _epoch:Number = 0;
      
      protected var _callUpdate:Boolean = true;
      
      protected var _x:Number = 0;
      
      protected var _y:Number = 0;
      
      public function Star(... rest)
      {
         super();
         if(rest.length > 0)
         {
            loadSettingsFromObjectsList(rest);
         }
      }
      
      public function get y() : Number
      {
         return _y;
      }
      
      protected function update() : void
      {
         dispatchEvent(new Event(StarField.STAR_CHANGED));
      }
      
      public function get epoch() : Number
      {
         return _epoch;
      }
      
      public function set epoch(param1:Number) : void
      {
         _epoch = param1;
      }
      
      public function get magnitude() : Number
      {
         return _magnitude;
      }
      
      protected function loadSettingsFromObjectsList(param1:*) : void
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
               if(_loc2_.magnitude is Number)
               {
                  magnitude = _loc2_.magnitude;
               }
            }
            _loc3_++;
         }
         _callUpdate = true;
         update();
      }
      
      public function set magnitude(param1:Number) : void
      {
         if(!isFinite(param1) || isNaN(param1))
         {
            return;
         }
         _magnitude = param1;
         if(_callUpdate)
         {
            update();
         }
      }
      
      public function loadSettings(... rest) : void
      {
         loadSettingsFromObjectsList(rest);
      }
      
      public function set y(param1:Number) : void
      {
         if(!isFinite(param1) || isNaN(param1))
         {
            return;
         }
         _y = param1;
         if(_callUpdate)
         {
            update();
         }
      }
      
      public function set x(param1:Number) : void
      {
         if(!isFinite(param1) || isNaN(param1))
         {
            return;
         }
         _x = param1;
         if(_callUpdate)
         {
            update();
         }
      }
      
      public function get x() : Number
      {
         return _x;
      }
   }
}

