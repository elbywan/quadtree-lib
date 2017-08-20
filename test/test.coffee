assert = require 'assert'
Quadtree = require '../build/js/quadtree'

randomNb = (min, max) ->
    throw new Error 'min must be < max' if min >= max
    Math.floor(Math.random() * (max - min)) + min

describe 'quadtree', ->

    it 'should reject bad or missing arguments on quadtree init.', ->
        assert.throws (-> new Quadtree), Error
        assert.throws (-> new Quadtree x: 1,  y: 1), Error
        assert.throws (-> new Quadtree x: 1,  y: 1,  width: 10), Error
        assert.throws (-> new Quadtree x: 1,  y: 1,  height: 10), Error
        assert.throws (-> new Quadtree x: 1,  y: 1,  width: 0,  height: 10), Error
        assert.throws (-> new Quadtree x: 1,  y: 1,  width: 10, height: -1), Error
        assert.throws (-> new Quadtree x: {}, y: 1,  width: 10, height: 10), Error
        assert.throws (-> new Quadtree x: 1,  y: 1,  width: 10, height: 10, maxElements: -1), Error

    it 'should reject improper elements', ->
        quadtree = new Quadtree width: 100, height: 100
        assert.throws (-> quadtree.push()), Error
        assert.throws (-> quadtree.push 'string'), Error
        assert.throws (-> quadtree.push 10), Error
        assert.throws (-> quadtree.push x: 1), Error
        assert.throws (-> quadtree.push y: 1), Error
        assert.throws (-> quadtree.push x: 1, y: 0, width: -1), Error
        assert.throws (-> quadtree.push x: 1, y: 0, height: -1), Error

    it 'should add a fitting element properly', ->
        quadtree = new Quadtree x: -10, y: -10, width: 20, height: 20
        quadtree.push element = x: 0, y: 0, content: 'element 0'
        assert.equal quadtree.size, 1
        assert.equal quadtree.contents[0], element

    it 'should add an oversized element properly', ->
        quadtree = new Quadtree width: 100, height: 100
        quadtree.push element = x: 0, y: 0, width: 55, height: 55, content: 'element 0'
        assert.equal quadtree.size, 1
        assert.equal quadtree.oversized[0], element

    it 'should add and remove an element while keeping the length updated', ->
        quadtree = new Quadtree width: 100, height: 100
        quadtree.push element = x: 0, y: 0, content: 'element 0'
        quadtree.remove element
        assert.equal quadtree.size, 0

    it 'should return false when trying to remove an unknown element', ->
        quadtree = new Quadtree width: 100, height: 100
        quadtree.push element = x: 0, y: 0, content: 'element 0'
        assert.equal quadtree.remove(x: 10, y: 10), false
        assert.equal quadtree.size, 1

    it 'should clean itself properly', ->
        quadtree = new Quadtree width: 100, height: 100
        quadtree.pushAll [
            element0 =  x: 75,  y: 80, width: 10, height: 10,
            element1 =  x: 80,  y: 85, width: 15, height: 10,
            element2 =  x: 10,  y: 15, width: 1,  height: 1,
            element3 =  x: 12,  y: 19, width: 1,  height: 1 ]
        assert.equal quadtree.size, 4
        assert.equal(quadtree.children.NW.tree.children.NW.tree.children.SE.tree.contents[0], element3)
        quadtree.clear()
        quadtree.pushAll [ element0, element1, element2, element3 ]
        assert.equal quadtree.size, 4
        assert.equal(quadtree.children.NW.tree.children.NW.tree.children.SE.tree.contents[0], element3)

    it 'should detect colliding elements', ->
        quadtree = new Quadtree width: 100, height: 100
        quadtree.pushAll [
            element0 =  x: 75,  y: 80, width: 10, height: 10,
            element1 =  x: 80,  y: 85, width: 15, height: 10,
            element2 =  x: 10,  y: 15, width: 5,  height: 5,
            element3 =  x: 12,  y: 19, width: 5,  height: 5,
            element4 =  x: 5,   y: 5,
            element5 =  x: 49,  y: 49, width: 2, height: 2,
            element6 =  x: 50,  y: 49, width: 1, height: 1,
            element7 =  x: 49,  y: 50, width: 1, height: 1,
            element8 =  x: 50,  y: 50, width: 1, height: 1,
            element9 =  x: 98,  y: 98,
            element10 = x: 98,  y: 98,
            element11 = x: 0,   y: 0,
            element12 = x: -2,  y: -2, width: 5, height: 5,
            element13 = x: 105, y: 105,
            element14 = x: 99,  y: 99, width: 10, height: 10,
            element15 = x: 105, y: 55,
            element16 = x: 99,  y: 55, width: 10, height: 10,
            element17 = x: 55,  y: 105,
            element18 = x: 55,  y: 99, width: 10, height: 10]

        assert.equal quadtree.size, 19
        assert.equal (quadtree.colliding element0)[0], element1
        quadtree.onCollision element0, (i) -> assert.equal i, element1
        assert.equal (quadtree.colliding element1)[0], element0
        quadtree.onCollision element1, (i) -> assert.equal i, element0
        assert.equal (quadtree.colliding element2)[0], element3
        quadtree.onCollision element2, (i) -> assert.equal i, element3
        assert.equal (quadtree.colliding element3)[0], element2
        quadtree.onCollision element3, (i) -> assert.equal i, element2
        assert.equal (quadtree.colliding element4).length, 0
        quadtree.onCollision element4, (i) -> throw new Error('Unexpected collision.')

        microCollisions = quadtree.colliding element5
        assert.equal microCollisions.length, 3
        counter = 0
        quadtree.onCollision element5, (i) -> counter++
        assert.equal counter, 3

        siblings = [element6, element7, element8]
        for sibling in siblings
            siblingsCollisions = quadtree.colliding sibling
            assert.equal siblingsCollisions.length, 1
            counter = 0
            quadtree.onCollision sibling, (i) -> counter++
            assert.equal counter, 1

        outers = [element11, element12, element13, element14,
            element15, element16, element17, element18]
        for outer in outers
            outerCollisions = quadtree.colliding outer
            assert.equal outerCollisions.length, 1
            counter = 0
            quadtree.onCollision outer, (i) -> counter++
            assert.equal counter, 1

        assert.equal (quadtree.colliding element9).length, 1
        assert.equal (quadtree.colliding element10).length, 1

    it 'should iterate over the elements', ->
        quadtree = new Quadtree width: 100, height: 100

        elementArray = [
            element0 = x: 55, y: 60, width: 10, height: 10,
            element1 = x: 60, y: 65, width: 15, height: 10,
            element2 = x: 10, y: 10, width: 5, height: 5,
            element3 = x: 12, y: 20, width: 5, height: 5,
            element4 = x: 49, y: 49 ]

        quadtree.pushAll elementArray

        assert.equal quadtree.size, 5

        quadtree.each (item) ->
            assert.ok elementArray.indexOf(item) > -1

    it 'should get an element provided its coordinates and properties', ->
        quadtree = new Quadtree width: 10, height: 10
        quadtree.pushAll [
             e0 = x: 1, y: 0,
             e1 = x: 0, y: 1,
             e2 = x: 2, y: 1,
             e3 = x: 4, y: 5,
             e3bis = x: e3.x, y: e3.y, content: 'toto',
             big = x: 0, y: 0, width: 10, height: 10 ]

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
        assert.equal quadtree.find((item) -> item.content is 'toto')[0], e3bis
        assert.equal quadtree.where(x: 2, y: 1, content: 'nope').length, 0

    it 'should add, list and remove a random number of elements properly', ->
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

    it 'should be filterable in an immutable way', ->
        quadtree = new Quadtree width: 100, height: 100

        elementArray = [
            element0 = x: 55, y: 60, width: 10, height: 10, toString: -> 0,
            element1 = x: 60, y: 65, width: 15, height: 10, toString: -> 1,
            element2 = x: 10, y: 10, width: 5, height: 5, toString: -> 2,
            element3 = x: 12, y: 20, width: 5, height: 5, toString: -> 3,
            element4 = x: 49, y: 49, toString: -> 4 ]

        quadtree.pushAll elementArray

        copycatFilter = quadtree.filter (element) ->
            element.x > 50
        copycatReject = quadtree.reject (element) ->
            element.width > 5

        for element in elementArray
            assert.equal quadtree.remove(element), true

        assert.equal quadtree.size, 0

        copycatFilter.each (element) ->
            assert.ok(element.x > 50)
        copycatReject.each (element) ->
            assert.ok(element.width ? 1 <= 5)

        assert.equal copycatFilter.size, 2
        assert.equal copycatReject.size, 3

    it 'should be visitable', ->
        quadtree = new Quadtree width: 100, height: 100

        elementArray = [
            element0 = x: 55, y: 60, width: 10, height: 10,
            element1 = x: 60, y: 65, width: 15, height: 10,
            element2 = x: 10, y: 10, width: 5, height: 5,
            element3 = x: 12, y: 20, width: 5, height: 5,
            element4 = x: 49, y: 49 ]

        quadtree.pushAll elementArray

        i = 0
        quadtree.visit ->
            i += @oversized.length + @contents.length

        assert.equal i, 5

    it 'should have the correct maximum elements by leaf', ->
        quadtree  = new Quadtree width: 100, height: 100
        quadtree2 = new Quadtree width: 100, height: 100, maxElements: 2

        elementArray = [
            element0 = x: 49, y: 49,
            element1 = x: 10, y: 10,
            element2 = x: 55, y: 55 ]

        quadtree.pushAll elementArray
        quadtree2.pushAll elementArray

        assert.equal quadtree.children['NW'].tree.contents.length, 0
        assert.equal quadtree2.children['NW'].tree.contents.length, 2

    it 'should update the quadtree if an element dimensions or position is manually updated', ->
        quadtree  = new Quadtree width: 100, height: 100

        elementArray = [
            element0 = x: 0, y: 0,
            element1 = x: 1, y: 1,
            element2 = x: 2, y: 2 ]

        for element in elementArray
            quadtree.push element, true

        assert.equal quadtree.size, 3
        assert.equal quadtree.children['NW'].tree.size, 3
        assert.equal quadtree.oversized.indexOf(element0), -1

        element0.x = 70

        assert.equal quadtree.size, 3
        assert.equal quadtree.children['NW'].tree.size, 2
        assert.equal quadtree.children['NE'].tree.size, 1
        assert.equal quadtree.oversized.indexOf(element0), -1

        element0.y = 70

        assert.equal quadtree.size, 3
        assert.equal quadtree.children['NW'].tree.size, 2
        assert.equal quadtree.children['SE'].tree.size, 1
        assert.equal quadtree.oversized.indexOf(element0), -1

        element0.x = 0
        element0.y = 0
        element0.width = 60
        element0.height = 60

        assert.equal quadtree.size, 3
        assert.equal quadtree.children['NW'].tree.size, 2
        assert.equal quadtree.oversized.indexOf(element0), 0

        for element in elementArray
            quadtree.remove element

        element0.x = 0
        element0.y = 0
        element1.y = 1
        assert.equal quadtree.size, 0


    it 'should get an element by any property', ->
        quadtree  = new Quadtree width: 100, height: 100
        quadtree.push e0 = x: 0, y: 0, animal: 'rabbit'
        quadtree.push e1 = x: 25, y: 50, animal: 'dog'
        quadtree.push e1 = x: 16, y: 18, animal: 'rabbit'

        whereResult1 = quadtree.where(animal: 'horse')
        whereResult2 = quadtree.where(animal: 'rabbit')
        whereResult3 = quadtree.where(animal: 'dog')

        assert.equal(whereResult1.length, 0)
        assert.equal(whereResult2.length, 2)
        assert.equal(whereResult3.length, 1)

    it 'should pretty print the quadtree', ->
        quadtree = new Quadtree width: 20, height: 20, maxElements: 2
        elementArray = [
            element0 = x: 0,  y: 0,  toString: -> 0,
            element1 = x: 2,  y: 2,  toString: -> 1,
            element2 = x: 4,  y: 4,  toString: -> 2,
            element3 = x: 6,  y: 6,  toString: -> 3,
            element4 = x: 8,  y: 8,  toString: -> 4,
            element5 = x: 10, y: 8,  toString: -> 5,
            element6 = x: 12, y: 12, toString: -> 6,
            element7 = x: 8,  y: 14, toString: -> 7,
            element8 = x: 6,  y: 16, toString: -> 8,
            element9 = x: 18, y: 18, toString: -> 9
            bigElement = x: 10, y: 10, width: 6, height: 6, toString: -> '[BIG]'
        ]
        quadtree.pushAll elementArray

        fixedOutput =  '''
                       | ROOT
                       | ------------
                       └──┐
                          | SE
                          | ------------
                          | * Oversized elements *
                          |   [BIG]
                          | * Leaf content *
                          |   6,9
                          | SW
                          | ------------
                          | * Leaf content *
                          |   7,8
                          | NE
                          | ------------
                          | * Leaf content *
                          |   5
                          | NW
                          | ------------
                          └──┐
                             | SE
                             | ------------
                             | * Leaf content *
                             |   3,4
                             | NW
                             | ------------
                             └──┐
                                | SE
                                | ------------
                                | * Leaf content *
                                |   1,2
                                | NW
                                | ------------
                                | * Leaf content *
                                |   0\n
                                '''
        assert.equal(quadtree.pretty(), fixedOutput)
