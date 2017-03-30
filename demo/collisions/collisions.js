var canvas = document.getElementById("quadtree_canvas")
var ctx = canvas.getContext("2d")
var layer = document.getElementById("layer_canvas")
var layerCtx = layer.getContext("2d")
var container = document.getElementById("canvas-container")
var collisitionRect = document.getElementById("canvas-collision")
var counter = document.getElementById("counter")
var width = Math.min(container.clientWidth, window.innerWidth)
var height = width === window.innerWidth ? window.innerWidth : container.clientHeight

quadtreeColor = 'rgba(120, 144, 156, 0.1)'
scannedColor = 'rgba(229, 57, 53, 1)'
eltColor = 'rgba(136, 14, 79, 1)'
collidingColor = '#F57F17'

eltNb = 1000

document.addEventListener('DOMContentLoaded', function () {
    init()
    makeMovable(collisitionRect, container, {
        onMove: function() {
            updateLayer()
        },
        onResize: function() {
            updateLayer()
        }
    })
    updateCanvas()
    updateLayer()
})

var init = function(){
    canvas.width = width
    canvas.height = height
    ctx.clearRect(0, 0, width, height)
    ctx.lineWidth = 1
    layer.width = width
    layer.height = height
    layerCtx.clearRect(0, 0, width, height)
    layerCtx.lineWidth = 1
    quadtree = new Quadtree({
        width: width,
        height: height
    })
    var elts = []
    for(var i = 0; i < eltNb; i++) {
        var squareSize = randomNb(5, 15)
        elts.push({
            x: randomNb(0, width),
            y: randomNb(0, height),
            width: squareSize,
            height: squareSize,
            color: eltColor
        })
    }
    quadtree.pushAll(elts)
}

var updateCanvas = function(){
    ctx.clearRect(0, 0, width, height)
    quadtree.visit(function(){
        ctx.strokeStyle = quadtreeColor
        drawQuadtree(this)
        ctx.fillStyle = eltColor
        for(i in this.contents)
            drawSquare(this.contents[i], true)
        for(i in this.oversized)
            drawSquare(this.oversized[i], true)
    })
}

var updateLayer = function(){
    var scanned = 0
    var colliding = 0
    var total = quadtree.size

    var monkeyPatchCollisionAlgorithm = function(elt1, elt2) {
        layerCtx.fillStyle = scannedColor
        drawSquare(elt2, true, layerCtx)
        scanned++
        var ref, ref1, ref2, ref3
        return !(elt1.x > elt2.x + ((ref = elt2.width) != null ? ref : 0) || elt1.x + ((ref1 = elt1.width) != null ? ref1 : 0) < elt2.x || elt1.y > elt2.y + ((ref2 = elt2.height) != null ? ref2 : 0) || elt1.y + ((ref3 = elt1.height) != null ? ref3 : 0) < elt2.y);
    }

    layerCtx.clearRect(0, 0, width, height)
    var containerBox = container.getBoundingClientRect()
    var collisionBox = collisitionRect.getBoundingClientRect()
    var coordinates = {
        x: collisionBox.x - containerBox.x,
        y: collisionBox.y - containerBox.y,
        width: collisionBox.width,
        height: collisionBox.height
    }


    quadtree.colliding(coordinates, monkeyPatchCollisionAlgorithm).forEach(function(elt) {
        layerCtx.fillStyle = collidingColor
        drawSquare(elt, true, layerCtx)
        colliding++
    })

    updateCounters(scanned, colliding, total)
}

var updateCounters = function(scanned, colliding, total) {
    counter.innerHTML = "Total : " + total + " | Scanned : " + scanned + " | Colliding : " + colliding
}
