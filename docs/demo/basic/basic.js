var canvas = document.getElementById("quadtree_canvas")
var layer = document.getElementById("layer_canvas")
var container = document.getElementById("canvas-container")
var counter = document.getElementById("counter")
var ctx = canvas.getContext("2d")
var layerCtx = layer.getContext("2d")
var width = Math.min(container.clientWidth, window.innerWidth)
var height = container.clientHeight
DELAY = 1
canvas.width = width
canvas.height = height
layer.width = width
layer.height = height

quadtreeColor = 'rgba(120,144,156, 0.1)'
eltColor = 'rgba(229,57,53 ,1)'
oversizeColor = 'rgba(136,14,79 ,1)'
collidingColor = '#F57F17'

eltSizeQuota = 25
eltDrawMult = 100
eltIncrement = 10

document.addEventListener('DOMContentLoaded', function () {
    init()
    updateCanvas()
    updateLayer()
})

var updateCounter = function(){
    counter.innerHTML = quadtree.size + " elements"
}

var randomNb = function(min, max){
    if(min >= max)
        throw new Error('min must be < max')
    return Math.floor(Math.random() * (max - min)) + min
}
var randomizeElement = function(){
    return {
        x: randomNb(0, width),
        y: randomNb(0, height),
        width: randomNb(0, Math.min(width, height) / eltSizeQuota),
        height: randomNb(0, Math.min(width, height) / eltSizeQuota),
        color: eltColor//"#"+((1<<24)*Math.random()|0).toString(16)
    }
}
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
    updateCounter()
}

var drawSquare = function(elt, fill, context){
    if(!context)
        context = ctx
    context.beginPath()
    context.moveTo(elt.x, elt.y)
    context.lineTo(elt.x + (elt.width ? elt.width : 1), elt.y)
    context.lineTo(elt.x + (elt.width ? elt.width : 1), elt.y + (elt.height ? elt.height : 1))
    context.lineTo(elt.x, elt.y + (elt.height ? elt.height : 1))
    context.closePath()
    context.stroke()
    if(fill)
        context.fill()
}

var drawQuadtree = function(tree, fill, context) {
    var halfWidth  = Math.max(Math.floor(tree.width  / 2), 1)
    var halfHeight = Math.max(Math.floor(tree.height / 2), 1)

    drawSquare({
        x: tree.x,
        y: tree.y,
        width:  halfWidth,
        height: halfHeight
    }, fill, context)
    drawSquare({
        x: tree.x + halfWidth,
        y: tree.y,
        width:  halfWidth,
        height: halfHeight
    }, fill, context)
    drawSquare({
        x: tree.x,
        y: tree.y + halfHeight,
        width:  halfWidth,
        height: halfHeight
    }, fill, context)
    drawSquare({
        x: tree.x + halfWidth,
        y: tree.y + halfHeight,
        width:  halfWidth,
        height: halfHeight
    }, fill, context)
}

var updateCanvas = function(){
    ctx.clearRect(0, 0, width, height)
    quadtree.visit(function(){
        ctx.strokeStyle = quadtreeColor
        drawQuadtree(this)
        ctx.fillStyle = eltColor
        for(i in this.contents)
            drawSquare(this.contents[i], true)
        ctx.fillStyle = oversizeColor
        for(i in this.oversized)
            drawSquare(this.oversized[i], true)
    })
}

var updateLayer = function(){
    layerCtx.clearRect(0, 0, width, height)
    if(window.mousePos){
        layerCtx.strokeStyle = collidingColor
        layerCtx.fillStyle = collidingColor
        layerCtx.beginPath()
        layerCtx.moveTo(0, mousePos.y)
        layerCtx.lineTo(width, mousePos.y)
        layerCtx.closePath()
        layerCtx.stroke()
        layerCtx.beginPath()
        layerCtx.moveTo(mousePos.x, 0)
        layerCtx.lineTo(mousePos.x, height)
        layerCtx.closePath()
        layerCtx.stroke()
        quadtree.colliding(mousePos).forEach(function(elt){
            drawSquare(elt, true, layerCtx)
        })
    }
}

var addElements = function(){
    var elementArray = []
    for(var i = 0; i < eltIncrement; i++)
        elementArray.push(randomizeElement())
    quadtree.pushAll(elementArray)
    updateCanvas()
    updateLayer()
    updateCounter()
}
var unregisterMouse = function(){
    delete window.mousePos
    updateLayer()
}
var hoverMouse = function(event){
    mousePos = {
        x: event.offsetX || (event.offsetX === 0 ? 0 : event.changedTouches[0].clientX - event.target.getBoundingClientRect().left),
        y: event.offsetY || (event.offsetY === 0 ? 0 : event.changedTouches[0].clientY - event.target.getBoundingClientRect().top)
    }
    if(mousePos.x < 0 || mousePos.y < 0)
        return
    event.stopPropagation()
    event.preventDefault()
    updateLayer()
}
