var canvas = document.getElementById("quadtree_canvas")
var layer = document.getElementById("layer_canvas")
var ctx = canvas.getContext("2d")
var layerCtx = layer.getContext("2d")

var canvasContainer = document.getElementById("canvas-container")

document.addEventListener('DOMContentLoaded', function () {
    init()
})

var init = function(){
    width = canvasContainer.clientWidth
    height = canvasContainer.clientHeight
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
}
