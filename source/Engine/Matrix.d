module Engine.Matrix;

import gl3n.linalg;
import std.stdio;
import std.datetime;



/*
unittest {
	import core.simd;
    import std.random;

    Random r;
    r.seed(0);

    auto floatArray = new float[10000000];
    auto floatArray2 = new float[10000000];
    foreach(ref f; floatArray) {
        f = uniform(0,100, r);
    }

    int i = 0, i2=0, i3 = 0, i4 = 0;
    auto t = benchmark!(
	{
		float4* a,b;
		//float4* aptr;
		a = cast(float4*)floatArray[i..i+4];
		b = cast(float4*)floatArray[i+4..i+8];
		//a.array = [floatArray[i],floatArray[i+1],floatArray[i+2],floatArray[i+3]];
		//a.array = floatArray[i..i+4];
		//b.array = [floatArray[i+4],floatArray[i+5],floatArray[i+6],floatArray[i+7]];
		float4 c = (*a)*(*b);
		//float4 c = (*cast(float4*)floatArray[i..i+4])*(*cast(float4*)floatArray[i+4..i+8]);
		//writeln(c.ptr[0..4], (*a).ptr[0..4], (*b).ptr[0..4]);
		i += 8;
		i = i % cast(int)(floatArray.length-8);
	},
	{
		vec4 c =
			cast(vec4)(floatArray[i2..i2+4])*cast(vec4)(floatArray[i2+4..i2+8]);
		i2 += 8;
		i2 = i2 % cast(int)(floatArray.length-8);
	},
	{
		*(cast(byte16*)floatArray2[i3..i3+16]) = *(cast(byte16*)floatArray[i3..i3+16]);
		i3 += 16;
		i3 = i3 % cast(int)(floatArray.length-16);
	},
	{
		*(cast(long*)floatArray2[i4..i4+2]) = *(cast(long*)floatArray[i4..i4+2]);
		//floatArray2[i4..i4+16] = floatArray[i4..i4+16];
		i4 += 16;
		i4 = i4 % cast(int)(floatArray.length-16);
	}
	)(100000);
	writeln(cast(float)t[0].nsecs/100000, " ",
			cast(float)t[1].nsecs/100000, " ", cast(float)t[2].nsecs/100000, " ",
			cast(float)t[3].nsecs/100000);
} 
*/