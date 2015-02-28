module Engine.Atlas;


import Engine.math;
import std.math;
import std.stdio;
import Engine.Texture;

class Atlas {
	Texture texture;
	
	this(int width, int height) {

	}


}



class Image {
	ubyte[] Pixels;
	int Width;
	int Height;
	PixelType Type;



	this(ubyte[] pixels, int width, int height, PixelType type) {
		this.Pixels = pixels;
		this.Width = width;
		this.Height = height;
		this.Type = type;
	}


	enum PixelType {
		RGBA,
		RGB,
		BGR,
		BGRA,
		Gray,
		Alpha,
	}
}


class MaxRectsBinPack {
	int width;
	int height;
	int padding;

	recti[] freeRectangles;
	recti[] usedRectangles;

	this(int width, int height, int padding) {
		this.width = width;
		this.height = height;
		this.padding = padding;
		freeRectangles ~= recti(width,height);
	}

	void Reset() {
		freeRectangles.length = 1;
		usedRectangles.length = 0;
		freeRectangles[0] = recti(width,height);
	}

	void placeRect(recti r) {
		for (auto i = 0; i < freeRectangles.length; i++) {
			if (SplitFreeNode(freeRectangles[i], r)) {
				freeRectangles[i] = freeRectangles[freeRectangles.length-1];
				freeRectangles.length--;
				i--;
			}
		}
		PruneFreeList();
		usedRectangles ~= r;
	}


	/// Computes the ratio of used surface area.
	float Occupancy()  {
		ulong usedSurfaceArea = 0;
		foreach (ref r; usedRectangles) {
			usedSurfaceArea += r.Dx() * r.Dy();
		}
		return (cast(double)(usedSurfaceArea) / cast(double)(this.width*this.height));
	}

	bool Insert(recti rect, out recti result) {
		int a,b;
		auto r = this.FindPositionForNewNodeBestShortSideFit(rect.Dx()+this.padding, rect.Dy()+this.padding,a,b);
		if (r.Dx() == 0) {
			return false;
		}

		this.placeRect(r);
	
		r.max.x -= this.padding;
		r.max.y -= this.padding;

		return true;
	}

	recti[] InsertArray(recti[] rects)   {
		auto r = new recti[rects.length];
		auto numRects = rects.length;
		while (numRects != 0) {
			auto bestScore1 = int.max;
			auto bestScore2 = int.max;
			auto bestRectIndex = -1;
			recti bestNode;

			foreach (int i,ref recti rect; rects) {
				if (r[i] != recti.Zero) {
					continue;
				}	
				int score1, score2;
				auto newNode = this.FindPositionForNewNodeBestShortSideFit(rect.Dx()+this.padding, rect.Dy()+this.padding, score1, score2);
				if (score1 < bestScore1 || (score1 == bestScore1 && score2 < bestScore2)) {
					bestScore1 = score1;
					bestScore2 = score2;
					bestNode = newNode;
					bestRectIndex = i;
				}
			}

			if (bestRectIndex == -1) {
				return null;
			} else {
				placeRect(bestNode);
				bestNode.max.x -= padding;
				bestNode.max.y -= padding;
				r[bestRectIndex] = bestNode;
				numRects--;
			}
		}
		return r;
	}

	void PruneFreeList() {
		/*
		///  Would be nice to do something like this, to avoid a Theta(n^2) loop through each pair.
		///  But unfortunately it doesn't quite cut it, since we also want to detect containment.
		///  Perhaps there's another way to do this faster than Theta(n^2).

		if (freeRectangles.size() > 0)
		clb::sort::QuickSort(&freeRectangles[0], freeRectangles.size(), NodeSortCmp);

		for(size_t i = 0; i < freeRectangles.size()-1; ++i)
		if (freeRectangles[i].x == freeRectangles[i+1].x &&
		freeRectangles[i].y == freeRectangles[i+1].y &&
		freeRectangles[i].width == freeRectangles[i+1].width &&
		freeRectangles[i].height == freeRectangles[i+1].height)
		{
		freeRectangles.erase(freeRectangles.begin() + i);
		--i;
		}
		*/

		/// Go through each pair and remove any rectangle that is redundant.
		for (auto i = 0; i < freeRectangles.length; i++) {
			for (auto j = i + 1; j < freeRectangles.length; j++) {
				if (freeRectangles[i].In(this.freeRectangles[j])) {
					freeRectangles[i] = freeRectangles[freeRectangles.length-1];
					//freeRectangles = freeRectangles[0..i] ~ freeRectangles[i+1..$];
					freeRectangles.length--;
					
					i--;
					break;
				}
				if (this.freeRectangles[j].In(this.freeRectangles[i])) {
					freeRectangles[j] = freeRectangles[freeRectangles.length-1];
					//freeRectangles = freeRectangles[0..j] ~ freeRectangles[j+1..$];
					freeRectangles.length--;
					j--;
				}
			}
		}
	}

