var canvas = document.getElementById("quadtree_canvas")
var layer = document.getElementById("layer_canvas")
var container = document.getElementById("canvas-container")
var counter = document.getElementById("counter")
var ctx = canvas.getContext("2d")
var layerCtx = layer.getContext("2d")
var width = Math.min(container.clientWidth, window.innerWidth)
var height = width === window.innerWidth ? window.innerWidth : container.clientHeight
DELAY = 1
canvas.width = width
canvas.height = height
layer.width = width
layer.height = height

quadtreeColor = 'rgba(120, 144, 156, 0.1)'
eltColor = 'rgba(229, 57, 53, 1)'
oversizeColor = 'rgba(136, 14, 79, 1)'
collidingColor = '#F57F17'

eltSizeQuota = 25
eltDrawMult = 100
eltIncrement = 10

document.addEventListener('DOMContentLoaded', function () {
    init()
    updateCanvas()
    updateLayer()
})

var init = function(){
    canvas.width = width
    canvas.height = height
    container.style.height = height+"px"
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

var updateCounter = function(){
    counter.innerHTML = quadtree.size + " elements"
}

var randomizeElement = function(){
    var squareSize = randomNb(0, Math.min(width, height) / eltSizeQuota)
    return {
        x: randomNb(0, width),
        y: randomNb(0, height),
        width: squareSize,
        height: squareSize,
        color: eltColor//"#"+((1<<24)*Math.random()|0).toString(16)
    }
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
