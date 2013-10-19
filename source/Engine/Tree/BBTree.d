module Engine.Trees.BBTree;

import Engine.math;
alias ulong TimeStamp;
alias ulong Hash;
import std.stdio;
import Engine.Allocator;

alias ulong delegate(Indexable a,Indexable b, ulong collisionID) SpatialIndexQueryFunc;
alias void delegate(Node* node)  HashSetIterator;


class BBTree : Tree
{
	ChunkAllocator!(Pair, 100) pairAllocator;
	ChunkAllocator!(Node, 100) nodeAllocator;
	int allocatedNodes = 0;
	int allocatedPair = 0;
	int freedNodes = 0;
	int freedPair = 0;


	Node*[Indexable] leaves;
	Node* root;


	@property ref TimeStamp stamp() {
		return stamp_;
	}
	TimeStamp stamp_;

	Tree staticTree;
	Tree dynamicTree;

	this(Tree staticTree)
	{
		if (staticTree !is null) {
			this.staticTree = staticTree;
		}
		stamp_ = 0;
	}

	@property size_t length() const {
		return leaves.length;
	}

	void Each(HashSetIterator func) {
		foreach (Node* node; leaves) {
			func(node);
		}
	}

	void Insert(Indexable obj ) {
		auto leaf = NewLeaf(obj);
		leaves[obj] = leaf;	
		this.root = this.SubtreeInsert(this.root, leaf);
		leaf.stamp = GetMasterTree().stamp;
		LeafAddPairs(leaf);
		IncrementStamp();
	}

	void LeafAddPairs(Node *leaf)
	{
		if (dynamicTree !is null) {
			auto dTree = cast(BBTree)dynamicTree;
			if(dTree !is null && dTree.root !is null){
				MarkContext context = MarkContext(dTree, null, null);
				context.MarkLeafQuery(dTree.root, leaf, true);
			}
        } else {
			auto sTree = cast(BBTree)staticTree;
			Node *staticRoot = sTree !is null ?  sTree.root : null;
			MarkContext context = MarkContext(this, staticRoot, null);
			context.MarkLeaf(leaf);
        }
	}

	void Query(Indexable obj, rect bb, SpatialIndexQueryFunc func) {
		if(root) 
			SubtreeQuery(root, obj, bb, func);
	}

	void SubtreeQuery(Node *subtree, Indexable obj, rect bb, SpatialIndexQueryFunc func)
	{
        if(rect.Intersects(subtree.bb, bb)){
			if(subtree.NodeIsLeaf()){
				func(obj, subtree.obj, 0);
			} else {
				SubtreeQuery(subtree.a, obj, bb, func);
				SubtreeQuery(subtree.b, obj, bb, func);
			}
        }
	}

	bool LeafUpdate(Node *leaf)
	{
		auto rt = root;
        if(!rect.Contains(leaf.bb, leaf.obj.BB())){
			leaf.bb = BB(leaf.obj);

			rt = SubtreeRemove(rt, leaf);
			root = SubtreeInsert(rt, leaf);

			PairsClear(leaf);
			leaf.stamp = GetMasterTree.stamp;

			return true;
        } else {
			return false;
        }
	}

	void PairsClear(Node *leaf)
	{	
        Pair *pair = leaf.pairs;
        leaf.pairs = null;

        while(pair !is null){
			if(pair.a.leaf == leaf){
				Pair *next = pair.a.next;
				ThreadUnlink(pair.b);
				PairRecycle(pair);
				pair = next;
			} else {
				Pair *next = pair.b.next;
				ThreadUnlink(pair.a);
				PairRecycle(pair);
				pair = next;
			}
        }
	}

	void ThreadUnlink()(auto ref Thread thread)
	{
        auto next = thread.next;
        auto prev = thread.prev;

        if(next){
			if(next.a.leaf == thread.leaf) next.a.prev = prev; else next.b.prev = prev;
        }

        if(prev){
			if(prev.a.leaf == thread.leaf) prev.a.next = next; else prev.b.next = next;
        } else {
			thread.leaf.pairs = next;
        }
	}

	Pair* PairFromPool() {
		allocatedPair++;
		return pairAllocator.allocate();
	}

	void PairRecycle(Pair *pair)
	{
		freedPair++;
		pair.a.next = null;
        pairAllocator.free(pair);
	}

	Node* NodeFromPool() {
		allocatedNodes++;
		return nodeAllocator.allocate();
	}

	void NodeRecycle(Node *node)
	{
		freedNodes++;
		node.parent = null;
		nodeAllocator.free(node);
	}

	Node* SubtreeRemove(Node *subtree, Node *leaf)
	{
        if(leaf == subtree){
			return null;
        } else {
			Node *parent = leaf.parent;
			if(parent == subtree){
				Node *other = subtree.NodeOther(leaf);
				other.parent = subtree.parent;
				NodeRecycle(subtree);
				return other;
			} else {
				NodeReplaceChild(parent.parent, parent, parent.NodeOther(leaf));
				return subtree;
			}
        }
	}