	recti FindPositionForNewNodeBestShortSideFit(int width,int height, out int bestShortSideFit, out int bestLongSideFit) {
		bestShortSideFit = int.max;
		bestLongSideFit = int.max;
		recti bestNode;
		foreach (ref r; freeRectangles) {
				auto rW = r.Dx();
				auto rH = r.Dy();
				// Try to place the rectangle in upright (non-flipped) orientation.
				if (rW >= width && rH >= height) {
						auto leftoverHoriz = abs(rW - width);
						auto leftoverVert = abs(rH - height);
						auto shortSideFit = min(leftoverHoriz, leftoverVert);
						auto longSideFit = max(leftoverHoriz, leftoverVert);

						if (shortSideFit < bestShortSideFit || (shortSideFit == bestShortSideFit && longSideFit < bestLongSideFit)) {
								bestNode.min = r.min;
								bestNode.max = vec2i(bestNode.min.x + width, bestNode.min.y + height);
								bestShortSideFit = shortSideFit;
								bestLongSideFit = longSideFit;
						}
				}

			/* Disable rotation
			if (rW >= height && rH >= width)
			{
				auto flippedLeftoverHoriz = abs(rW - height);
				auto flippedLeftoverVert = abs(rH - width);
				auto flippedShortSideFit = min(flippedLeftoverHoriz, flippedLeftoverVert);
				auto flippedLongSideFit = max(flippedLeftoverHoriz, flippedLeftoverVert);

				if (flippedShortSideFit < bestShortSideFit || (flippedShortSideFit == bestShortSideFit && flippedLongSideFit < bestLongSideFit)) {
					bestNode.min = vec2i(freeRectangles[i].x, freeRectangles[i].y);
					bestNode.max = vec2i(freeRectangles[i].x + height,  freeRectangles[i].y + width);
					bestShortSideFit = flippedShortSideFit;
					bestLongSideFit = flippedLongSideFit;
				}
			}
			*/
		}
		return bestNode;
	}

	bool SplitFreeNode(recti freeNode,recti usedNode )  {
		// Test with SAT if the rectangles even intersect.
		if (usedNode.min.x >= freeNode.max.x || usedNode.max.x <= freeNode.min.x ||
			usedNode.min.y >= freeNode.max.y || usedNode.max.y <= freeNode.min.y) {
				return false;
		}

		if (usedNode.min.x < freeNode.max.x && usedNode.max.x > freeNode.min.x) {
			// New node at the top side of the used node.
			if (usedNode.min.y > freeNode.min.y && usedNode.min.y < freeNode.max.y) {
					auto newNode = freeNode;
					newNode.max.y = usedNode.min.y;
					this.freeRectangles ~= newNode;
			}

			// New node at the bottom side of the used node.
			if (usedNode.max.y < freeNode.max.y) {
					auto newNode = freeNode;
					newNode.min.y = usedNode.max.y;
					this.freeRectangles ~= newNode;
			}
		}

		if (usedNode.min.y < freeNode.max.y && usedNode.max.y > freeNode.min.y) {
			// New node at the left side of the used node.
			if (usedNode.min.x > freeNode.min.x && usedNode.min.x < freeNode.max.x) {
					auto newNode = freeNode;
					newNode.max.x = usedNode.min.x;
					this.freeRectangles ~= newNode;
			}

			// New node at the right side of the used node.
			if (usedNode.max.x < freeNode.max.x) {
					auto newNode = freeNode;
					newNode.min.x = usedNode.max.x;
					this.freeRectangles ~= newNode;
			}
		}

		return true;
	}

	static vec2i FindOptimalSizeFast(long totalSize)  {
		long ww = 1, hh = 1;
		auto sw = true;
		while (ww*hh < totalSize) {
			if (sw) {
				hh *= 2;
			} else {
				ww *= 2;
			}
			sw = !sw;
		}
		return vec2i(cast(int)(ww),cast(int)(hh));
	}

	/*
	This needs to be smarter, but it does work great for images like fonts
	*/
	static vec2i FindOptimalSize(int tries ,recti[] rects, int padding)  {
		long totalSize = 0;
		foreach (ref rect; rects) {
			totalSize += (rect.Dx() * rect.Dy());
		}

		auto size = FindOptimalSizeFast(totalSize);
		auto sw = true;
		if (size.x < size.y) {
			sw = false;
		}
		auto bin = new MaxRectsBinPack(size.x, size.y, padding);
		for (auto i = 0; i < tries; i++) {
			auto rs = bin.InsertArray(rects);
			if (rs != null) {
				return size;
			}
			if (sw) {
				size.y *= 2;
				sw = !sw;
			} else {
				size.x *= 2;
				sw = !sw;
			}	
			bin.Reset();
			bin.width = size.x;
			bin.height = size.y;
		}

		return vec2i(0,0);
	}
}

