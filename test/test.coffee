assert = require "assert"
Quadtree = require "../build/js/quadtree"

randomNb = (min, max) ->
    throw new Error 'min must be < max' if min >= max
    Math.floor(Math.random() * (max - min)) + min

describe 'quadtree', () ->

    it 'should reject bad or missing arguments on quadtree init.', () ->
        assert.throws (() -> new Quadtree), Error
        assert.throws (() -> new Quadtree x:1,  y:1), Error
        assert.throws (() -> new Quadtree x:1,  y:1,  width:10), Error
        assert.throws (() -> new Quadtree x:1,  y:1,  height:10), Error
        assert.throws (() -> new Quadtree x:-1, y:1,  width:10, height: 10), Error
        assert.throws (() -> new Quadtree x:1,  y:-1, width:10, height: 10), Error
        assert.throws (() -> new Quadtree x:1,  y:1,  width:0,  height: 10), Error
        assert.throws (() -> new Quadtree x:1,  y:1,  width:10, height: -1), Error

    it 'should reject improper elements', () ->
        quadtree = new Quadtree width: 100, height: 100
        assert.throws (() -> quadtree.push()), Error
        assert.throws (() -> quadtree.push x:1), Error
        assert.throws (() -> quadtree.push y:1), Error
        assert.throws (() -> quadtree.push x:1,  y:-1), Error
        assert.throws (() -> quadtree.push x:-1, y:0), Error
        assert.throws (() -> quadtree.push x:1,  y:0, width:-1), Error
        assert.throws (() -> quadtree.push x:1,  y:0, height:-1), Error

    it 'should add a fitting element properly', () ->
        quadtree = new Quadtree width: 100, height: 100
        quadtree.push element = x: 0, y: 0, content: 'element 0'
        assert.equal quadtree.size, 1
        assert.equal quadtree.contents[0], element

    it 'should add an oversized element properly', () ->
        quadtree = new Quadtree width: 100, height: 100
        quadtree.push element = x: 0, y: 0, width: 55, height: 55, content: 'element 0'
        assert.equal quadtree.size, 1
        assert.equal quadtree.oversized[0], element

    it 'should add and remove an element while keeping the length updated', () ->
        quadtree = new Quadtree width: 100, height: 100
        quadtree.push element = x: 0, y: 0, content: 'element 0'
        quadtree.remove element
        assert.equal quadtree.size, 0

    it 'should detect colliding elements', () ->
        quadtree = new Quadtree width: 100, height: 100
        quadtree.push element0 = x: 75, y: 80, width: 10, height: 10
        quadtree.push element1 = x: 80, y: 85, width: 15, height: 10
        quadtree.push element2 = x: 10, y: 15, width: 5, height: 5
        quadtree.push element3 = x: 12, y: 20, width: 5, height: 5
        quadtree.push element4 = x: 0, y: 0
        quadtree.push element5 = x: 49, y: 49, width: 1, height :1
        quadtree.push element6 = x: 50, y: 49, width: 1, height :1
        quadtree.push element7 = x: 49, y: 50, width: 1, height :1
        quadtree.push element8 = x: 50, y: 50, width: 1, height :1
        quadtree.push element9 = x: 99, y: 99
        quadtree.push element10 = x: 99, y: 99

        assert.equal quadtree.size,11
        assert.equal (quadtree.colliding element0)[0], element1
        assert.equal (quadtree.colliding element1)[0], element0
        assert.equal (quadtree.colliding element2)[0], element3
        assert.equal (quadtree.colliding element3)[0], element2
        assert.equal (quadtree.colliding element4).length, 0

        microCollisions = quadtree.colliding element5
        assert.equal microCollisions.length, 3
        siblings = [element6, element7, element8]

        for sibling in siblings
            collisions = quadtree.colliding sibling
            assert.equal collisions.length, 3

        assert.equal (quadtree.colliding element9).length, 1
        assert.equal (quadtree.colliding element10).length, 1

    it 'should iterate over the elements', () ->
        quadtree = new Quadtree width: 100, height: 100

        elementArray = [
            element0 = x: 55, y: 60, width: 10, height: 10,
            element1 = x: 60, y: 65, width: 15, height: 10,
            element2 = x: 10, y: 10, width: 5, height: 5,
            element3 = x: 12, y: 20, width: 5, height: 5,
            element4 = x: 49, y: 49 ]

        for element in elementArray
            quadtree.push element

        assert.equal quadtree.size, 5

        quadtree.each (item) ->
            assert.ok elementArray.indexOf(item) > -1



    it 'should get an element provided its coordinates and properties', () ->
        quadtree = new Quadtree width: 10, height: 10
        quadtree.push e0 = x: 1, y: 0
        quadtree.push e1 = x: 0, y: 1
        quadtree.push e2 = x: 2, y: 1
        quadtree.push e3 = x: 4, y: 5
        quadtree.push e3bis = x: e3.x, y: e3.y, content: 'toto'
        quadtree.push big = x: 0, y: 0, width: 10, height: 10

        assert.equal quadtree.get(x: e0.x, y: e0.y).length, 1
        assert.equal quadtree.get(x: e0.x, y: e0.y)[0], e0
        assert.equal quadtree.get(x: e1.x, y: e1.y).length, 1
        assert.equal quadtree.get(x: e1.x, y: e1.y)[0], e1
        assert.equal quadtree.get(x: e2.x, y: e2.y).length, 1
        assert.equal quadtree.get(x: e2.x, y: e2.y)[0], e2
        assert.equal quadtree.get(x: e3.x, y: e3.y).length, 2
        assert.equal quadtree.get(x: e3.x, y: e3.y)[0], e3
        assert.equal quadtree.get(x: e3.x, y: e3.y)[1], e3bis
        assert.equal quadtree.where(x: e3bis.x, y: e3bis.y, content: 'toto').length, 1
        assert.equal quadtree.where(x: e3bis.x, y: e3bis.y, content: 'toto')[0], e3bis

    it 'should add, list and remove a random number of elements properly', () ->
        times = randomNb 1000, 2000
        quadtree = new Quadtree width: 1024, height: 1024
        for index in [1..times]
            quadtree.push
                x: randomNb 0, 1024
                y: randomNb 0, 1024
                width: randomNb 1, 50
                height: randomNb 1, 50

        assert.equal quadtree.size, times

        elements = []
        quadtree.each (elt) ->
            elements.push elt

        assert.equal elements.length, times

        for elt in elements
            quadtree.remove elt

         assert.equal quadtree.size, 0

         for child in quadtree.children then assert.isNull child.tree

    it 'should be filterable in an immutable way', () ->
        quadtree = new Quadtree width: 100, height: 100

        elementArray = [
            element0 = x: 55, y: 60, width: 10, height: 10,
            element1 = x: 60, y: 65, width: 15, height: 10,
            element2 = x: 10, y: 10, width: 5, height: 5,
            element3 = x: 12, y: 20, width: 5, height: 5,
            element4 = x: 49, y: 49 ]

        for element in elementArray
            quadtree.push element

        copycat = quadtree.filter (element) ->
            element.x > 50

        for element in elementArray
            quadtree.remove element

        assert.equal quadtree.size, 0

        copycat.each (element) ->
            assert.ok(element.x > 50)

         assert.equal copycat.size, 2

    it 'should be visitable', () ->
        quadtree = new Quadtree width: 100, height: 100

        elementArray = [
            element0 = x: 55, y: 60, width: 10, height: 10,
            element1 = x: 60, y: 65, width: 15, height: 10,
            element2 = x: 10, y: 10, width: 5, height: 5,
            element3 = x: 12, y: 20, width: 5, height: 5,
            element4 = x: 49, y: 49 ]

        for element in elementArray
            quadtree.push element

        i = 0
        quadtree.visit () ->
            i += @oversized.length + @contents.length

        assert.equal i, 5

    it 'should have the correct maximum elements by leaf', () ->
        quadtree  = new Quadtree width: 100, height: 100
        quadtree2 = new Quadtree width: 100, height: 100, maxElements: 2

        elementArray = [
            element0 = x: 49, y: 49,
            element1 = x: 10, y: 10,
            element2 = x: 55, y: 55 ]

        for element in elementArray
            quadtree.push element
            quadtree2.push element

        assert.equal quadtree.children["NW"].tree.contents.length, 0
        assert.equal quadtree2.children["NW"].tree.contents.length, 2