	void NodeReplaceChild(Node *parent, Node *child, Node *value)
	{
		assert(!parent.NodeIsLeaf(), "Internal Error: Cannot replace child of a leaf.");
        assert(child == parent.a || child == parent.b, "Internal Error: Node is not a child of parent.");

        if(parent.a == child){
			NodeRecycle(parent.a);
			parent.NodeSetA(value);
        } else {
			NodeRecycle(parent.b);
			parent.NodeSetB(value);
        }

        for(Node *node=parent; node; node = node.parent){
			node.bb = rect.Merge(node.a.bb, node.b.bb);
        }
	}

	void ReindexQuery(SpatialIndexQueryFunc func)
	{
        if(root is null) return;

        // LeafUpdate() may modify tree->root. Don't cache it.
		foreach (ref leaf ; leaves) {
			LeafUpdate(leaf);
		}

        auto staticIndex = cast(BBTree)staticTree;
        Node *staticRoot = staticIndex !is null ? staticIndex.root : null;

        MarkContext context = MarkContext(this, staticRoot, func);
        context.MarkSubtree(root);
        if(staticIndex && !staticRoot) 
			SpatialIndexCollideStatic(this, staticIndex, func);

        IncrementStamp();
	}

	static void SpatialIndexCollideStatic(Tree tree, Tree staticIndex, SpatialIndexQueryFunc func) {
		if (staticIndex.length > 0) {
			tree.Each((Node* node) {
				staticIndex.Query(node.obj, node.obj.BB(), func);
			});
		}
	}

	void IncrementStamp()()
	{
		if (dynamicTree !is null) {
			dynamicTree.stamp++;
		} else {
			stamp++;
		}
	}

	Tree GetMasterTree()() {
		if (dynamicTree !is null) {
			return dynamicTree;
		}
		return this;
	}

	Node * SubtreeInsert(Node *subtree, Node *leaf)
	{
		if(subtree is null){
			return leaf;
		} else if(subtree.NodeIsLeaf()){
			return NodeNew(leaf, subtree);
		} else {
			auto cost_a = subtree.b.bb.Area() + rect.MergedArea(subtree.a.bb, leaf.bb);	
			auto cost_b = subtree.a.bb.Area() + rect.MergedArea(subtree.b.bb, leaf.bb);

			if(cost_a == cost_b){
				cost_a = rect.Proximity(subtree.a.bb, leaf.bb);
				cost_b = rect.Proximity(subtree.b.bb, leaf.bb);
			}

			if(cost_b < cost_a){
				subtree.NodeSetB(SubtreeInsert(subtree.b, leaf));
			} else {	
				subtree.NodeSetA(SubtreeInsert(subtree.a, leaf));
			}
			subtree.bb = rect.Merge(subtree.bb, leaf.bb);

			return subtree;
		}
	}

	Node* NodeNew(Node* a, Node* b)
	{
		Node *node = NodeFromPool();
		
		node.obj = null;	
		node.bb = rect.Merge(a.bb, b.bb);
		node.parent = null;

		node.NodeSetA(a);
		node.NodeSetB(b);

		return node;
	}

	rect BB(Indexable obj )
	{
		auto bb = obj.BB();

		/*
		cpBBTreeVelocityFunc velocityFunc = tree->velocityFunc;
		if(velocityFunc){
			cpFloat coef = 0.1f;
			cpFloat x = (bb.r - bb.l)*coef;
			cpFloat y = (bb.t - bb.b)*coef;
			
			cpVect v = cpvmult(velocityFunc(obj), 0.1f);
			return cpBBNew(bb.l + cpfmin(-x, v.x), bb.b + cpfmin(-y, v.y), bb.r + cpfmax(x, v.x), bb.t + cpfmax(y, v.y));
		} else {
			return bb;
		}
		*/
		return bb;
	}

	Node* NewLeaf(Indexable obj ){
		auto node = NodeFromPool();
		node.obj = obj;
		node.bb = BB(obj);

		node.parent = null;
		node.stamp = 0;
		node.pairs = null;

		return node;
	}

	void PairInsert(Node *a, Node *b)
	{
        Pair* nextA = a.pairs, nextB = b.pairs;
        Pair *pair = PairFromPool();
		*pair = Pair(Thread(null, a, nextA),Thread(null, b, nextB), 0);

        a.pairs = b.pairs = pair;

        if(nextA !is null){
			if(nextA.a.leaf == a) nextA.a.prev = pair; else nextA.b.prev = pair;
        }

        if(nextB !is null){
			if(nextB.a.leaf == b) nextB.a.prev = pair; else nextB.b.prev = pair;
        }
	}

