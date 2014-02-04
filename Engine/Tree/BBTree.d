module Engine.Tree.BBTree;

import Engine.math;
alias ulong TimeStamp;
alias ulong Hash;
import std.stdio;
import Engine.Allocator;
import std.parallelism;
import std.concurrency;
import core.atomic;

alias ulong delegate(Indexable a,Indexable b, ulong collisionID) SpatialIndexQueryFunc;
alias void delegate(Node* node)  HashSetIterator;

shared class Stack(T) {
	private shared struct Node {
		T _payload;
		Node * _next;
	}
	private Node * _root;
	
	void push(T value) {
		auto n = cast(shared)new Node(value);
		n._payload = value;
		shared(Node)* oldRoot;
		do {
			oldRoot = _root;
			n._next = oldRoot;
		} while (!cas(&_root, oldRoot, n));
	}
	
	shared(T)* pop() {
		typeof(return) result;
		shared(Node)* oldRoot;
		do {
			oldRoot = _root;
			if (!oldRoot) return null;
			result = & oldRoot._payload;
		} while (!cas(&_root, oldRoot, oldRoot._next));
		return result;
	}

	bool empty() {
		if (atomicLoad(_root))
			return false;
		return true;
	}
}

class BBTree : Tree
{
	ChunkAllocator!(Node, 100) nodeAllocator;
	int allocatedNodes = 0;
	int freedNodes = 0;

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
		IncrementStamp();
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

	void LeafQuery()(Node *subtree, Node *leaf, SpatialIndexQueryFunc func)
	{
        if(rect.Intersects(leaf.bb, subtree.bb)){
			if(subtree.NodeIsLeaf()) {
				if (func !is null) {
					func(leaf.obj, subtree.obj, 0);
				}
			} else {
				LeafQuery(subtree.a, leaf,func);
				LeafQuery(subtree.b, leaf,func);
			}
        }
	}

	void NodeQuery()(Node *leaf, Node *staticRoot, SpatialIndexQueryFunc func)
	{
		if(staticRoot !is null) 
			LeafQuery(staticRoot, leaf, func);

		for(Node *node = leaf; node.parent !is null; node = node.parent){
			if(node == node.parent.a){
				LeafQuery(node.parent.b, leaf, func);
			}
		}
	}


	void SubtreeSelfQuery()(Node *subtree, Node *staticRoot, SpatialIndexQueryFunc func) {
		if(subtree.NodeIsLeaf()){
			NodeQuery(subtree,staticRoot,func);
        } else {
			SubtreeSelfQuery(subtree.a,staticRoot,func);
			SubtreeSelfQuery(subtree.b,staticRoot,func); // TODO: Force TCO here?
        }
	}

	bool LeafUpdate(Node *leaf)
	{
		auto rt = root;
        if(!rect.Contains(leaf.bb, leaf.obj.BB())){
			leaf.bb = BB(leaf.obj);

			rt = SubtreeRemove(rt, leaf);
			root = SubtreeInsert(rt, leaf);

			leaf.stamp = GetMasterTree.stamp;

			return true;
        } else {
			return false;
        }
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

		SubtreeSelfQuery(root,staticRoot,func);
	
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

		return node;
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

interface Indexable {
	//Hash GetHash();
	rect BB();
}

private struct Node {
	public Indexable obj;
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
};
