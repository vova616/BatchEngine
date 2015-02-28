module Engine.Font;

import derelict.freetype.ft;
import derelict.util.exception;
import std.stdio;
import std.conv;
import Engine.Texture;
import Engine.Atlas;
import Engine.math;

alias dchar[] CharSet;

	
struct LetterInfo {
	public recti AtlasRect;
	public dchar Charecter;
	public double XOffset;        
	public double YOffset;       
	public double XAdvance;      
	public double RelativeWidth;  
	public double RelativeHeight; 
}

class Font {
	extern(C) package static FT_Library ftLibrary;

	package FT_Face face;
	Texture Atlas;
	LetterInfo[dchar] Map;

	static CharSet ASCII = CreateCharSet('!', '~');

	static CharSet CreateCharSet(dchar min, dchar max) {
		auto arr = new dchar[max-min+1];
		for(auto i=0;min<=max;min++,i++) {
			arr[i] = min;
		}
		return arr;
	}

	static string CreateSet(dchar min, dchar max) {
		string s = "[to!dchar(" ~ to!string(to!int(min));
		min++;
		for(;min<=max;min++) {
			s ~= "),to!dchar(" ~ to!string(to!int(min));
		}
		s ~= ")]";
		return s;
	}

	static this() {
			DerelictFT.missingSymbolCallback( (string symbolName){ 
				switch (symbolName) {
					case "FT_Get_PS_Font_Value":
					case "FT_Get_CID_Registry_Ordering_Supplement" :
					case "FT_Get_CID_From_Glyph_Index" :
					case "FT_Get_CID_Is_Internally_CID_Keyed" :
					case "FT_Stream_OpenBzip2":
					case "FT_Gzip_Uncompress":
					case "FT_Property_Set":
					case "FT_Property_Get":
					case "FT_Outline_EmboldenXY":
						return ShouldThrow.No;
					default:
						return ShouldThrow.Yes;
				}
			});
			DerelictFT.load();	
			if (FT_Init_FreeType(&ftLibrary) != 0)
				throw new Exception("Cannot initialize FreeType");
	}




	this(string filepath, int size, CharSet set) {
		auto error = FT_New_Face( ftLibrary,
							&filepath.ptr[0],
							0,
							&face );
		if ( error == FT_Err_Unknown_File_Format )
		{
			throw new Exception("Unknown file format.");
		}
		else if ( error )
		{
			writeln(error);
			throw new Exception("Could not read the file " ~ cast(string)filepath ~ " .");
			
		}

		error = FT_Set_Pixel_Sizes(face, 0, size);
		if (error != 0) 
			throw new Exception("Could not set font size(is the font fixed sized?).");
		

		recti[] rects = new recti[set.length];
		int rectsIndex = 0;
		foreach(dchar chr; set) {
			auto glyph_index = FT_Get_Char_Index( face, chr );
			if (glyph_index == 0) {
				throw new Exception("Could not find \'" ~to!string(chr)~ "\' glyph index.");
			}
			
			error = FT_Load_Glyph( face, glyph_index, FT_LOAD_DEFAULT );
			if ( error != 0)
				throw new Exception("Could not load glyph \'" ~to!string(chr)~ "\'.");

			/* convert to an anti-aliased bitmap */
			error = FT_Render_Glyph( face.glyph, FT_RENDER_MODE_NORMAL );
			if ( error )
				throw new Exception("Could not render glyph \'" ~to!string(chr)~ "\'.");

			FT_Bitmap bitmap = face.glyph.bitmap;

			auto height = bitmap.rows;
			auto width = bitmap.width;
			rects[rectsIndex] = recti(width, height);
			rectsIndex++;
		}


		auto atlasSize = MaxRectsBinPack.FindOptimalSize(10, rects, 1);
		if (atlasSize.x == 0) {
			throw new Exception("Could not find atlas size.");
		}
		auto bin = new MaxRectsBinPack(atlasSize.x, atlasSize.y, 1);
		rects = bin.InsertArray(rects);

		ubyte[] atlas = new ubyte[(atlasSize.x*atlasSize.y*2)];

		rectsIndex = 0;
		foreach(dchar chr; set) {
			auto glyph_index = FT_Get_Char_Index( face, chr );
			if (glyph_index == 0) {
				throw new Exception("Could not find \'" ~to!string(chr)~ "\' glyph index.");
			}

			error = FT_Load_Glyph( face, glyph_index, FT_LOAD_DEFAULT );
			if ( error != 0)
				throw new Exception("Could no load glyph \'" ~to!string(chr)~ "\'.");

			/* convert to an anti-aliased bitmap */
			error = FT_Render_Glyph( face.glyph, FT_RENDER_MODE_NORMAL );
			if ( error )
				throw new Exception("Could no render glyph \'" ~to!string(chr)~ "\'.");

			auto glyph = face.glyph;
			FT_Bitmap bitmap = glyph.bitmap;

			

			auto pixelSize = bitmap.width/bitmap.pitch;
			if (pixelSize < 0) {
				pixelSize = -pixelSize;
			}
			auto height = bitmap.rows;
			auto width = bitmap.width;

			auto r = rects[rectsIndex];

			FT_Glyph_Metrics metrics = glyph.metrics;

			Map[chr] = LetterInfo(r,chr,
			                      ((cast(double)metrics.horiBearingX) / 64)	/ cast(double)size ,
								  ( ((cast(double)metrics.horiBearingY) / 64) - cast(double)r.Dy())	/ cast(double)size ,
			                      ((cast(double)metrics.horiAdvance)  / 64)   / cast(double)size ,
			                      cast(double)r.Dx() 				/ cast(double)size, 
			                      cast(double)r.Dy() 				/ cast(double)size);

			auto buffer = bitmap.buffer;
			for (int x =0;x<width;x++) {
				for(int y=0;y<height;y++) {
					auto pos = ((r.min.x+x)+(r.min.y+y)*atlasSize.x)*2;
					if (pos >= atlas.length)
						throw new Exception("DAFUQ");
					atlas[pos] = 0xff;
					atlas[pos+1] = buffer[x+(height-y-1)*width];
				}
			}
			rectsIndex++;
		}
		Atlas = new Texture(atlas, atlasSize.x, atlasSize.y);
	} 
}