	static this() {
		
		
		class Box : Indexable {
			rect bb;
			this(rect bb) {
				this.bb = bb;
			}
			rect BB() {
				return bb;
			}
		}
	
		import std.random;
		import std.datetime;
		
		import core.memory;
	

		auto tree = new BBTree(null);

			GC.disable();

		auto b1 = new Box(rect(vec2(0,0), vec2(10,10)));
		tree.Insert(b1);
		tree.Insert(new Box(rect(vec2(5,5), vec2(6,6))));
		for (int i=0;i<10000;i++) {
			auto min = vec2(i*2,i*2);
			auto max = vec2(i*3,i*3);
			tree.Insert(new Box(rect(min, max)));
		}
		
	
		tree.ReindexQuery(delegate ulong(Indexable a,Indexable b, ulong collisionID) {
			writeln("collision");
			return collisionID;
		});
		

		string s;
		GC.enable();
		writeln("Inserted", tree.allocatedNodes, " ", tree.allocatedPair," ", tree.freedNodes," ", tree.freedPair);
		scanf("%s", &s);
		
		StopWatch t1;
		t1.start();
		tree.ReindexQuery(delegate ulong(Indexable a,Indexable b, ulong collisionID) {
			return collisionID;
		});
		t1.stop();
		writeln("collision ms", cast(double)t1.peek().nsecs / 1000000000);

		tree.ReindexQuery(delegate ulong(Indexable a,Indexable b, ulong collisionID) {
			return collisionID;
		});
	}
}
	
interface Tree {

	@property ref TimeStamp stamp();
	@property size_t length() const;

	void Each(HashSetIterator fnc);

	//Contains(obj Indexable) bool
	void Insert(Indexable obj);
	//Remove(obj Indexable)

	//Reindex()
	//ReindexObject(obj Indexable)
	//ReindexQuery(fnc SpatialIndexQueryFunc)

	//TimeStamp Stamp();

	void Query(Indexable obj, rect aabb, SpatialIndexQueryFunc fnc);
	//SegmentQuery(obj Indexable, a, b vect.Vect, t_exit vect.Float, fnc func())
}

struct MarkContext {
	BBTree tree;
	Node* staticRoot;
	SpatialIndexQueryFunc func;


	void MarkLeafQuery()(Node *subtree, Node *leaf, bool left)
	{
        if(rect.Intersects(leaf.bb, subtree.bb)){
			if(subtree.NodeIsLeaf()) {
				if(left){
					tree.PairInsert(leaf, subtree);
				} else {
					if(subtree.stamp < leaf.stamp) 
						tree.PairInsert(subtree, leaf);
					if (func !is null)
						func(leaf.obj, subtree.obj, 0);
				}
			} else {
				MarkLeafQuery(subtree.a, leaf, left);
				MarkLeafQuery(subtree.b, leaf, left);
			}
        }
	}

	void MarkLeaf()(Node *leaf)
	{
        if(leaf.stamp == tree.GetMasterTree().stamp) {
			Node *staticRoot = staticRoot;
			if(staticRoot !is null) 
				MarkLeafQuery(staticRoot, leaf, false);

			for(Node *node = leaf; node.parent !is null; node = node.parent){
				if(node == node.parent.a){
					MarkLeafQuery(node.parent.b, leaf, true);
				} else {
					MarkLeafQuery(node.parent.a, leaf, false);
				}
			}
        } else {
			Pair *pair = leaf.pairs;
			while(pair !is null){
				if(leaf == pair.b.leaf){
					if (func !is null)
						pair.id = func(pair.a.leaf.obj, leaf.obj, pair.id);
					pair = pair.b.next;
				} else {
					pair = pair.a.next;
				}
			}
        }
	}

	void MarkSubtree()(Node *subtree)
	{
        if(subtree.NodeIsLeaf()){
			MarkLeaf(subtree);
        } else {
			MarkSubtree(subtree.a);
			MarkSubtree(subtree.b); // TODO: Force TCO here?
        }
	}

};

interface Indexable {
	//Hash GetHash();
	rect BB();
}

struct Thread  {
	Pair* prev;
	Node* leaf;
	Pair* next;
}

struct Pair {
	Thread a, b; 
	ulong id;
}

struct Node {
	Indexable obj;
	rect bb;
	Node *parent;

	bool NodeIsLeaf()
	{
		return obj !is null;
	}

	Node* NodeOther(Node *child)
	{
        return (a == child ? b : a);
	}

	void NodeSetA()(Node *value)
	{
        a = value;
        value.parent = &this;
	}

	void NodeSetB()(Node *value)
	{
        b = value;
        value.parent = &this;
	}

	//children
	Node* a, b;

	//leaf
	TimeStamp stamp;
	Pair* pairs;
};
