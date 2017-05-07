assert = require 'assert'
Quadtree = require '../../build/js/quadtree'

randomNb = (min, max) ->
    throw new Error 'min must be < max' if min >= max
    Math.floor(Math.random() * (max - min)) + min

describe 'quadtree', ->
    @.timeout 60000

    perfFunction = (times, size, buffer = 1) ->
        quadtree = new Quadtree width: size, height: size, maxElements: buffer

        startingTime = new Date()
        console.log "[Perfs] Starting for #{times} elements with size #{size}, #{startingTime} [buffer: #{buffer}]"
        console.log '[Perfs] Adding random elements ...'

        randomElements = []
        for index in [1..times - 1]
            randomElements.push
                x: randomNb 0, size
                y: randomNb 0, size
                width: randomNb 1, size / 10
                height: randomNb 1, size / 10
        quadtree.pushAll(randomElements)

        randomElt = {
            x: randomNb 0, size
            y: randomNb 0, size
            width: randomNb 1, size / 10
            height: randomNb 1, size / 10
        }
        quadtree.push randomElt

        console.log "\t#{new Date().getTime() - startingTime.getTime()} ms elapsed."

        console.log '[Perfs] Collision check ...'
        startingTime = new Date()
        collisions = quadtree.colliding randomElt
        console.log "[Perfs] #{collisions.length} collisions detected."

        assert.equal quadtree.size, times

        console.log "\t#{new Date().getTime() - startingTime.getTime()} ms elapsed."
        console.log '[Perfs] Filtering ...'
        startingTime = new Date()
        clone = quadtree.filter (elt) ->
            elt.content = 'Lorem ipsum ...'
            true

        assert.equal clone.size, times

        console.log "\t#{new Date().getTime() - startingTime.getTime()} ms elapsed."
        console.log '[Perfs] ForEach ...'
        startingTime = new Date()
        i = 0
        clone.each (elt) ->
            i++
        assert.equal i, clone.size

        console.log "\t#{new Date().getTime() - startingTime.getTime()} ms elapsed."
        console.log '[Perfs] Visitor ...'
        startingTime = new Date()
        i = 0
        clone.visit ->
            i += @contents.length + @oversized.length
        assert.equal i, clone.size

        console.log "\t#{new Date().getTime() - startingTime.getTime()} ms elapsed."

    it 'should add, clone and iterate on a thousand random elements inside a 1024*1024 quadtree',  ->
        perfFunction 1000, 1024

    it 'should add, clone and iterate on ten thousand random elements inside a 1024*1024 quadtree', ->
        perfFunction 10000, 1024

    it 'should add, clone and iterate on ten thousand random elements inside a 2048*2048 quadtree', ->
        perfFunction 10000, 2048

    it 'should add, clone and iterate on a hundred thousand random elements inside a 2048*2048 quadtree', ->
        perfFunction 100000, 2048

    it 'should add, clone and iterate on a million of random elements inside a 2048*2048 quadtree', ->
        perfFunction 1000000, 2048
