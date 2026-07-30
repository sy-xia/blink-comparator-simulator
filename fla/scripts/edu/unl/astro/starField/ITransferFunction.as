package edu.unl.astro.starField
{
   import flash.events.IEventDispatcher;
   
   public interface ITransferFunction extends IEventDispatcher
   {
      
      function set peakValue(param1:uint) : void;
      
      function getColor(param1:uint) : uint;
      
      function get peakValue() : uint;
   }
}

