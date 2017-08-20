/* global window, document */

window.demo = (function() {

    var canvas = document.getElementById("quadtree_canvas")
    var layer = document.getElementById("layer_canvas")
    var container = document.getElementById("canvas-container")
    var counter = document.getElementById("counter")
    var ctx = canvas.getContext("2d")
    var layerCtx = layer.getContext("2d")
    var width = Math.min(container.clientWidth, window.innerWidth)
    var height = width === window.innerWidth ? window.innerWidth : container.clientHeight

    canvas.width = width
    canvas.height = height
    layer.width = width
    layer.height = height

    var basicDemo = {
        quadtreeColor: "rgba(120, 144, 156, 0.1)",
        eltColor: "rgba(229, 57, 53, 1)",
        oversizeColor: "rgba(136, 14, 79, 1)",
        collidingColor: "#F57F17",
        eltSizeQuota: 25,
        eltDrawMult: 100,
        eltIncrement: 10,
        mousePos: null,
        quadtree: null,

        init: function() {
            canvas.width = width
            canvas.height = height
            container.style.height = height + "px"
            ctx.clearRect(0, 0, width, height)
            ctx.lineWidth = 1
            layer.width = width
            layer.height = height
            layerCtx.clearRect(0, 0, width, height)
            layerCtx.lineWidth = 1
            this.quadtree = new window.Quadtree({
                width: width,
                height: height
            })
            this.updateCounter()
        },

        updateCounter: function() {
            counter.innerHTML = this.quadtree.size + " elements"
        },

        randomizeElement: function() {
            var squareSize = window.randomNb(0, Math.min(width, height) / this.eltSizeQuota)
            return {
                x: window.randomNb(0, width),
                y: window.randomNb(0, height),
                width: squareSize,
                height: squareSize,
                color: this.eltColor// "#"+((1<<24)*Math.random()|0).toString(16)
            }
        },

        updateCanvas: function() {
            var that = this
            ctx.clearRect(0, 0, width, height)
            this.quadtree.visit(function() {
                ctx.strokeStyle = that.quadtreeColor
                window.drawQuadtree(this, false, ctx)
                ctx.fillStyle = that.eltColor
                for(var i in this.contents)
                    window.drawSquare(this.contents[i], true, ctx)
                ctx.fillStyle = that.oversizeColor
                for(var j in this.oversized)
                    window.drawSquare(this.oversized[j], true, ctx)
            })
        },

        updateLayer: function() {
            layerCtx.clearRect(0, 0, width, height)
            if(this.mousePos) {
                layerCtx.strokeStyle = this.collidingColor
                layerCtx.fillStyle = this.collidingColor
                layerCtx.beginPath()
                layerCtx.moveTo(0, this.mousePos.y)
                layerCtx.lineTo(width, this.mousePos.y)
                layerCtx.closePath()
                layerCtx.stroke()
                layerCtx.beginPath()
                layerCtx.moveTo(this.mousePos.x, 0)
                layerCtx.lineTo(this.mousePos.x, height)
                layerCtx.closePath()
                layerCtx.stroke()
                this.quadtree.colliding(this.mousePos).forEach(function(elt) {
                    window.drawSquare(elt, true, layerCtx)
                })
            }
        },

        addElements: function(n) {
            var elementArray = []
            for(var i = 0; i < (n || this.eltIncrement); i++)
                elementArray.push(this.randomizeElement())
            this.quadtree.pushAll(elementArray)
            this.updateCanvas()
            this.updateLayer()
            this.updateCounter()
        },

        unregisterMouse: function() {
            delete this.mousePos
            this.updateLayer()
        },

        hoverMouse: function(event) {
            this.mousePos = {
                x: event.offsetX || (event.offsetX === 0 ? 0 : event.changedTouches[0].clientX - event.target.getBoundingClientRect().left),
                y: event.offsetY || (event.offsetY === 0 ? 0 : event.changedTouches[0].clientY - event.target.getBoundingClientRect().top)
            }
            if(this.mousePos.x < 0 || this.mousePos.y < 0)
                return
            event.stopPropagation()
            event.preventDefault()
            this.updateLayer()
        }
    }

    document.addEventListener("DOMContentLoaded", function() {
        basicDemo.init()
        basicDemo.addElements(50)
        basicDemo.updateCanvas()
        basicDemo.updateLayer()
    })

    return basicDemo

}())
