<h1 align="center">
    quadtree-lib<br>
	<br>
	<a href="http://elbywan.github.io/quadtree-lib/demo/collisions/collisions.html" target="_blank">
		<img alt="quatree gif" src="http://elbywan.github.io/quadtree-lib/assets/quadtree.gif" width="120px"/>
	</a><br>
	<a href="https://travis-ci.org/elbywan/quadtree-lib" target="_blank" style="margin-right: 10px">
		<img alt="Build Status" src="https://travis-ci.org/elbywan/quadtree-lib.svg?branch=master"/>
	</a>
	<a href="https://coveralls.io/github/elbywan/quadtree-lib?branch=master" target="_blank" style="margin-right: 10px">
		<img alt="Coverage Status" src="https://coveralls.io/repos/github/elbywan/quadtree-lib/badge.svg?branch=master"/>
	</a>
	<a href="https://www.npmjs.com/package/quadtree-lib" target="_blank">
		<img alt="npm version" src="https://badge.fury.io/js/quadtree-lib.svg"/>
	</a>
</h1>
<h4 align="center">
	Quadtree-lib is an easy to use, developer friendly quadtree library which
	contains many helper methods to add, remove, iterate, filter, simulate
	collisions over 2d elements and more.
</h4>

If you are already familiar with quadtrees, then you should perfectly understand
how to use this library.

Otherwise, there are many online articles
([wikipedia does the job](https://en.wikipedia.org/wiki/Quadtree)) which explain
the advantages of using the quadtree datastructure in certain situations.

If you want to see the library in action :
- [Collision demo](http://elbywan.github.io/quadtree-lib/demo/collisions/collisions.html)
- [Movement demo](http://elbywan.github.io/quadtree-lib/demo/movement/movement.html)
- [Mass demo](http://elbywan.github.io/quadtree-lib/demo/basic/basic.html)

## Setup

### Using npm / yarn

From the command line :

`npm install quadtree-lib` or `yarn add quadtree-lib`

### Using bower

`bower install quadtree-lib`

### Using gulp

In your favorite terminal :

```bash
# 1°clone the repo
git clone https://github.com/elbywan/quadtree-lib
# 2° change dir
cd quadtree-lib
# 3° build the library
gulp
# 4° build the documentation
gulp doc
# 5° run performance tests
gulp perf
# 6° profit
```

## Usage

### Import

**This library is bundled in UMD format.**

Examples :

- Import using commonjs :
```javascript
Quadtree = require("quadtree-lib")
```

- Import globally with a script tag :
```html
<script src="path/to/quadtree-lib.min.js"></script>
```

### Init

First step is to initialize a new Quadtree object.

```javascript
var quadtree = new Quadtree({
    width: 500,
    height: 500,
    maxElements: 5 //Optional
})
```

`width` and `height` are mandatory attributes.

`maxElements` (default 1) is the maximum number of elements contained in a leaf before it
splits into child trees.

### For typescript users

A set of declaration files (.d.ts) is included, which means that you have access to auto-completion and embedded documentation in your favorite IDE.

If you are using the library **globally** with a `<script>` tag, add the following declaration import :
```typescript
/// <reference types="quadtree-lib" />
```

Otherwise, if you are using the **commonjs** way :
```typescript
import * as Quadtree from "quadtree-lib"
```

### Adding elements

Elements must be objects, with coordinates set.

Optionally, you can pass a boolean argument which, if set to `true`, will
remove/push the object into the quadtree each time its coordinates or dimensions
are set *(ex: item.x = ... or item.width = ...)*.

*Without this flag, x / y / width / height properties should* **not** *be
changed  after insertion.*

```javascript
quadtree.push({
    x: 10,      //Mandatory
    y: 10,      //Mandatory
    width: 1,   //Optional, defaults to 1
    height: 2   //Optional, defaults to 1
}, true) //Optional, defaults to false
```

To insert an array of elements, use the **pushAll** method which is faster than inserting each element with push.

```javascript
quadtree.pushAll([
    {x: 1, y: 1},
    {x: 2, y: 2}
    // ... //
])
```

### Removing elements

Removes an item by reference.

```javascript
quadtree.remove(item)
```

### Clearing the tree

Removes the tree contents and restores it to pristine state.

```javascript
quatree.clear()
```

### Filtering the tree

Filters the quadtree and returns a **clone** containing only the elements
determined by a predicate function.

```javascript
var filtered = quadtree.filter(function(element){
    return element.x > 50
})
```

*Opposite: quadtree.reject*

### Retrieve colliding elements

Gets every element that collides with the parameter 2d object.

```javascript
var colliding = quadtree.colliding({
    x: 10,
    y: 10,
    width: 5, //Optional
    height: 5 //Optional
})
```

The default collision function is a basic bounding box algorithm.
You can change it by providing a function as a second argument.

```javascript
var colliding = quadtree.colliding({
    x: 10,
    y: 10
}, function(element1, element2){
    return // Place collision algorithm here //
})

```

### Perform an action on colliding elements

Performs an action on every element that collides with the parameter 2d object.

```javascript
onCollision({
    x: 10,
    y: 20
}, function(item) {
    /* Action on colliding item */

    // As with all iterative methods, modifying the quadtree or its contents is discouraged. //
}, function(element1, element2){
    /* Optional custom collision algorithm */
    return // Place predicate here //
})
```

### Retrieve by properties

Gets every element that match the parameter properties.

```javascript
quadtree.push({x: 0, y: 0, animal: 'rabbit'})
var match = quadtree.where({
    animal: 'rabbit'
})
```

*Alias : quadtree.get*

### Retrieve by predicate

Gets every element that validate the given predicate.

```javascript
quadtree.find(function(element){
    return element.color === 'red' //Example
})
```

### Iterate over the elements

Performs an action on each element of the Quadtree (breadth first traversal).

```javascript
quadtree.each(function(element){
    console.log(element.color)

    // As with all iterative methods, modifying the quadtree or its contents is discouraged. //
})
```

*Like some other data structures, it is strongly discouraged to update Quadtree elements (especially coordinates / dimensions) or the Quadtree itself while iterating on it.*

### Visit the tree nodes

Visits each node of the quadtree. (meaning subtrees)

```javascript
quadtree.visit(function(){
    // This function is called once for each node.
    // *this* is a pointer to the current node.
    console.log(this.contents)

    // As with all iterative methods, modifying the quadtree or its contents is discouraged. //
})
```

### Pretty print

Outputs the tree and its contents in an eye friendly format.

```javascript
var quadtree = new Quadtree({
  width: 10,
  height: 10,
  maxElements: 1
});

var elementArray = [
  element0 = {
    x: 0,
    y: 0,
    toString: function() {
      return 0;
    }
  }, element1 = {
    x: 3,
    y: 3,
    toString: function() {
      return 1;
    }
  }
];

quadtree.pushAll(elementArray);

console.log(quadtree.pretty());
```

Console output :

```
| ROOT
| ------------
└──┐
   | NW
   | ------------
   └──┐
      | SE
      | ------------
      | * Leaf content *
      |   1
      | NW
      | ------------
      | * Leaf content *
      |   0
```


## Further documentation

You can find the annotated source code [here](http://elbywan.github.io/quadtree-lib/).

*Generated with Docco.*

## License

#### The MIT License (MIT)

Copyright (c) 2015 Julien Elbaz

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
