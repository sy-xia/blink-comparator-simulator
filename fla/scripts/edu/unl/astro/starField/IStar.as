package edu.unl.astro.starField
{
   import flash.events.IEventDispatcher;
   
   public interface IStar extends IEventDispatcher
   {
      
      function get magnitude() : Number;
      
      function set epoch(param1:Number) : void;
      
      function get x() : Number;
      
      function get y() : Number;
   }
}

