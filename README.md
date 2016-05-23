# | quadtree-lib | [![Build Status](https://travis-ci.org/elbywan/quadtree-lib.svg?branch=master)](https://travis-ci.org/elbywan/quadtree-lib) | [![Coverage Status](https://coveralls.io/repos/github/elbywan/quadtree-lib/badge.svg?branch=master)](https://coveralls.io/github/elbywan/quadtree-lib?branch=master) | [![NPM](https://nodei.co/npm/quadtree-lib.png?mini=true)](https://nodei.co/npm/quadtree-lib/)

<a href="http://elbywan.github.io/quadtree-lib/demo/" target="_blank">
    <img alt="quatree gif" src="assets/quadtree.gif" width="150px" align="left" style="margin-right: 25px"/>
</a>

Quadtree-lib is an easy to use, developer friendly quadtree library which
contains many helper methods to add, remove, iterate, filter, simulate
collisions over 2d elements and more.

If you are already familiar with quadtrees, then you should perfectly understand
how to use this library.

Otherwise, there are many online articles
([wikipedia does the job](https://en.wikipedia.org/wiki/Quadtree)) which explain
the advantages of using the quadtree datastructure in certain situations.

[Here](http://elbywan.github.io/quadtree-lib/demo/) is a small demo of the
library in action.

## Setup

### Using npm

From the command line :

`npm install quadtree-lib`

Then in your javascript file :

```javascript
Quadtree = require("quadtree-lib")
```

### Using Bower

`bower install quadtree-lib`

### Using gulp

Clone the git repository, run
`git clone https://github.com/elbywan/quadtree-lib`  

-   To build the library, run `gulp`.
-   To run the performance tests, run `gulp perf`.

## Usage

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

### Adding elements

Elements must be objects, with coordinates set.

Optionally, you can pass a boolean argument which, if set to True, will
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

### Removing elements

Removes an item by reference.

```javascript
quadtree.remove(item)
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
    return //Place collision algorithm here
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

```javascript
quadtree.each(function(element){
    console.log(element.color)
})
```

### Visit the tree nodes

Visits each node of the quadtree. (meaning subtrees)

```javascript
quadtree.visit(function(){
    // This function is called once for each node.
    //this -> this is always the current node.
    console.log(this.contents)
})
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
