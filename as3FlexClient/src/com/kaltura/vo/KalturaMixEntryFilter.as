package com.kaltura.vo
{
	import com.kaltura.vo.KalturaMixEntryBaseFilter;

	[Bindable]
	public dynamic class KalturaMixEntryFilter extends KalturaMixEntryBaseFilter
	{
		override public function getUpdateableParamKeys():Array
		{
			var arr : Array;
			arr = super.getUpdateableParamKeys();
			return arr;
		}

		override public function getInsertableParamKeys():Array
		{
			var arr : Array;
			arr = super.getInsertableParamKeys();
			return arr;
		}

	}
}
