package edu.unl.astro.starField
{
   import flash.events.IEventDispatcher;
   
   public interface IPSF extends IEventDispatcher
   {
      
      function get width() : uint;
      
      function get data() : Array;
      
      function get height() : uint;
      
      function set epoch(param1:Number) : void;
      
      function get x() : int;
      
      function get y() : int;
   }
}

